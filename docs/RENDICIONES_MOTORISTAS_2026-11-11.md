## Rendiciones por motorista

Central > Rendiciones de delivery: tarjetas para cada motorista activo, saldo ordenado, detalle de pedidos, cobros, comisión de entregas y rechazos, declarado y recibido, PDF individual.

El cálculo principal conserva exactamente la lógica actual del cierre de caja (incluye comisión de rechazo); el detalle incorpora cálculo prudente que no anticipa el rechazo impago y lo señala. No se modifican datos, SQL, comisiones ni cierres existentes. Confirmación de recepción real solo para usuarios autorizados y cierres no confirmados, con verificación explícita.

Limitación heredada: algunos cierres pueden estar marcados confirmados por el flujo anterior; la vista no certifica presencia física del dinero y no reabre cierres confirmados.
