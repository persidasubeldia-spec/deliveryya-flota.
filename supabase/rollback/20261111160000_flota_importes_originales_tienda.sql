-- Conservar las columnas con precios originales porque constituyen evidencia comercial;
-- solo se retira el bloqueo si es necesario revertir su mecanismo, sin borrar historia.
DROP TRIGGER IF EXISTS flota_importes_originales_tienda_inmutables_trg ON public.pedidos;
DROP FUNCTION IF EXISTS public.flota_proteger_importes_originales_tienda();

DROP TRIGGER IF EXISTS flota_validar_importes_originales_tienda_trg ON public.pedidos;
DROP FUNCTION IF EXISTS public.flota_validar_importes_originales_tienda();
