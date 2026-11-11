-- Rollback SOLO en entorno de prueba / previa aprobación.
REVOKE ALL ON FUNCTION public.flota_resumen_rendicion_motoristas(date) FROM authenticated;
DROP FUNCTION IF EXISTS public.flota_resumen_rendicion_motoristas(date);
