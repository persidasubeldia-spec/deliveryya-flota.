# Rendición por motorista · propuesta aislada (11/11/2026)

## Ubicación
- Acceso rápido «Pendientes de rendición» en Inicio de Central.
- Nueva pestaña «Rendición por motorista», solo Central con permisos financieros.
- Una caja por motorista y fecha: incluye mañana y tarde; detalle en la misma pantalla.
- RPC SQL de lectura: flota_resumen_rendicion_motoristas(p_fecha date), con autorización por empresa.

## Fórmulas reales verificadas (no inventar otras)
- motorista_presentar_cierre agrega efectivo, transferencias y comisión por fecha contable de movimientos de Asunción.
- Modalidad retener_comision: efectivo esperado = greatest(0, efectivo - least(efectivo, sum(comision_motorista))). Para otras modalidades se entrega el efectivo íntegro.
- Si hay cierre, se usa a_rendir_esperado como fuente de verdad. Si no está confirmado, «Entregó» dice «Sin confirmar» y «Falta» dice «Sin conciliar».
- La función motorista_mis_ganancias_por_fecha utiliza fecha de ruta, no fecha contable: la vista separa cobros de otra fecha.

## Diferencia detectada en el sistema antiguo
El PDF administrativo rdPdfMotoCentral estima la retención solo con comisiones de pedidos entregados; motorista_presentar_cierre suma las comisiones de movimientos del día (también rechazos facturables).
Ejemplo sintético: efectivo 100.000, comisión de entregas 15.000, comisión por rechazo 5.000. La RPC oficial espera 80.000 y la estimación del PDF anterior daría 85.000.
La nueva vista conserva la fórmula de la RPC y los valores de cierre; NO altera el PDF existente.

## Archivos
- central.html: pequeño cambio en navegación, tarjeta de Inicio, estilo y script nuevo separado.
- supabase/migrations/20261111110000_flota_resumen_rendicion_motoristas.sql
- supabase/rollback/20261111110000_flota_resumen_rendicion_motoristas.sql
- tests/rendicion-motoristas.test.mjs

## Validación y publicación
1. Ejecutar pruebas de sintaxis, unitarias y navegador en rama. No equivalen a pruebas financieras de base.
2. Validar la migración sobre PostgreSQL local / Supabase de ensayo con datos sintéticos y roles simulados, incluyendo exclusión de otras empresas.
3. Revisar tres cajas de prueba (comisiones especiales, dos turnos, transferencias) comparando con las RPC de producción.
4. Con respaldo y aprobación explícita, aplicar SQL solo al proyecto sxhuvjvbqkovivcbisrn.
5. Fusionar PR a main después de comprobar la RPC, pues el push publica en Cloudflare.

## Confirmación del dinero realmente recibido
- Un cierre presentado por el motorista puede contener confirmed_at y estado confirmada sin comprobante de recepción de Central. La nueva vista no lo considera dinero recibido salvo confirmado_por con autorización financiera de Central.
- Nueva función flota_confirmar_recepcion_caja actualiza exclusivamente el cierre existente, con autorización estricta, bloqueo de fila, idempotencia y rechazo de doble confirmación distinta; no altera movimientos ni comisiones.
- No se precargan los importes: Central escribe efectivo y transferencia realmente recibidos, directamente en el detalle del motorista.
- Migración: supabase/migrations/20261111111000_flota_confirmar_recepcion_caja.sql
- Rollback: supabase/rollback/20261111111000_flota_confirmar_recepcion_caja.sql

## Fuera de alcance
No se modifican datos históricos, motorista.html, index.html, PDF ni el proceso actual de registrar y confirmar cajas.