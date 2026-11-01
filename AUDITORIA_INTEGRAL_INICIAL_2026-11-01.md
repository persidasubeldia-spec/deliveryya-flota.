# Auditoría inicial de DeliveryYa Flota — 2026-11-01

**Alcance:** lectura de siete páginas del repositorio y consultas de solo lectura a Supabase, más una corrección acotada de seguridad.

**Advertencia:** inventario estático del código HTML, NO equivale a prueba interactiva ni prueba 100% funcional.

## Hallazgos de prioridad

### P0 — Política financiera excesivamente permisiva (corregida)
- Tabla: `public.movimientos_financieros`.
- Evidencia: política `Acceso autenticado total movimientos` con `cmd=ALL` para `PUBLIC`, predicado `auth.role() = 'authenticated'`. El rol `authenticated` tenía privilegios SQL de SELECT, INSERT, UPDATE y DELETE.
- Acción aplicada: migración `remove_unrestricted_financial_movements_policy` que elimina exclusivamente dicha política.
- Verificación: permanecen las políticas `flota_movimientos_financieros_autorizados` y `motorista_movimientos_propio`, ambas de lectura. Ninguna de las dos concede modificación directa.
- Pendiente: pruebas de integraciones financieras bajo sesiones con distintos roles, tras la corrección.

### P1 — Diferencia entre DEMO de 50 y ruta de producción
- `demo-50-ruta.html` optimiza 50 coordenadas en el navegador usando una matriz de OSRM y mantiene asignaciones de DEMO en `localStorage`.
- `admin_confirmar_ruta_optimizada` en Supabase admite expresamente un máximo de **26** identificadores por llamada.
- La demostración de 50 pedidos NO demuestra que el flujo real Central → Supabase permita confirmar una ruta de 50 paradas; requiere diseño transaccional y pruebas específicas.

### P1 — Google Maps no unificado en las 3 apps
- Central incluye código Google Maps y Leaflet.
- Motorista tiene Leaflet y no tiene carga del SDK Google Maps en su HTML examinado.
- DEMO 50 usa Google Maps, pero no representa de forma integral la app productiva.

### P1 — Flujo financiero sin prueba integral
- Existen RPC de cobro, rechazo y confirmación de rendiciones con comprobaciones de autorización.
- `motorista_cerrar_entrega` calcula efectivo y transferencia según modalidad, y registra un movimiento, pero no se ejecutaron escenarios con cuentas de prueba.
- Pendiente: casos producto_pagado, todo_pagado, rechazo, cobros parciales, cierre y concurrencia.

## Cobertura comprobada hasta ahora
- Código de los siete archivos enumerados: leído.
- Las 26 tablas públicas muestran RLS activado.
- Inspección de definiciones SQL de seis RPC clave y políticas de tablas principales.
- No se hizo navegación autenticada, pruebas de botones, pruebas de estrés ni conciliación con planillas reales.
- **Ningún botón se marca como probado operativamente.**

## Inventario inicial de botones (sección HTML estática)

