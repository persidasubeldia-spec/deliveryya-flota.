-- Respaldo exacto de public.motorista_registrar_entrega_anterior, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.motorista_registrar_entrega_anterior(p_pedido uuid, p_fecha date, p_medio text, p_version integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_p public.pedidos%rowtype;v_fecha date;v_ahora timestamptz;v_registro timestamptz;v_mov uuid;
BEGIN
 v_ahora=now();
 v_fecha=(v_ahora AT TIME ZONE 'America/Asuncion')::date;
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.motoristas m WHERE m.id=v_p.motorista_id AND m.usuario_id=auth.uid() AND m.activo)
 AND NOT EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.empresa_id=v_p.empresa_id AND u.usuario_id=auth.uid() AND u.activo AND u.rol IN ('propietario','socio'))
 THEN RAISE EXCEPTION 'Sin autorización para esta entrega'; END IF;
 IF v_p.estado<>'pendiente' THEN RAISE EXCEPTION 'Solo se puede confirmar un pedido pendiente'; END IF;
 IF coalesce(v_p.version_edicion,0)<>p_version THEN RAISE EXCEPTION 'Pedido modificado: actualizá tu pantalla';END IF;
 IF p_fecha>=v_fecha OR p_fecha<v_fecha-7 THEN RAISE EXCEPTION 'La fecha debe ser anterior y dentro de los últimos 7 días'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.rutas_generales r WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_p.empresa_id AND r.fecha=p_fecha AND r.estado<>'cerrada')
 THEN RAISE EXCEPTION 'El pedido ya no pertenece a esa ruta o la ruta está cerrada'; END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c WHERE c.empresa_id=v_p.empresa_id AND c.motorista_id=v_p.motorista_id AND c.fecha=p_fecha)
 THEN RAISE EXCEPTION 'Caja histórica cerrada: requiere ajuste autorizado por Central'; END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros mf WHERE mf.pedido_id=p_pedido)
 THEN RAISE EXCEPTION 'Ya existe movimiento financiero para el pedido'; END IF;
 IF p_medio NOT IN ('efectivo','transferencia','pagado_previo') THEN RAISE EXCEPTION 'Medio de cobro inválido'; END IF;
 IF (v_p.modalidad_pago='todo_pagado' AND p_medio<>'pagado_previo')
 OR (v_p.modalidad_pago<>'todo_pagado' AND p_medio='pagado_previo')
 THEN RAISE EXCEPTION 'Medio incompatible con modalidad de pago'; END IF;
 -- El movimiento se registra con fecha contable anterior y hora original en columna separada.
 PERFORM public.motorista_cerrar_entrega(p_pedido,p_medio,'entregado',NULL);
 v_registro=(p_fecha::timestamp + time '12:00') AT TIME ZONE 'America/Asuncion';
 UPDATE public.movimientos_financieros SET created_at=v_registro,registrado_real_en=v_ahora
 WHERE pedido_id=p_pedido AND motorista_id=v_p.motorista_id AND liquidado=false RETURNING id INTO v_mov;
 IF v_mov IS NULL THEN RAISE EXCEPTION 'No se registró el cobro íntegro'; END IF;
 UPDATE public.pedidos SET version_edicion=p_version+1,updated_at=v_ahora WHERE id=p_pedido;
 INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 VALUES(p_pedido,v_p.empresa_id,v_p.tienda_id,auth.uid(),p_version,p_version+1,
 jsonb_build_object('accion','entrega_historica_confirmada','fecha_operativa',p_fecha,
 'fecha_registro_real',v_ahora,'medio_cobro',p_medio,'movimiento_id',v_mov,
 'estado_anterior',v_p.estado,'estado_nuevo','entregado'));
 RETURN jsonb_build_object('pedido_id',p_pedido,'fecha_operativa',p_fecha,'movimiento_id',v_mov);
END
$function$
