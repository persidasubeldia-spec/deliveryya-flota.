-- Ejecutar únicamente sobre staging o tras autorización explícita.
REVOKE ALL ON FUNCTION public.flota_confirmar_recepcion_caja(uuid,integer,integer) FROM authenticated;
DROP FUNCTION IF EXISTS public.flota_confirmar_recepcion_caja(uuid,integer,integer);
