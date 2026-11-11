-- Respaldo exacto de public.flota_compensar_rechazo_en_rendicion, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_compensar_rechazo_en_rendicion(p_pedido uuid, p_fecha_rendicion date, p_referencia text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_r public.flota_rechazos_detalle%rowtype;
 v_p public.pedidos%rowtype;
 v_merc integer;v_descuentos integer;v_pagos integer;v_disponible integer;v_id uuid;
BEGIN
 IF p_pedido IS NULL OR p_fecha_rendicion IS NULL OR p_fecha_rendicion<>(now() AT TIME ZONE 'America/Asuncion')::date
 THEN RAISE EXCEPTION 'La compensación debe registrarse en la rendición de hoy';END IF;
 IF length(btrim(coalesce(p_referencia,'')))<5 THEN RAISE EXCEPTION 'Indicá la referencia del acuerdo de descuento';END IF;
 SELECT * INTO v_r FROM public.flota_rechazos_detalle WHERE pedido_id=p_pedido FOR UPDATE;
 IF NOT FOUND OR v_r.responsable_pago<>'tienda' OR v_r.importe_pendiente<=0
 THEN RAISE EXCEPTION 'Rechazo no facturable a tienda o ya cobrado';END IF;
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido;
 IF v_p.estado<>'rechazado' OR v_p.empresa_id IS DISTINCT FROM v_r.empresa_id OR v_p.tienda_id IS DISTINCT FROM v_r.tienda_id
 THEN RAISE EXCEPTION 'Pedido o tienda no conciliable';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=v_r.empresa_id AND u.activo AND (u.rol='propietario' OR u.puede_confirmar_rendiciones))
 THEN RAISE EXCEPTION 'No autorizado para aplicar el descuento';END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_r.empresa_id::text),pg_catalog.hashtext(v_r.tienda_id::text||p_fecha_rendicion::text));
 IF EXISTS(SELECT 1 FROM public.flota_compensaciones_tienda WHERE pedido_id=p_pedido)
 THEN RAISE EXCEPTION 'El rechazo ya fue descontado en una rendición; no se duplica';END IF;
 SELECT coalesce(sum(CASE
  WHEN p.estado='entregado' AND p.modalidad_pago='pendiente' THEN m.monto_mercaderia-coalesce(p.delivery_subsidio_tienda,0)
  WHEN p.estado='entregado' AND p.modalidad_pago='todo_pagado' THEN -m.monto_delivery
  WHEN p.estado='entregado' AND p.modalidad_pago='producto_pagado' THEN -coalesce(p.delivery_subsidio_tienda,0)
  ELSE 0 END),0)::integer
 INTO v_merc
 FROM public.movimientos_financieros m
 JOIN public.pedidos p ON p.id=m.pedido_id
 WHERE m.empresa_id=v_r.empresa_id AND m.tienda_id=v_r.tienda_id
 AND (m.created_at AT TIME ZONE 'America/Asuncion')::date=p_fecha_rendicion;
 SELECT coalesce(sum(importe),0)::integer INTO v_descuentos
 FROM public.flota_compensaciones_tienda WHERE empresa_id=v_r.empresa_id AND tienda_id=v_r.tienda_id AND fecha_rendicion=p_fecha_rendicion;
 SELECT coalesce(sum(importe),0)::integer INTO v_pagos
 FROM public.flota_pagos_tienda WHERE empresa_id=v_r.empresa_id AND tienda_id=v_r.tienda_id AND fecha_rendicion=p_fecha_rendicion;
 v_disponible:=v_merc-v_descuentos-v_pagos;
 IF v_disponible<v_r.importe_pendiente THEN
  RAISE EXCEPTION 'La tienda solo tiene saldo libre de % Gs. El rechazo pendiente de % Gs sigue como deuda y no se duplicó',greatest(v_disponible,0),v_r.importe_pendiente;
 END IF;
 INSERT INTO public.flota_compensaciones_tienda(empresa_id,tienda_id,pedido_id,fecha_rendicion,importe,referencia,confirmado_por)
 VALUES(v_r.empresa_id,v_r.tienda_id,p_pedido,p_fecha_rendicion,v_r.importe_pendiente,btrim(p_referencia),auth.uid())
 RETURNING id INTO v_id;
 RETURN jsonb_build_object('descuento_id',v_id,'pedido_id',p_pedido,'tienda_id',v_r.tienda_id,
  'importe',v_r.importe_pendiente,'fecha_aplicacion',p_fecha_rendicion,'saldo_previo',v_disponible);
END;$function$
