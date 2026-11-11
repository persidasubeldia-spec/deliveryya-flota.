-- Respaldo exacto de public.motorista_recorrido_actual, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.motorista_recorrido_actual()
 RETURNS TABLE(fecha date, version bigint, pedido_ids uuid[], coordenadas jsonb, origen_lat double precision, origen_lng double precision, confirmado_en timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select c.fecha,c.version,c.pedido_ids,c.coordenadas,c.origen_lat,c.origen_lng,c.confirmado_en
 from public.motorista_recorridos_confirmados c
 join public.motoristas m on m.id=c.motorista_id
 where m.usuario_id=(select auth.uid()) and m.activo and c.fecha=(now() at time zone 'America/Asuncion')::date;
$function$
