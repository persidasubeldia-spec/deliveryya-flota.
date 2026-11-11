-- Respaldo exacto de public.flota_ordenes_motoristas_fecha, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_ordenes_motoristas_fecha(p_fecha date)
 RETURNS TABLE(motorista_id uuid, pedido_id uuid, posicion integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select x.motorista_id,x.pedido_id,x.posicion
 from public.motorista_ordenes_pedidos x
 join public.motoristas m on m.id=x.motorista_id
 where x.fecha=p_fecha and exists (
  select 1 from public.flota_usuarios u
  where u.usuario_id=auth.uid() and u.empresa_id=m.empresa_id and u.activo=true
 )
$function$
