# DeliveryYa Flota — Registro de desarrollo y pruebas
Actualizado: 2026-10-31

## Arquitectura y datos
- Repositorio existente: este mismo proyecto; App Tienda en index.html; Central en central.html; motorista en motorista.html.
- Supabase es fuente única de verdad. Todas las operaciones financieras nuevas pasan por funciones transaccionales.
- Los usuarios de flota están en flota_usuarios. La tienda conserva sus permisos por membresía.
- Escenarios DEMO (50 pedidos, 5 grupos, 5 motoristas descriptivos) en tablas separadas. No son pedidos reales ni usuarios Auth.

## Implementaciones incorporadas
- Acceso propietario, invitaciones para socios y operadores, permisos y revocación segura.
- Central compacta: Inicio, Pedidos, Rutas, Motoristas, Tiendas, Finanzas. Usuarios y socios en área administrativa.
- Alta de motoristas e invitación por WhatsApp; activación con perfil motoristas y usuario verificado.
- Alta de tiendas con código y token de propietaria; renovar invitación; portal tienda-alta.html. Autorregistro no autorizado bloqueado en políticas RLS.
- Ruta general con mapa Leaflet, consulta vial OSRM Trip, confirmación numerada, tres vistas y zoom estable.
- Asignación por mapa, lista e intervalo en una operación atómica; guardar tasas de empresa y motorista al asignar; compartir por WhatsApp.
- Ruta individual del motorista con mapa, navegación, WhatsApp, llamada, optimización vial desde GPS y orden individual persistente, sin modificar numero_general.
- GPS voluntario del motorista, posición reciente con antigüedad visible.
- Cambio de estado, incidencias, entregas, rechazos y movimientos financieros idempotentes con separación de efectivo/transferencia.
- Comisiones general y especial por motorista; no se reescriben porcentajes de pedidos ya asignados.
- Caja y rendición del motorista presentada, confirmación por la Central con efectivo recibido y transferencia verificada, diferencias visibles; bloqueo de cobros tras presentar caja.
- Reporte de tienda imprimible / guardar PDF: reporte-tienda.html. No equivale a comprobante de pago confirmado.
- Laboratorio aislado simulacros.html con cinco escenarios diferentes y cincuenta pedidos de ejemplo.

## Pruebas ejecutadas y resultados
- JavaScript: comprobación de sintaxis sobre las principales pantallas y modificaciones.
- Supabase: simulación transaccional con 50 pedidos, cinco rutas, cinco motoristas; 50 asignados, 27 entregas, cuatro rechazos y 31 movimientos financieros. Transacción revertida.
- Finanzas: pedido entregado de ₲ 125.000, comisión flota ₲ 6.250 y comisión motorista ₲ 18.750. Transacción revertida.
- Cinco casos: efectivo, producto pagado, todo pagado, rechazo y sin respuesta. Cuatro movimientos, sin cobro por no respuesta. Transacción revertida.
- Rendición: efectivo esperado/recibido ₲ 125.000, transferencia verificada ₲ 25.000, diferencias cero. Transacción revertida.
- Cierre de ruta: dos pedidos entregados, estado 'cerrada'. Transacción revertida.
- RLS: identidad sin permisos de flota no puede leer usuarios, pedidos, tiendas, motoristas ni finanzas.
- Verificación de Vercel: varias versiones READY con SHA coincidente con GitHub. READY no prueba ejecución en navegador.

## NO CONCLUIDO / VALIDACIÓN NECESARIA
- Pruebas de interfaz en navegador autenticado para propietario, tienda, socio y repartidor; el navegador local no pudo acceder al dominio por restricción de red.
- Optimización vial real de escenarios completos y medición de recorridos; OSRM es dependencia externa y puede tener límites/caídas.
- Cinco simulacros UI de principio a fin con treinta/cincuenta pedidos, WhatsApp y recepción móvil: NO aprobados. El laboratorio es una simulación de datos.
- Reportes PDF: el navegador puede imprimir/guardar PDF; falta probar las opciones reales de dispositivos y formalizar comprobantes de pago para tienda.
- Pagos reales, devolución de capital, reprogramación de pendientes y conciliación bancaria final.
- End-to-end de invitaciones y confirmaciones de correo; revisar la allowlist de redirecciones de Supabase.
- Rendición definitiva de fondos a tiendas; actualmente solo hay reporte provisional de importes.
- RLS detallado y pruebas de concurrencia en dispositivos; auditoría de eventos operativos completa.
- No habilitar actividad comercial plena hasta verificar lo anterior.

## Criterio de continuidad
Mantener intactos pedidos reales, códigos de tienda y cuentas existentes. No presentar escenario DEMO como cobro real. Aplicar cambios pequeños, migraciones seguras, pruebas y verificación del despliegue antes de afirmar funcionalidad completa.
