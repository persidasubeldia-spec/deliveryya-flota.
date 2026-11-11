# Corrección de importes de dos pedidos de Boom Store T14 · 2026-11-11

## Datos comprobados
- En dos pedidos pendientes independientes, el historial de ediciones registra que se pasó la mercadería de Gs. 100.000 a Gs. 105.000. Ambos siguen sin movimientos financieros.
- En el primero, la tienda ya había devuelto manualmente la mercadería a Gs. 100.000.
- En el segundo, se corrigió en producción Gs. 105.000 → Gs. 100.000, transaccionalmente, con control de versión, comprobación de ausencia de movimiento/cierre y auditoría protegida.
- Ambos pedidos tienen **tarifa real Gs. 25.000**, de los cuales el cliente paga **Gs. 20.000** y Boom Store subsidia **Gs. 5.000**. La mercadería permanece Gs. 100.000, así que el cliente paga Gs. 120.000 (no Gs. 125.000).
- El historial confirma una edición de precio, NO que un cálculo automático haya aumentado la mercadería. La motivación humana de la edición no puede establecerse solo con el registro.

## Prevención
El PR incorpora una revisión de importes en Tienda, validación visual en Motorista, un trigger de protección de precio y auditoría desde la creación para pedidos futuros. Esta prevención **sigue sin desplegarse** hasta validar las pruebas SQL y aprobar el PR.
La tabla `flota_correcciones_precio_pre_cobro_auditadas` guarda la evidencia histórica de esta intervención; la migración de compatibilidad solo sincroniza la estructura de GitHub con la creada en Supabase, sin ejecutar de nuevo la corrección.
No publicar nombres, teléfonos ni identificadores de clientes en este repositorio público.
