# Importes ingresados originalmente por la tienda · 2026-11-11

## Qué resuelve
La regla especial de Boom Store puede convertir un envío introducido como Gs. 20.000 en una tarifa interna de Gs. 25.000. Hasta esta mejora la aplicación no conservaba **el número bruto original** en una columna propia. Era imposible reconstruirlo con certeza a partir de la tarifa normalizada.

- Se incorporan dos columnas **inmutables** en `public.pedidos`: `precio_mercaderia_cargado_tienda` y `precio_delivery_cargado_tienda`.
- Al crear nuevos pedidos desde Tienda, se graban el valor original de mercadería y el envío ingresado/seleccionado, antes de la regla Boom.
- Central muestra **Tienda cargó**, **Cliente paga**, **Subsidio tienda** y **Tarifa real**, tanto en listado y detalle como en el editor.
- Si un pedido antiguo no tiene los originales conservados, Central dice **No registrado**: no inventa que 20.000 o 25.000 fue necesariamente el valor ingresado.
- El trigger no modifica precios, caja, comisiones o subsidios; impide reescribir los valores originales.
- Se valida en PostgreSQL 17 aislado con 8 pruebas SQL nuevas además de la suite existente.

## Despliegue
Primero aplicar migración en Supabase producción `sxhuvjvbqkovivcbisrn`, verificar columnas/triggers, después publicar HTML mediante PR GitHub. Para evitar fallos de PostgREST, actualizar la caché de esquema si hiciera falta mediante procedimiento de Supabase.
