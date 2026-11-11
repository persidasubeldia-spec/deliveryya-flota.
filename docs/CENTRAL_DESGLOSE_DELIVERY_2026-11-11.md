# Desglose de envío en Central · 11/11/2026

## Alcance
La tabla de **Pedidos** muestra tres importes diferenciados: *Cliente paga envío*, *Subsidio tienda* y *Tarifa real*. Se alimenta de los campos **ya existentes** `delivery_cliente`, `delivery_subsidio_tienda` y `precio_delivery`. Aplica a pedidos del día y futuros, y respeta registros históricos sin campos de subsidio.

El detalle de Pedido y la vista de Ruta usan el mismo desglose. El editor de pedidos muestra la **tarifa real** para evitar que se confunda con el cobro al cliente. Recalcula el total usando `delivery_cliente` previsto por la regla Boom; el aviso WhatsApp al motorista usa el importe realmente cobrado al cliente.

### Regla vigente de T14
- Tarifa real **Gs. 25.000**, cobro cliente **Gs. 20.000**, subsidio tienda **Gs. 5.000**.
- En tarifa mayor **Gs. 30.000**, el cliente paga **Gs. 30.000** y el subsidio es **Gs. 0**.
- Producto **Gs. 100.000** + envío cliente **Gs. 20.000** = cobro **Gs. 120.000**.
- No se cambia la regla SQL, ni las comisiones ni los registros históricos.

### Publicación
Cambio exclusivo de `central.html` + prueba de regresión, sin migración SQL. Fusionar a `main` solo tras aprobación de GitHub Actions; Cloudflare Pages despliega automáticamente.
