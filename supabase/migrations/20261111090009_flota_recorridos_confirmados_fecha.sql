-- Respaldo exacto de public.flota_recorridos_confirmados_fecha, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_recorridos_confirmados_fecha(p_fecha date)
 RETURNS TABLE(motorista_id uuid, empresa_id uuid, fecha date, version bigint, pedido_ids uuid[], coordenadas jsonb, origen_lat double precision, origen_lng double precision, confirmado_en timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select c.motorista_id,c.empresa_id,c.fecha,c.version,c.pedido_ids,c.coordenadas,c.origen_lat,c.origen_lng,c.confirmado_en
 from public.motorista_recorridos_confirmados c
 where c.fecha=p_fecha and exists(
   select 1 from public.flota_usuarios u where u.empresa_id=c.empresa_id
    and u.usuario_id=(select auth.uid()) and u.activo and u.rol in('propietario','socio','operador')
 );
$function$
