-- Respaldo exacto de public.flota_registrar_pago_tienda, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_registrar_pago_tienda(p_tienda uuid, p_fecha date, p_importe integer, p_medio text, p_referencia text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_id uuid;v_base bigint;v_comp bigint;v_rechazos bigint;v_pagado bigint;v_fecha date;
begin
 select u.empresa_id into v_empresa from public.flota_usuarios u where u.usuario_id=auth.uid() and u.activo and
 (u.rol='propietario' or u.puede_confirmar_rendiciones) limit 1;
 if v_empresa is null then raise exception 'No autorizado para registrar pagos';end if;
 if not exists(select 1 from public.tiendas t where t.id=p_tienda and t.empresa_id=v_empresa) then raise exception 'Tienda no autorizada';end if;
 v_fecha=(now() at time zone 'America/Asuncion')::date;
 if p_fecha is null or p_fecha>v_fecha or p_importe is null or p_importe<=0 or p_medio not in ('efectivo','transferencia')
 or length(btrim(coalesce(p_referencia,'')))<5 then raise exception 'Datos de pago inválidos';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text||p_tienda::text),pg_catalog.hashtext(p_fecha::text));
 select coalesce(sum(case when p.estado='entregado' and p.modalidad_pago='pendiente' then m.monto_mercaderia-coalesce(p.delivery_subsidio_tienda,0) else 0 end),0)
       -coalesce(sum(case when p.estado='entregado' and p.modalidad_pago='todo_pagado' then m.monto_delivery when p.estado='entregado' and p.modalidad_pago='producto_pagado' then coalesce(p.delivery_subsidio_tienda,0) else 0 end),0)
 into v_base from public.movimientos_financieros m join public.pedidos p on p.id=m.pedido_id
 where m.empresa_id=v_empresa and m.tienda_id=p_tienda
 and (m.created_at at time zone 'America/Asuncion')::date=p_fecha;
 select coalesce(sum(c.importe),0) into v_comp from public.flota_compensaciones_tienda c
 where c.empresa_id=v_empresa and c.tienda_id=p_tienda and c.fecha_rendicion=p_fecha;
 select coalesce(sum(r.importe_pendiente),0) into v_rechazos
 from public.flota_rechazos_detalle r join public.pedidos p on p.id=r.pedido_id
 join public.movimientos_financieros m on m.pedido_id=p.id
 where r.empresa_id=v_empresa and r.tienda_id=p_tienda and p.estado='rechazado' and r.responsable_pago='tienda'
 and r.importe_pendiente>0
 and (m.created_at at time zone 'America/Asuncion')::date=p_fecha
 and not exists(select 1 from public.flota_compensaciones_tienda c where c.pedido_id=r.pedido_id);
 select coalesce(sum(x.importe),0) into v_pagado from public.flota_pagos_tienda x
 where x.empresa_id=v_empresa and x.tienda_id=p_tienda and x.fecha_rendicion=p_fecha;
 if p_importe>v_base-v_comp-v_rechazos-v_pagado then
   raise exception 'El pago excede el saldo neto: los rechazos de la tienda ya están descontados';
 end if;
 insert into public.flota_pagos_tienda(empresa_id,tienda_id,fecha_rendicion,importe,medio,referencia,confirmado_por)
 values(v_empresa,p_tienda,p_fecha,p_importe,p_medio,btrim(p_referencia),auth.uid()) returning id into v_id;
 return v_id;
end $function$
