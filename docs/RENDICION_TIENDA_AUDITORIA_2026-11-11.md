# Rendición a tiendas — conciliación reforzada (11/11/2026)

La vista de **Central → Rendiciones → Rendiciones a tiendas** muestra la auditoría por tienda. Si hay diferencia de movimientos, subsidios o cargo de rechazo, se bloquean los botones de descarga y compartir y se indica la causa. Al descargar, se consultan nuevamente los datos de Supabase antes de generar el documento.

## Fórmula oficial
- `mercaderia`: suma de `monto_mercaderia` de pedidos **entregados y pagados al recibir**.
- `subsidios`: suma del `delivery_subsidio_tienda` **sólo en entregados**; en Boom mínimo 25.000 reales, cliente 20.000, aporte tienda 5.000.
- `enviosTienda`: envíos a cargo de tiendas para pedidos `todo_pagado`.
- `rechazos`: envío a cargo de tienda con detalle registrado, descontado **una vez**, o sustituido por compensación explícita; en ambos casos nunca es cobro en efectivo del motorista.
- `compensaciones`: descuentos confirmados; `pagos`: pagos a tienda efectivamente registrados.
- `neto = mercadería - subsidios - enviosTienda - rechazosPendientes - compensaciones`
- `saldo = neto - pagos`

## Caso verificable del 11/11/2026 — T14 Boom Store
- 17 entregas: mercadería **Gs. 1.460.000**.
- Subsidio entregas: **Gs. 60.000**.
- Fabby rechazado, cargo tienda: **Gs. 25.000**, cliente 0. No sumar subsidio del rechazo como otro cargo.
- `1.460.000 - 60.000 - 25.000 = 1.375.000`. Pagos confirmados a tienda: 0.
- Diferencia entre ganancia flota sólo entregas Gs. 108.750 y con rechazo Gs. 115.000 no se revela en el PDF de tienda, pues las comisiones son internas.

## Controles agregados
1. A cada pedido corresponde un solo movimiento válido, sin dinero negativo.
2. Reparto de tarifa real coincide con empresa + motorista.
3. El cobro a cliente respeta modalidad y subsidio separado.
4. El rechazo requiere detalle, responsable e importe reconciliable.
5. No se puede descontar dos veces un rechazo compensado.
6. Cada suma parcial concuerda con su total y saldo final.
7. Los pedidos pendientes sin movimiento sólo figuran como informativos.
8. Descargar PDF requiere una lectura nueva y auditoría aprobada.
9. PDF añade columna subsidio, corrige título a "Envío cliente", conserva colores por estado y no revela comisiones internas.

**Límites**: estas validaciones protegen la generación dentro de Central, pero no sustituyen un cierre contable firmado ni prueban una transferencia fuera del sistema. Un PDF histórico se regenerará con los datos vigentes; aún no hay un mecanismo de archivo inmutable con versión y firma digital.
