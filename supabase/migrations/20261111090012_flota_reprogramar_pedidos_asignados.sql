-- Respaldo exacto de public.flota_reprogramar_pedidos_asignados, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_reprogramar_pedidos_asignados(p_pedidos uuid[], p_motorista_destino uuid, p_fecha_destino date, p_turno_destino text, p_versiones jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_total integer; v_empresa uuid; v_pct integer; v_hoy date;
 v_ruta_dest uuid; v_num integer; v_pos integer;
 v_id uuid; v_p public.pedidos%rowtype; v_orig public.rutas_generales%rowtype;
 v_cambios jsonb:='[]'::jsonb; v_v integer;
BEGIN
 v_hoy:=(now() AT TIME ZONE 'America/Asuncion')::date;
 v_total:=coalesce(array_length(p_pedidos,1),0);
 IF v_total<1 OR v_total>100 OR (SELECT count(DISTINCT t.id) FROM unnest(p_pedidos) t(id))<>v_total THEN RAISE EXCEPTION 'Seleccioná de 1 a 100 pedidos sin duplicar'; END IF;
 IF p_fecha_destino IS NULL OR p_fecha_destino<v_hoy OR p_fecha_destino>v_hoy+14 THEN RAISE EXCEPTION 'La nueva fecha debe estar entre hoy y los próximos 14 días'; END IF;
 IF p_turno_destino NOT IN ('manana','tarde') THEN RAISE EXCEPTION 'Elegí mañana o tarde'; END IF;
 IF p_versiones IS NULL OR jsonb_typeof(p_versiones)<>'object' THEN RAISE EXCEPTION 'Faltan versiones de los pedidos'; END IF;
 SELECT m.empresa_id,m.porcentaje_empresa_pct INTO v_empresa,v_pct
 FROM public.motoristas m WHERE m.id=p_motorista_destino AND m.activo FOR UPDATE;
 IF NOT FOUND OR v_pct NOT BETWEEN 0 AND 100 THEN RAISE EXCEPTION 'Motorista destino no disponible'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=v_empresa AND u.activo AND u.rol IN ('propietario','socio','operador')) THEN RAISE EXCEPTION 'Sin permiso para mover pedidos'; END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(p_fecha_destino::text||p_turno_destino));
 PERFORM 1 FROM public.pedidos p WHERE p.id=ANY(p_pedidos) ORDER BY p.id FOR UPDATE;
 IF (SELECT count(*) FROM public.pedidos WHERE id=ANY(p_pedidos))<>v_total THEN RAISE EXCEPTION 'Hay pedidos que ya no existen'; END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas WHERE empresa_id=v_empresa AND motorista_id=p_motorista_destino AND fecha=p_fecha_destino) THEN RAISE EXCEPTION 'La caja de destino ya está cerrada'; END IF;
 SELECT r.id INTO v_ruta_dest FROM public.rutas_generales r
 WHERE r.empresa_id=v_empresa AND r.fecha=p_fecha_destino AND r.turno=p_turno_destino AND r.estado IN ('abierta','optimizada','en_reparto')
 ORDER BY r.created_at,r.id LIMIT 1 FOR UPDATE;
 IF v_ruta_dest IS NULL THEN
    INSERT INTO public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion)
    VALUES(v_empresa,p_fecha_destino,p_turno_destino,'en_reparto',0)
    RETURNING id INTO v_ruta_dest;
 END IF;
 SELECT coalesce(max(p.numero_general),0) INTO v_num FROM public.pedidos p WHERE p.ruta_general_id=v_ruta_dest;
 SELECT coalesce(max(o.posicion),0) INTO v_pos FROM public.motorista_ordenes_pedidos o WHERE o.motorista_id=p_motorista_destino AND o.fecha=p_fecha_destino;
 FOR v_id IN SELECT t.id FROM unnest(p_pedidos) t(id) ORDER BY t.id LOOP
    SELECT * INTO v_p FROM public.pedidos WHERE id=v_id;
    IF v_p.empresa_id<>v_empresa OR v_p.motorista_id IS NULL THEN RAISE EXCEPTION 'Pedido % no pertenece a una moto de esta empresa',v_id; END IF;
    IF v_p.estado NOT IN ('pendiente','no_responde','no_recibio','pasa_manana') THEN RAISE EXCEPTION 'Pedido % ya terminado',v_id; END IF;
    IF NOT (p_versiones ? v_id::text) OR (p_versiones->>v_id::text) !~ '^[0-9]+$' THEN RAISE EXCEPTION 'Falta versión del pedido %',v_id; END IF;
    v_v:=(p_versiones->>v_id::text)::integer;
    IF coalesce(v_p.version_edicion,0)<>v_v THEN RAISE EXCEPTION 'Pedido % cambiado por otra persona: actualizá la pantalla',v_id; END IF;
    IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_id) THEN RAISE EXCEPTION 'Pedido % tiene cobros y no se puede mover',v_id; END IF;
    SELECT * INTO v_orig FROM public.rutas_generales r WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_empresa;
    IF NOT FOUND OR v_orig.estado='cerrada' THEN RAISE EXCEPTION 'Pedido % tiene origen sin ruta válida o cerrada',v_id; END IF;
    IF v_orig.fecha>=p_fecha_destino THEN RAISE EXCEPTION 'La fecha destino debe ser posterior a la fecha de origen'; END IF;
    IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c WHERE c.empresa_id=v_empresa AND c.motorista_id=v_p.motorista_id AND c.fecha=v_orig.fecha) THEN RAISE EXCEPTION 'La caja original del pedido % está cerrada',v_id; END IF;
    DELETE FROM public.motorista_ordenes_pedidos WHERE pedido_id=v_id;
    v_num:=v_num+1;v_pos:=v_pos+1;
    UPDATE public.pedidos SET ruta_general_id=v_ruta_dest,numero_general=v_num,
      motorista_id=p_motorista_destino,turno=p_turno_destino,estado='pendiente',motivo_incidencia=NULL,
      porcentaje_empresa_pct=v_pct,porcentaje_motorista_pct=100-v_pct,
      requiere_revisar_ruta=true,version_edicion=v_v+1,updated_at=now()
    WHERE id=v_id;
    INSERT INTO public.motorista_ordenes_pedidos(motorista_id,fecha,pedido_id,posicion)
    VALUES(p_motorista_destino,p_fecha_destino,v_id,v_pos);
    INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
    VALUES(v_id,v_empresa,v_p.tienda_id,auth.uid(),v_v,v_v+1,
     jsonb_build_object('accion','reprogramar_pedido_asignado','motorista_anterior',v_p.motorista_id,
     'motorista_nuevo',p_motorista_destino,'fecha_anterior',v_orig.fecha,'fecha_nueva',p_fecha_destino,
     'turno_anterior',v_p.turno,'turno_nuevo',p_turno_destino,'numero_anterior',v_p.numero_general,
     'numero_nuevo',v_num,'estado_anterior',v_p.estado,'motivo_anterior',v_p.motivo_incidencia));
    v_cambios:=v_cambios||jsonb_build_array(jsonb_build_object('pedido_id',v_id,'numero_nuevo',v_num));
 END LOOP;
 UPDATE public.rutas_generales SET estado='en_reparto' WHERE id=v_ruta_dest AND estado IN ('abierta','optimizada');
 RETURN jsonb_build_object('total',v_total,'ruta_destino',v_ruta_dest,'fecha_destino',p_fecha_destino,'motorista_id',p_motorista_destino,'pedidos',v_cambios);
END;
$function$
