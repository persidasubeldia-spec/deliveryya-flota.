-- Respaldo exacto de public.flota_liberar_pedidos_seguros, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_liberar_pedidos_seguros(p_pedidos uuid[], p_versiones jsonb, p_fecha date, p_turno text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_total integer;v_empresa uuid;v_p public.pedidos%rowtype;v_f date;v_t text;v_estado text;v_id uuid;v_vers integer;v_cambiados jsonb:='[]'::jsonb;
BEGIN
 v_total:=coalesce(array_length(p_pedidos,1),0);
 IF v_total<1 OR v_total>100 OR (SELECT count(DISTINCT x) FROM unnest(p_pedidos) x)<>v_total
 THEN RAISE EXCEPTION 'Seleccioná entre 1 y 100 pedidos sin duplicados';END IF;
 IF p_versiones IS NULL OR jsonb_typeof(p_versiones)<>'object' OR p_fecha IS NULL OR p_turno NOT IN ('manana','tarde','sin_definir')
 THEN RAISE EXCEPTION 'Faltan versiones, fecha o turno';END IF;
 IF p_fecha<>(now() AT TIME ZONE 'America/Asuncion')::date THEN RAISE EXCEPTION 'La liberación directa solo está habilitada para la fecha de hoy';END IF;
 FOR v_id IN SELECT x FROM unnest(p_pedidos) x ORDER BY x LOOP
  IF NOT (p_versiones ? v_id::text) OR (p_versiones->>v_id::text) !~ '^[0-9]+$' THEN RAISE EXCEPTION 'Versión faltante para pedido %',v_id;END IF;
  v_vers:=(p_versiones->>v_id::text)::int;
  SELECT * INTO v_p FROM public.pedidos WHERE id=v_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Pedido % inexistente',v_id;END IF;
  IF v_empresa IS NULL THEN v_empresa:=v_p.empresa_id;END IF;
  IF v_empresa IS DISTINCT FROM v_p.empresa_id THEN RAISE EXCEPTION 'No se mezclan pedidos de distintas empresas';END IF;
  IF NOT EXISTS (SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=v_empresa AND u.activo AND u.rol IN ('propietario','socio','operador'))
  THEN RAISE EXCEPTION 'No autorizado para liberar pedidos';END IF;
  IF v_p.motorista_id IS NULL OR v_p.estado<>'pendiente' THEN RAISE EXCEPTION 'Pedido % no elegible: debe estar pendiente y asignado',v_id;END IF;
  IF coalesce(v_p.version_edicion,0)<>v_vers THEN RAISE EXCEPTION 'Pedido % modificado; actualizá Central',v_id;END IF;
  SELECT r.fecha,r.turno,r.estado INTO v_f,v_t,v_estado FROM public.rutas_generales r WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_empresa;
  IF v_f IS DISTINCT FROM p_fecha OR v_t IS DISTINCT FROM p_turno OR v_p.turno IS DISTINCT FROM p_turno
   OR v_estado NOT IN ('abierta','optimizada','en_reparto')
  THEN RAISE EXCEPTION 'Pedido % no pertenece a la ruta operativa abierta',v_id;END IF;
  IF EXISTS(SELECT 1 FROM public.movimientos_financieros mf WHERE mf.pedido_id=v_id)
  OR EXISTS(SELECT 1 FROM public.flota_rechazos_detalle rd WHERE rd.pedido_id=v_id)
  THEN RAISE EXCEPTION 'Pedido % con movimiento financiero: requiere revisión',v_id;END IF;
  IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c WHERE c.empresa_id=v_empresa AND c.motorista_id=v_p.motorista_id AND c.fecha=p_fecha)
  THEN RAISE EXCEPTION 'Pedido % vinculado a una caja presentada o cerrada',v_id;END IF;
  DELETE FROM public.motorista_ordenes_pedidos WHERE pedido_id=v_id AND motorista_id=v_p.motorista_id;
  UPDATE public.pedidos SET motorista_id=NULL,version_edicion=v_vers+1,requiere_revisar_ruta=true,updated_at=now() WHERE id=v_id;
  INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  VALUES(v_id,v_empresa,v_p.tienda_id,auth.uid(),v_vers,v_vers+1,
   jsonb_build_object('accion','liberar_pedido_central','motivo','Liberado para reasignar','motorista_anterior',v_p.motorista_id,
   'motorista_nuevo',NULL,'fecha',v_f,'turno',v_t,'numero_general',v_p.numero_general,'estado_conservado',v_p.estado));
  v_cambiados:=v_cambiados||jsonb_build_array(jsonb_build_object('pedido_id',v_id,'motorista_anterior',v_p.motorista_id,'version',v_vers+1));
 END LOOP;
 RETURN jsonb_build_object('total',v_total,'liberados',v_cambiados);
END;
$function$
