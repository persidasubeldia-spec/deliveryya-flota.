# Incidencias Boom Store — Diego Britez y Gael, 12/11/2026

Se identificaron dos pedidos T14, ambos de Boli Diego, originalmente `no_recibio`. Motorista acudió al destino y no cobró entrega ni envío. La autorización expresa en conversación indica facturar **Gs. 25.000 por visita a Boom Store**.

- Diego Britez (registrado así; usuario dijo Benítez), Fernando de la Mora, pedido `7a9d4512-6cce-4f60-a2ca-cc25bc958937`.
- Gael, Villa Elisa, pedido `0f59f26e-0152-419d-86ba-93e0acdf36ed`.
- **Costo tienda:** Gs. 50.000 total. **Ingreso de clientes:** Gs. 0.
- **Ganancia Boli Diego:** 2 × 18.750 = Gs. 37.500 reconocida por visitas; **ganancia Central:** 2 × 6.250 = Gs. 12.500 prevista; la tienda soporta 50.000 al descontarse en su rendición.
- No descontar también subsidio de Gs. 5.000 por incidencia, ya que se factura tarifa completa de Gs. 25.000.
- El flujo anterior no facturaba el estado `no_recibio`; para adecuarse al motor financiero existente, la incidencia con visita comprobada se formaliza como `rechazado` (visita fallida, no cobrada), con texto explicativo original preservado en la tabla de auditoría. **No declarar que el cliente rechazó físicamente el producto si el motivo fue distinto.**
- La tabla privada `flota_incidencias_visita_auditadas` conserva estado y motivo anteriores, fecha, cobranzas cero, comisiones y autorización. La migración de esquema NO transforma pedidos por sí sola.
- La ejecución de los dos casos es transacción específica e idempotente, con validación de IDs, empresa, tienda, motorista, fecha operativa, ruta, condición financiera sin movimientos/cierres y comisiones. No es una regla automática para otros `no_recibio` porque algunos pueden no implicar una visita realmente realizada.
