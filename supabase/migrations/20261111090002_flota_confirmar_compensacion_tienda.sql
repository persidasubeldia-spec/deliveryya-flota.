-- Respaldo exacto de public.flota_confirmar_compensacion_tienda, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_confirmar_compensacion_tienda(p_pedido uuid, p_fecha date, p_referencia text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_id uuid;v_tienda uuid;v_importe integer;v_fecha_ruta date;
begin
 select u.empresa_id into v_empresa from public.flota_usuarios u where u.usuario_id=auth.uid() and u.activo and
 (u.rol='propietario' or u.puede_confirmar_rendiciones) limit 1;
 if v_empresa is null then raise exception 'No autorizado para compensar';end if;
 if length(btrim(coalesce(p_referencia,'')))<5 then raise exception 'Falta referencia del acuerdo de compensación';end if;
 if p_fecha is null or p_fecha>(now() at time zone 'America/Asuncion')::date then raise exception 'Fecha inválida';end if;
 select r.tienda_id,r.importe_pendiente,g.fecha into v_tienda,v_importe,v_fecha_ruta
 from public.flota_rechazos_detalle r join public.pedidos p on p.id=r.pedido_id
 left join public.rutas_generales g on g.id=p.ruta_general_id
 where r.pedido_id=p_pedido and r.empresa_id=v_empresa and r.responsable_pago='tienda' and p.estado='rechazado' for update of r;
 if v_tienda is null or v_importe is null or v_importe<=0 or v_fecha_ruta is distinct from p_fecha then
 raise exception 'El rechazo no es elegible o no corresponde a la fecha';end if;
 insert into public.flota_compensaciones_tienda(empresa_id,tienda_id,pedido_id,fecha_rendicion,importe,referencia,confirmado_por)
 values(v_empresa,v_tienda,p_pedido,p_fecha,v_importe,btrim(p_referencia),auth.uid()) returning id into v_id;
 return v_id;
end $function$
