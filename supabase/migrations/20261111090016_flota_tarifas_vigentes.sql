-- Respaldo exacto de public.flota_tarifas_vigentes, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_tarifas_vigentes(p_empresa uuid)
 RETURNS TABLE(localidad text, costo_envio integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT tz.localidad,tz.costo_envio
 FROM public.tarifas_zona tz
 WHERE tz.empresa_id=p_empresa AND tz.activo
 AND (
  EXISTS (SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=p_empresa AND u.activo)
  OR EXISTS (
   SELECT 1 FROM public.tiendas t
   WHERE t.empresa_id=p_empresa AND t.activo AND
   (t.usuario_id=auth.uid() OR EXISTS (SELECT 1 FROM public.tienda_miembros tm WHERE tm.tienda_id=t.id AND tm.usuario_id=auth.uid() AND tm.activo))
  )
 )
 ORDER BY tz.localidad;
$function$
