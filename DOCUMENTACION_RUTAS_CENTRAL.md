# PROMPT — Auditoría de la pantalla Central › Rutas (DeliveryYa Flota)

Sos el ingeniero que audita **cada función** de la pantalla **Central › Rutas** (`central.html`). Para cada botón verificá lo que **debe cumplir** según esta tabla. Hacelo con una sesión de **administrador** (`flota_usuarios`, rol propietario, socio u operador), nunca con una cuenta de tienda.

## Diagnóstico del 2026-11-02 ("no funciona ningún botón")
1. **Sesión cruzada.** Central, Tienda y Moto compartían la sesión del navegador. Al entrar como T3 en la Tienda, Central pasaba a ser T3: mostraba 12 pedidos, 0 motos y rechazaba todo. **Corregido (PR #6):** cada app guarda su propia sesión.
2. **Pasos previos invisibles.** Con la sesión correcta, los registros del servidor mostraron **cero llamadas** tras tocar los botones. La pantalla bloqueaba la acción por un paso previo (filtro en "Todos", falta de punto de salida, ruta sin confirmar) y avisaba en un texto gris chico. **Corregido (PR #7):**
   - Los avisos ahora se ven en un recuadro amarillo grande, con desplazamiento automático hasta él.
   - "Preparar" con el filtro en "Todos" pregunta qué turno preparar.
   - Se recuerda el último punto de salida usado.

## Orden obligatorio del flujo
`Turno → 1. Preparar turno y ruta → Punto de salida → Optimizar (1 o más veces) → Confirmar → 2. Repartir: moto + pedidos → Asignar → 3. Avance → Cerrar ruta`

## Qué debe cumplir cada función

| # | Botón / control | Requisito previo | Qué debe hacer | Llamada al servidor | Si falta el requisito |
|---|---|---|---|---|---|
| 1 | Filtros **Todos / Mañana / Tarde / Sin turno** | — | Filtra la lista, el mapa, los contadores y las casillas. Quita las selecciones de otro turno. Si hay una sola ruta activa del turno, la elige. | **Ninguna** (no escribe en la base) | — |
| 2 | **Ruta** (lista) | — | Elige la ruta de trabajo (fecha · turno · estado). Limpia la selección y las propuestas. | Ninguna | — |
| 3 | **1. Preparar turno y ruta** | Un turno elegido; si está en "Todos", pregunta cuál | Crea o reutiliza la ruta de hoy del turno y rescata pendientes de rutas viejas (sin turno o de días anteriores). Muestra cuántos rescató. | `flota_crear_ruta_turno(fecha, turno)` + `flota_reorganizar_pendientes_heredados(fecha, turno)` | Selector de turno |
| 4 | **Organizar pendientes antiguos** | Ruta del turno elegida | Igual que el rescate del punto 3, sin crear una ruta. | `flota_reorganizar_pendientes_heredados` | Aviso: "Elegí la ruta del turno" |
| 5 | **Actualizar mapa** | — | Vuelve a leer pedidos, motos y rutas. Redibuja el mapa y la lista. | Lecturas `pedidos`, `motoristas`, `rutas_generales` | — |
| 6 | **Punto de salida** + **Usar mi ubicación** | Permiso de GPS del navegador (precisión ≤ 250 m) | Fija el origen del recorrido. Acepta coordenadas o un enlace de Google Maps. Nunca inventa la ubicación. | Ninguna | Aviso: precisión insuficiente o permiso negado |
| 7 | **Optimizar / probar otra vez** | Ruta preparada del turno, 2 a 99 pedidos con GPS y punto de salida | Pide a OSRM el recorrido por calles y guarda la mejor propuesta. Repetir prueba alternativas **sin guardar nada en la base**. | `router.project-osrm.org/trip` (externo) | Aviso amarillo que dice qué falta |
| 8 | **Reiniciar propuestas** | — | Descarta las propuestas. No toca la base. | Ninguna | — |
| 9 | **Confirmar ruta calculada** | Una propuesta vigente con los mismos pedidos y salida | Numera 1..N (`numero_general`) y la ruta pasa a "optimizada". No permite si falta un pedido preparado o si ya hay repartos. | `admin_confirmar_ruta_optimizada(ruta, ids[])` | Botón deshabilitado |
| 10 | **Sumar pedidos nuevos al final** | Ruta confirmada (optimizada o en reparto) y pedidos nuevos del mismo turno | Numera N+1… sin renumerar los anteriores. | `flota_anexar_pedidos_a_ruta(ruta, ids[])` | Aviso |
| 11 | **Tarjeta de motorista** | Moto activa | La selecciona; muestra su color y la cantidad de pedidos asignados. | Ninguna | "No hay motoristas activos" |
| 12 | **Casillas / Seleccionar intervalo / Seleccionar puntos visibles / Limpiar** | Ruta **confirmada** | Selecciona solo pedidos pendientes, numerados, sin moto, de esa ruta y turno. | Ninguna | No marca pedidos no elegibles |
| 13 | **Asignar seleccionados** / **Asignar y WhatsApp** | Moto elegida y pedidos seleccionados (máx. 200) | Asigna todo o nada. Fija la comisión de la moto y pasa la ruta a "en reparto". WhatsApp abre el resumen con los números de la ruta. | `flota_asignar_lote(ids[], moto)` | "Elegí motorista activo y pedidos…" |
| 14 | **3. Avance** | — | Muestra el estado por moto: entregados, rechazados, incidencias. | Lecturas | — |
| 15 | **Cerrar ruta terminada** | Todos los pedidos entregados, rechazados o cancelados | La ruta pasa a "cerrada". | `flota_cerrar_ruta(ruta)` | "Quedan N pedidos…" |

## Cómo auditar sin tocar datos reales
- Pruebas automáticas: `tests/e2e/rutas-flujo.js` recorre los puntos 3→13 con datos de producción anonimizados y un Supabase simulado. Las pruebas SQL de `supabase/tests/` cubren las funciones del servidor.
- En producción, revisá en los registros de Supabase (Edge logs) que cada botón genere **su** llamada de la columna "Llamada al servidor". Si un botón no genera ninguna, la pantalla lo bloqueó por un requisito previo, y el aviso amarillo debe decir cuál.
- Checklist de diagnóstico rápido:
  - El encabezado muestra **todas** las tiendas y motos de la empresa. Si solo ves una tienda y 0 motos, la sesión es de una tienda, no de administrador.
  - El filtro de turno está en Mañana o Tarde, no en "Todos", antes de Optimizar.
  - Hay un punto de salida cargado.
  - La lista de Ruta muestra "fecha · turno · optimizada" antes de Repartir.
