# Incidente: cliente del incidente · Boom Store T14 · 11/11/2026

## Hallazgos comprobados (solo lectura sobre proyecto sxhuvjvbqkovivcbisrn)
- Pedido entregado: `[ID reservado en auditoría privada]`.
- Precio producto registrado: Gs. 100.000; delivery al cliente: Gs. 20.000; subsidio tienda: Gs. 5.000; tarifa real: Gs. 25.000.
- Movimiento financiero del pedido: Gs. 120.000 de efectivo, Gs. 100.000 de mercadería.
- Precio correcto informado por el negocio: Gs. 70.000 + Gs. 20.000 al cliente = Gs. 90.000; subsidio de tienda Gs. 5.000 separado.
- Hay un pedido previo distinto con nombre y teléfono coincidentes, producto Gs. 70.000, envío Gs. 20.000, aún pendiente. No concluir que sea el mismo pedido: IDs diferentes y fechas diferentes.
- El historial de ediciones del pedido entregado registra cambios de ruta/GPS, no modificación del precio de mercadería. Esto no prueba el importe al crear ni descarta una escritura no auditada.
- El trigger especial Boom Store modifica `precio_delivery`, `delivery_cliente` y `delivery_subsidio_tienda`, pero NO `precio_mercaderia`.
- Al consultar no había cierre del motorista para 11/11 ni pagos de la tienda registrados ese día. Verificar de nuevo inmediatamente antes de cualquier ajuste.

## Corrección pendiente (NO ejecutar automáticamente)
Hay que confirmar cuánto recibió realmente el motorista por ese pedido: ¿Gs. 90.000 o Gs. 120.000? Si cobró Gs. 120.000, se requiere devolución o acuerdo documentado de Gs. 30.000 antes de declarar que el movimiento real fue Gs. 90.000.
**No reducir silenciosamente efectivo cobrado ni borrar el movimiento.** La corrección del importe comercial y conciliación de caja debe realizarse en una transacción auditada específica, luego de verificar el cobro físico y que no exista rendición/pago/cierre posterior.
No se crea un ajuste inventado sin prueba del efectivo real.

## Protección implementada en PR
1. Tienda: confirma mercadería, delivery, total cliente y subsidio separadamente antes de enviar. Cambios del formulario obligan a revisar de nuevo.
2. Motorista: antes de marcar entregado, ve mercadería, delivery y total y confirma haber verificado los importes.
3. DB: el precio inicial queda guardado; cada cambio posterior de mercadería o de delivery queda auditado en tabla nueva protegida por RLS. Se bloquean modificaciones de importes en pedidos finalizados o con movimiento financiero.
4. No se altera automáticamente ningún dato histórico.

## Publicación segura
- Probar con pedidos ficticios el SQL en Supabase de ensayo o PostgreSQL local antes de aplicar.
- Revisar que no rompa otras operaciones de actualización y que las reglas especiales de Boom Store permanezcan intactas.
- Tras aprobación, aplicar migración al proyecto de producción correcto, **antes** de fusionar la rama y desplegar HTML.
- Para el pedido de cliente del incidente, ejecutar una conciliación auditada específica y comprobable, verificando previamente efectivo real. No hacerlo mediante una edición directa aislada.
