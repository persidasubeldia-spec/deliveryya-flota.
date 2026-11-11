## Corrección auditada aplicada (11/11/2026)

Se corrigió con autorización expresa un único pedido de Boom Store T14 en **Supabase de producción sxhuvjvbqkovivcbisrn**. El producto pasó de Gs. 100.000 a Gs. 70.000 y el efectivo cobrado de Gs. 120.000 a Gs. 90.000. Delivery al cliente Gs. 20.000, subsidio Gs. 5.000 y comisiones quedaron intactos. Se verificaron los importes después de una única transacción y se mantuvieron las referencias del movimiento.

La corrección utiliza una tabla de auditoría privada **flota_correcciones_financieras_auditadas**, con la foto de los valores antes/después, motivo, hora y autorización de la intervención. El archivo de migración de compatibilidad `20261111120100_flota_correcciones_financieras_auditadas.sql` preserva esa estructura sin reejecutar el caso histórico; no debe publicarse el identificador del pedido ni el contenido del registro.

**Prevención de recurrencia**: sigue pendiente de revisión/aprobación el resto del PR #72 (confirmación de importes en Tienda y Motorista y trigger de protección/auditoría). No afirmar que estas protecciones ya están operativas en producción.

**Nota de causa raíz**: la aplicación registra un pedido previo distinto con producto Gs. 70.000; el pedido entregado tenía Gs. 100.000 y no constan cambios auditados de precio. La causa de carga del valor incorrecto no está demostrada, por lo que la solución futura añade auditoría desde la creación.
