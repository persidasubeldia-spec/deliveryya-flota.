# Estado final — Reparación DeliveryYa Flota (2026-11-02)

**Producción:** `main` en `41241b3` (más este informe), publicada por GitHub Actions en Cloudflare Pages. Verificada leyendo las páginas publicadas.
**Base de datos:** Supabase `sxhuvjvbqkovivcbisrn`, con 2 migraciones nuevas aplicadas. No se modificó ninguna fila real.

## Cómo se probó (y qué NO cubre)
- **Staging:** el branching de Supabase requiere plan Pro, que no está disponible. Se usó un **PostgreSQL 16 local** con el esquema de producción cotejado **por hash** (funciones, tablas, índices, triggers) y permisos replicados. Los datos son sintéticos: 1 empresa, T1/T3, empleada, 2 motos al 25 % y al 30 %, y 30 pedidos.
- **Pruebas SQL** (`supabase/tests/`, ejecutar `run.sh`): **55/55**. Antes de corregir, fallaban las de F1, F2 y F6.
- **Interfaz de la moto** (`tests/e2e/moto.js`), en iPhone 13 emulado con Supabase simulado: **11/11**.
- **Carga de las 6 páginas** en escritorio e iPhone emulado: sin errores JS.
- **No cubierto:** prueba de punta a punta con sesiones reales en navegador contra un Supabase de staging, porque no hay staging en la nube. Tampoco iPhone físico.

## Estado por flujo

| Flujo / botón | Estado | Evidencia |
|---|---|---|
| Aislamiento entre tiendas: T1 no lee, edita ni encola pedidos de T3; usuario ajeno y sin sesión no ven nada | ✅ Aprobado | SQL A1–A9, J3 |
| Empleada crea pedido en su tienda | ✅ Aprobado | SQL A10 |
| Tienda › **Agregar a ruta** (Mañana/Tarde): turno y ruta correctos, reintento sin duplicar | ✅ Aprobado | SQL C1–C4 |
| Tienda › pedido tardío con la ruta ya confirmada (antes daba error "duplicate key") | ✅ Corregido | SQL E1–E3; pantalla "Recibido en el turno" |
| Central › **Preparar turno y ruta** rescata pedidos de rutas viejas sin turno o de días anteriores | ✅ Corregido | SQL B1–B4 (con auditoría y cierre de la ruta vacía) |
| Central › Confirmar ruta: numera 1..N y no pierde pedidos preparados | ✅ Aprobado | SQL D1–D3 |
| Central › **Sumar pedidos nuevos al final** (nuevo): N+1 sin renumerar | ✅ Aprobado | SQL E4–E5 |
| Central › Optimizar: hasta 99 pedidos (antes 26) | ✅ Medido | OSRM público: 26 y 60 OK; 101 → `TooBig` |
| Central › Repartir lote: atómico, comisión de la moto, rechaza mezclas de ruta o turno, no reasigna | ✅ Aprobado | SQL F1–F5 |
| Moto ve solo sus pedidos | ✅ Aprobado | SQL G1 |
| Moto › **Entregado** según modalidad (todo pagado = ₲ 0; producto pagado = envío; pendiente = mercadería + envío) | ✅ Aprobado | SQL G2–G8, UI M3–M6 |
| Comisión 25 %: envío 25.000 → empresa 6.250 / moto 18.750 | ✅ Aprobado | SQL G5 |
| Moto › **Rechazado** con importe real (15.000 < 20.000) y saldo pendiente | ✅ Aprobado | SQL G11–G12, UI M7–M8 |
| Moto › **Incidencias** (No responde / No recibió / Pasa mañana) | ✅ Aprobado | SQL G10, UI M9–M10 |
| Atajo para marcar Entregado sin cobro (F2) | ✅ Cerrado | SQL G9 |
| Moto › Presentar caja: "a rendir" cuadra (rinde todo / retiene comisión); no hay doble cierre; no se aceptan cobros tras presentar | ✅ Aprobado | SQL H1–H4 |
| Central › Confirmar rendición: exacta = confirmada, faltante = diferencia; la moto u operador sin permiso no pueden | ✅ Aprobado | SQL H5–H8 |
| Cerrar ruta con pedidos sin resolver | ✅ Bloqueado (correcto) | SQL I1 |
| Google Maps: `/maps/dir/origen/destino` resuelve al **destino**; enlace inválido da un error claro | ✅ Probado en producción | `POST /api/resolve-map` |
| Íconos de la app instalable | ✅ Corregido | `/icon-192.png` → 200 image/png (antes HTML) |
| WhatsApp desde la moto | ✅ Corregido | prefijo 595 (UI M2) |
| Enlace corto real `maps.app.goo.gl` y bloqueo 429 de Google | ⚠️ No probado | hace falta un enlace real; el código no inventa coordenadas |
| Registro de tienda, invitaciones, recuperación de contraseña, login en iPhone | ⚠️ No probado E2E | requiere correos y sesiones reales |
| Aviso de pedidos nuevos en Central (Realtime + revisión cada 15 s) | ⚠️ No probado | requiere sesión real |
| Reporte por tienda / PDF | ⚠️ Revisado en código | la fórmula coincide con la tabla de finanzas; sin prueba con datos |
| Optimizar con más de 99 pedidos en un turno | ❌ Límite del proveedor | repartir por sectores |
| "Corregir datos" en Moto | ⚠️ Usa `prompt()` | funciona; candidato a pasar al panel |

## Migraciones aplicadas en producción
| Migración | Qué hace | Reversión |
|---|---|---|
| `20261102100000_f1_f2_f6_rescate_rutas_y_cobros` | F1 rescate de pedidos; F2 incidencias solo como incidencias; F6 pedido tardío + `flota_anexar_pedidos_a_ruta` | `supabase/rollback/…100000…` (restaura las funciones exactas; probado) |
| `20261102110000_f3_f4_limpieza_y_endurecimiento` | Elimina 5 funciones obsoletas o peligrosas; `anon` sin acceso a tablas | `supabase/rollback/…110000…` (probado) |

## PRs fusionados
1. #1 Rescatar pedidos de rutas viejas, cerrar el atajo de cobro y aceptar pedidos tardíos.
2. #2 Limpieza de código muerto y endurecimiento de seguridad.
3. #3 Motorista: panel de botones.
4. #4 Central: optimizar hasta 99 pedidos.

## Pendiente que requiere acción del dueño
1. **Hoy, en Central:** elegir **Mañana** → **1. Preparar turno y ruta**, y después **Tarde** → igual. Así se rescatan los 4 pedidos de la ruta vieja del 1/11 sin turno (3 de Mañana, 1 de Tarde), que queda cerrada.
2. Hay 10 pedidos `sin_definir` (sin turno), creados antes de que existieran los turnos: asignarles turno desde Central o desde la Tienda.
3. **Supabase › Authentication:** activar la protección contra contraseñas filtradas (*Leaked password protection*).
4. **Google Cloud:** restringir la clave de Google Maps del frontend por dominio (`deliveryya-flota.pages.dev`).
5. Probar en un **iPhone físico**: login persistente, entrega, rechazo y caja.
6. Para pruebas E2E reales sin tocar producción: plan Pro (ramas) o un segundo proyecto Supabase gratuito como staging.

## Decisiones de negocio abiertas (no se inventaron fórmulas)
- **Rechazo con "Pendiente de definir":** el saldo del envío no aparece como deuda de nadie en el reporte por tienda hasta que se defina quién paga.
- **Moto que retiene comisión y tiene un rechazo cobrado parcialmente:** hoy retiene solo la comisión de los pedidos *entregados*. Confirmar si es la política deseada.
