-- Respaldo exacto de public.flota_resumen_ajustes_tienda, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_resumen_ajustes_tienda(p_fecha date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;
begin
 select u.empresa_id into v_empresa from public.flota_usuarios u where u.usuario_id=auth.uid() and u.activo and
 (u.rol='propietario' or u.puede_finanzas) limit 1;
 if v_empresa is null then raise exception 'Sin permiso de finanzas';end if;
 return jsonb_build_object(
  'compensaciones',coalesce((select jsonb_agg(jsonb_build_object('tienda_id',c.tienda_id,'pedido_id',c.pedido_id,'importe',c.importe,'referencia',c.referencia,'fecha',c.confirmado_en)) from public.flota_compensaciones_tienda c where c.empresa_id=v_empresa and c.fecha_rendicion=p_fecha),'[]'::jsonb),
  'pagos',coalesce((select jsonb_agg(jsonb_build_object('tienda_id',p.tienda_id,'importe',p.importe,'medio',p.medio,'referencia',p.referencia,'fecha',p.confirmado_en)) from public.flota_pagos_tienda p where p.empresa_id=v_empresa and p.fecha_rendicion=p_fecha),'[]'::jsonb)
 );
end $function$
