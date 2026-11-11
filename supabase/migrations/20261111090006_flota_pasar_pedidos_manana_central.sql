-- Respaldo exacto de public.flota_pasar_pedidos_manana_central, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_pasar_pedidos_manana_central(p_pedidos uuid[], p_versiones jsonb, p_fecha_origen date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_hoy date := (now() AT TIME ZONE 'America/Asuncion')::date;
 v_manana date := (now() AT TIME ZONE 'America/Asuncion')::date+1;
 v_empresa uuid;
 v_usuario uuid:=auth.uid();
 v_total integer;
 v_id uuid;
 v_p public.pedidos%rowtype;
 v_orig public.rutas_generales%rowtype;
 v_ruta uuid;
 v_num integer;
 v_v integer;
 v_items jsonb:='[]'::jsonb;
BEGIN
 IF v_usuario IS NULL THEN RAISE EXCEPTION 'Debés iniciar sesión';END IF;
 IF p_fecha_origen IS NULL OR p_fecha_origen<>v_hoy THEN
  RAISE EXCEPTION 'Solo podés pasar a mañana pedidos de la jornada actual';END IF;
 v_total:=coalesce(cardinality(p_pedidos),0);
 IF v_total<1 OR v_total>100 OR
   (SELECT count(DISTINCT v.id) FROM unnest(p_pedidos) v(id))<>v_total OR
   EXISTS(SELECT 1 FROM unnest(p_pedidos) v(id) WHERE v.id IS NULL) THEN
  RAISE EXCEPTION 'Seleccioná de 1 a 100 pedidos sin duplicaciones';END IF;
 IF p_versiones IS NULL OR jsonb_typeof(p_versiones)<>'object' THEN
  RAISE EXCEPTION 'Faltan las versiones de edición';END IF;
 SELECT empresa_id INTO v_empresa FROM public.flota_usuarios
 WHERE usuario_id=v_usuario AND activo AND rol IN ('propietario','socio','operador')
 ORDER BY created_at LIMIT 1;
 IF v_empresa IS NULL THEN RAISE EXCEPTION 'No tenés permisos para mover pedidos';END IF;
 -- Mismo candado que usa Pasa mañana del motorista: evita rutas y números duplicados.
 PERFORM pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(v_manana::text||'manana'));
 PERFORM 1 FROM public.pedidos p WHERE p.id=ANY(p_pedidos) ORDER BY p.id FOR UPDATE;
 IF (SELECT count(*) FROM public.pedidos WHERE id=ANY(p_pedidos))<>v_total THEN
  RAISE EXCEPTION 'Uno o más pedidos ya no existen';END IF;
 -- Validación completa ANTES de cualquier actualización: lote todo o nada.
 FOR v_id IN SELECT z.id FROM unnest(p_pedidos) z(id) ORDER BY z.id LOOP
  SELECT * INTO v_p FROM public.pedidos WHERE id=v_id;
  IF v_p.empresa_id<>v_empresa OR v_p.estado NOT IN ('pendiente','no_responde','no_recibio') THEN
   RAISE EXCEPTION 'Pedido % no es pendiente de esta empresa',v_id;END IF;
  IF NOT(p_versiones ? v_id::text) OR
    (p_versiones->>v_id::text)!~'^[0-9]+$' THEN
   RAISE EXCEPTION 'Falta la versión del pedido %',v_id;END IF;
  v_v:=(p_versiones->>v_id::text)::integer;
  IF v_p.version_edicion IS DISTINCT FROM v_v THEN
   RAISE EXCEPTION 'El pedido % fue modificado; actualizá la lista',v_id;END IF;
  IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_id)
   OR EXISTS(SELECT 1 FROM public.flota_rechazos_detalle d WHERE d.pedido_id=v_id)
  THEN RAISE EXCEPTION 'El pedido % tiene movimientos financieros',v_id;END IF;
  IF v_p.ruta_general_id IS NOT NULL THEN
   SELECT * INTO v_orig FROM public.rutas_generales r
   WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_empresa;
   IF NOT FOUND OR v_orig.fecha<>v_hoy OR v_orig.estado='cerrada' THEN
    RAISE EXCEPTION 'El pedido % no está en una ruta activa de hoy',v_id;END IF;
  ELSE
   IF v_p.motorista_id IS NOT NULL OR
    (v_p.created_at AT TIME ZONE 'America/Asuncion')::date<>v_hoy THEN
    RAISE EXCEPTION 'El pedido % sin ruta no corresponde a la carga de hoy',v_id;END IF;
  END IF;
  IF v_p.motorista_id IS NOT NULL AND EXISTS(
   SELECT 1 FROM public.flota_cierres_motoristas c
   WHERE c.empresa_id=v_empresa AND c.motorista_id=v_p.motorista_id AND c.fecha=v_hoy)
  THEN RAISE EXCEPTION 'La caja de origen de % ya está cerrada',v_id;END IF;
 END LOOP;
 SELECT id INTO v_ruta FROM public.rutas_generales
 WHERE empresa_id=v_empresa AND fecha=v_manana AND turno='manana'
 AND estado IN ('abierta','optimizada','en_reparto')
 ORDER BY created_at,id LIMIT 1 FOR UPDATE;
 IF v_ruta IS NULL THEN
  INSERT INTO public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion)
  VALUES(v_empresa,v_manana,'manana','abierta',0) RETURNING id INTO v_ruta;
 END IF;
 SELECT coalesce(max(numero_general),0) INTO v_num
 FROM public.pedidos WHERE ruta_general_id=v_ruta;
 FOR v_id IN SELECT z.id FROM unnest(p_pedidos) z(id) ORDER BY z.id LOOP
  SELECT * INTO v_p FROM public.pedidos WHERE id=v_id;
  v_num:=v_num+1;
  DELETE FROM public.motorista_ordenes_pedidos WHERE pedido_id=v_id;
  UPDATE public.pedidos SET
   ruta_general_id=v_ruta,numero_general=v_num,motorista_id=NULL,
   turno='manana',estado='pendiente',medio_cobro=NULL,
   motivo_incidencia='Reprogramado desde '||to_char(v_hoy,'DD/MM/YYYY')||' · Reprogramado por Central',
   requiere_revisar_ruta=true,version_edicion=v_p.version_edicion+1,updated_at=now()
  WHERE id=v_id;
  INSERT INTO public.pedidos_ediciones(
   pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  VALUES(v_id,v_empresa,v_p.tienda_id,v_usuario,
   v_p.version_edicion,v_p.version_edicion+1,
   pg_catalog.jsonb_build_object(
    'accion','pasar_manana_central','fecha_anterior',v_hoy,'fecha_nueva',v_manana,
    'ruta_anterior',v_p.ruta_general_id,'ruta_nueva',v_ruta,
    'motorista_anterior',v_p.motorista_id,'motorista_nuevo',NULL,
    'estado_anterior',v_p.estado,'estado_nuevo','pendiente',
    'turno_anterior',v_p.turno,'turno_nuevo','manana',
    'numero_anterior',v_p.numero_general,'numero_nuevo',v_num,
    'motivo_anterior',v_p.motivo_incidencia,
    'motivo_nuevo','Reprogramado por Central',
    'precio_delivery_preservado',v_p.precio_delivery));
  v_items:=v_items||pg_catalog.jsonb_build_array(
   pg_catalog.jsonb_build_object('pedido_id',v_id,'numero_nuevo',v_num));
 END LOOP;
 RETURN pg_catalog.jsonb_build_object('total',v_total,'fecha_destino',v_manana,
  'ruta_destino',v_ruta,'pedidos',v_items);
END
$function$