| Archivo | ID | Etiqueta visible en código | Estado de prueba |
|---|---|---|---|
| `index.html` | `themeToggle` | 🌙 Noche | No comprobado |
| `index.html` | `loginOpenBtn` | Ingresar | No comprobado |
| `index.html` | `logoutBtn` | Salir | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Inicio | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | + Nuevo pedido | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Mis pedidos | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Clientes | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Mi tienda | No comprobado |
| `index.html` | `togglePassword` | Mostrar | No comprobado |
| `index.html` | `loginBtn` | Ingresar | No comprobado |
| `index.html` | `registerOpenBtn` | Crear cuenta | No comprobado |
| `index.html` | `registerSubmitBtn` | Registrar mi tienda | No comprobado |
| `index.html` | `resendConfirmationBtn` | Reenviar confirmación de correo | No comprobado |
| `index.html` | `resetPasswordBtn` | Recuperar contraseña | No comprobado |
| `index.html` | `loginCancelBtn` | Volver a versión de prueba | No comprobado |
| `index.html` | `todayBtn` | Hoy | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | + Crear pedido | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Ver mis pedidos | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Mis clientes | No comprobado |
| `index.html` | `confirmBtn` | Guardar pedido | No comprobado |
| `index.html` | `draftBtn` | Guardar borrador | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Limpiar | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Guardar perfil local | No comprobado |
| `index.html` | `inviteEmployeeBtn` | Invitar empleada | No comprobado |
| `index.html` | `exportBtn` | Exportar respaldo JSON | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Copiar resumen | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Nuevo pedido para este cliente | No comprobado |
| `index.html` | `(sin ID; botón dinámico o por clase)` | Revocar acceso | No comprobado |
| `central.html` | `enter` | Ingresar | No comprobado |
| `central.html` | `register` | Crear cuenta del propietario | No comprobado |
| `central.html` | `logout` | Cerrar sesión | No comprobado |
| `central.html` | `homeReload` | ↻ Actualizar | No comprobado |
| `central.html` | `openUsers` | Usuarios y socios | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | '+label+''+val+'Consultar → | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Preparar ruta | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Ver repartos | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Revisar pedidos | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Cerrar operaciones | No comprobado |
| `central.html` | `orderReset` | Limpiar filtros | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | 1. Ruta general | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | 2. Repartir | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | 3. Avance | No comprobado |
| `central.html` | `routeClose` | Cerrar ruta terminada | No comprobado |
| `central.html` | `routeReload` | Actualizar mapa | No comprobado |
| `central.html` | `routeOptimize` | Calcular recorrido vial | No comprobado |
| `central.html` | `routeConfirm` | Confirmar ruta calculada | No comprobado |
| `central.html` | `routeRange` | Seleccionar intervalo | No comprobado |
| `central.html` | `routeVisible` | Seleccionar puntos visibles | No comprobado |
| `central.html` | `routeClear` | Limpiar selección | No comprobado |
| `central.html` | `routeAssign` | Asignar seleccionados | No comprobado |
| `central.html` | `routeSend` | Asignar y WhatsApp | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Pedidos | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Motoristas | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Detalle | No comprobado |
| `central.html` | `driverAddToggle` | + Agregar motorista | No comprobado |
| `central.html` | `driverPctToggle` | Configurar comisión | No comprobado |
| `central.html` | `saveGeneralPct` | Guardar porcentaje general | No comprobado |
| `central.html` | `mcreate` | Registrar motorista | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | '+(d.porcentaje_personalizado?'Personalizada':'General')+' | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Invitar | No comprobado |
| `central.html` | `storeAddToggle` | + Nueva tienda | No comprobado |
| `central.html` | `screate` | Registrar y generar invitación | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Reenviar invitación | No comprobado |
| `central.html` | `uinvit` | Crear invitación | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Resumen | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Motoristas | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Tiendas | No comprobado |
| `central.html` | `printReport` | Imprimir o guardar PDF | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Conciliar caja | No comprobado |
| `central.html` | `closeOrder` | Cerrar ✕ | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Ver | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Ver | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | Revocar | No comprobado |
| `central.html` | `(sin ID; botón dinámico o por clase)` | '+p+' | No comprobado |
| `motorista.html` | `login` | Ingresar | No comprobado |
| `motorista.html` | `register` | Crear cuenta invitada | No comprobado |
| `motorista.html` | `optimizeMine` | Optimizar mi recorrido | No comprobado |
| `motorista.html` | `gpsStart` | Compartir mi ubicación | No comprobado |
| `motorista.html` | `gpsStop` | Detener | No comprobado |
| `motorista.html` | `submitClose` | Presentar rendición | No comprobado |
| `motorista.html` | `refresh` | Actualizar | No comprobado |
| `motorista.html` | `logout` | Cerrar sesión | No comprobado |
| `motorista.html` | `(sin ID; botón dinámico o por clase)` | Entregado | No comprobado |
| `motorista.html` | `(sin ID; botón dinámico o por clase)` | Rechazado | No comprobado |
| `motorista.html` | `(sin ID; botón dinámico o por clase)` | Incidencia | No comprobado |
| `demo-50-ruta.html` | `opt` | Optimizar los 50 pedidos | No comprobado |
| `demo-50-ruta.html` | `reset` | Restaurar orden de prueba | No comprobado |
| `demo-50-ruta.html` | `refresh` | Actualizar 50 pedidos | No comprobado |
| `demo-50-ruta.html` | `assign` | Asignar intervalo | No comprobado |
| `demo-50-ruta.html` | `selectVisible` | Marcar visibles | No comprobado |
| `demo-50-ruta.html` | `clearSelected` | Desmarcar | No comprobado |
| `demo-50-ruta.html` | `assignSelected` | Asignar marcados | No comprobado |
| `demo-50-ruta.html` | `sendWhatsapp` | Enviar ruta por WhatsApp | No comprobado |
| `demo-50-ruta.html` | `fit` | Ver 50 puntos | No comprobado |
| `simulacros.html` | `(sin ID; botón dinámico o por clase)` | Imprimir / guardar PDF | No comprobado |
| `simulacros.html` | `demoOptimize` | Optimizar 50 pedidos por sectores | No comprobado |
| `simulacros.html` | `demoConfirm` | Confirmar numeración DEMO | No comprobado |
| `simulacros.html` | `demoReload` | Actualizar datos DEMO | No comprobado |
| `simulacros.html` | `demoGoogle` | Probar Google Maps | No comprobado |
| `simulacros.html` | `(sin ID; botón dinámico o por clase)` | '+esc(n//'·')+''+esc(x.cliente//'Pedido')+''+esc(x.tienda_codigo)+' ·  | No comprobado |
| `simulacros.html` | `(sin ID; botón dinámico o por clase)` | Mapa general · 50 pedidos | No comprobado |
| `simulacros.html` | `(sin ID; botón dinámico o por clase)` | Simulacro '+(i+1)+' — '+t+' | No comprobado |
| `simulacros.html` | `(sin ID; botón dinámico o por clase)` | Estado | No comprobado |
| `simulacros.html` | `(sin ID; botón dinámico o por clase)` | Moto | No comprobado |
| `reporte-tienda.html` | `print` | Imprimir / Guardar PDF | No comprobado |
| `tienda-alta.html` | `register` | Crear mi cuenta | No comprobado |
| `tienda-alta.html` | `login` | Ya tengo cuenta | No comprobado |

**Total provisional de elementos `<button>`:** 107. No incluye botones creados con `innerHTML`/JS, controles `<select>`, enlaces, menús, casillas ni formularios, que requieren una segunda fase de inventario.

## Próximas pruebas obligatorias
1. Recorrer todas las vistas con cuentas separadas para tienda, Central y motorista.
2. Probar permisos RLS reales contra roles autorizados y no autorizados, con datos DEMO.
3. Comparar `pedido → asignación → entrega → movimiento → cierre → reporte` en las tres apps.
4. Cubrir inventario dinámico de controles y distinguir funciones no implementadas de funciones inaccesibles por rol.
5. Validar Google Maps en Motorista y límites de confirmación 26/50.
