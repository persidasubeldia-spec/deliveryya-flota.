-- Respaldo exacto de public.motorista_pasar_pedido_manana, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.motorista_pasar_pedido_manana(p_pedido_id uuid, p_motivo text, p_version integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_p public.pedidos%rowtype;
 v_r public.rutas_generales%rowtype;
 v_hoy date := (now() AT TIME ZONE 'America/Asuncion')::date;
 v_manana date := (now() AT TIME ZONE 'America/Asuncion')::date + 1;
 v_ruta_nueva uuid;
 v_numero integer;
 v_usuario uuid := auth.uid();
 v_motivo text := btrim(coalesce(p_motivo,''));
BEGIN
 IF v_usuario IS NULL THEN RAISE EXCEPTION 'Sesión no autorizada'; END IF;
 IF p_pedido_id IS NULL OR p_version IS NULL OR p_version<0
 THEN RAISE EXCEPTION 'Faltan datos o versión del pedido'; END IF;
 IF length(v_motivo)<3 OR length(v_motivo)>300 THEN
   RAISE EXCEPTION 'Seleccioná un motivo de 3 a 300 caracteres'; END IF;
 -- Serializar las reprogramaciones del día sin bloquear otras empresas.
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente';END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtext(v_p.empresa_id::text),
  pg_catalog.hashtext(v_manana::text||'manana')
 );
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido_id FOR UPDATE;
 IF NOT EXISTS(SELECT 1 FROM public.motoristas m
  WHERE m.id=v_p.motorista_id AND m.usuario_id=v_usuario
  AND m.empresa_id=v_p.empresa_id AND m.activo)
 THEN RAISE EXCEPTION 'Este pedido ya no está asignado a tu usuario';END IF;
 IF v_p.version_edicion IS DISTINCT FROM p_version THEN
  RAISE EXCEPTION 'El pedido cambió. Actualizá la ruta y volvé a verificarlo';END IF;
 IF v_p.estado NOT IN ('pendiente','no_responde','no_recibio','pasa_manana') THEN
  RAISE EXCEPTION 'Pedido ya finalizado; no se puede reprogramar';END IF;
 IF v_p.ruta_general_id IS NULL THEN
  RAISE EXCEPTION 'El pedido no tiene una ruta original válida';END IF;
 SELECT * INTO v_r FROM public.rutas_generales
  WHERE id=v_p.ruta_general_id AND empresa_id=v_p.empresa_id FOR UPDATE;
 IF NOT FOUND OR v_r.fecha IS DISTINCT FROM v_hoy OR v_r.estado='cerrada' THEN
  RAISE EXCEPTION 'Solo se permite pasar a mañana pedidos de una ruta activa de hoy';END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c
  WHERE c.empresa_id=v_p.empresa_id AND c.motorista_id=v_p.motorista_id AND c.fecha=v_hoy)
 THEN RAISE EXCEPTION 'La caja de hoy ya fue cerrada; no se puede mover el pedido';END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_p.id)
  OR EXISTS(SELECT 1 FROM public.flota_rechazos_detalle r WHERE r.pedido_id=v_p.id)
 THEN RAISE EXCEPTION 'Este pedido tiene movimientos financieros y no se puede reprogramar';END IF;
 -- Una sola ruta general para mañana y turno mañana, reutilizando la existente.
 SELECT id INTO v_ruta_nueva FROM public.rutas_generales
 WHERE empresa_id=v_p.empresa_id AND fecha=v_manana AND turno='manana'
 AND estado IN ('abierta','optimizada','en_reparto')
 ORDER BY created_at,id LIMIT 1 FOR UPDATE;
 IF v_ruta_nueva IS NULL THEN
  INSERT INTO public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion)
  VALUES(v_p.empresa_id,v_manana,'manana','abierta',0)
  RETURNING id INTO v_ruta_nueva;
 END IF;
 SELECT coalesce(max(numero_general),0)+1 INTO v_numero
 FROM public.pedidos WHERE ruta_general_id=v_ruta_nueva;
 DELETE FROM public.motorista_ordenes_pedidos WHERE pedido_id=v_p.id;
 UPDATE public.pedidos
 SET ruta_general_id=v_ruta_nueva,
  numero_general=v_numero,
  motorista_id=NULL,
  turno='manana',
  estado='pendiente',
  medio_cobro=NULL,
  motivo_incidencia='Reprogramado desde '||to_char(v_hoy,'DD/MM/YYYY')||' · '||v_motivo,
  requiere_revisar_ruta=true,
  version_edicion=p_version+1,
  updated_at=now()
 WHERE id=v_p.id;
 INSERT INTO public.pedidos_ediciones(
  pedido_id,empresa_id,tienda_id,usuario_id,
  version_anterior,version_nueva,cambios
 ) VALUES (
  v_p.id,v_p.empresa_id,v_p.tienda_id,v_usuario,p_version,p_version+1,
  pg_catalog.jsonb_build_object(
   'accion','pasar_manana_automatico',
   'motorista_anterior',v_p.motorista_id,
   'fecha_anterior',v_hoy,
   'fecha_nueva',v_manana,
   'ruta_anterior',v_p.ruta_general_id,
   'ruta_nueva',v_ruta_nueva,
   'turno_anterior',v_p.turno,
   'turno_nuevo','manana',
   'numero_anterior',v_p.numero_general,
   'numero_nuevo',v_numero,
   'estado_anterior',v_p.estado,
   'estado_nuevo','pendiente',
   'motivo_anterior',v_p.motivo_incidencia,
   'motivo_reprogramacion',v_motivo
  )
 );
 RETURN pg_catalog.jsonb_build_object(
  'pedido_id',v_p.id,'fecha_origen',v_hoy,'fecha_destino',v_manana,
  'ruta_destino',v_ruta_nueva,'numero_nuevo',v_numero,
  'motorista_id',NULL,'estado','pendiente','reprogramado',true
 );
END
$function$
