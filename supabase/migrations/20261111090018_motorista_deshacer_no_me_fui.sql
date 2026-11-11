-- Respaldo exacto de public.motorista_deshacer_no_me_fui, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.motorista_deshacer_no_me_fui(p_pedido uuid, p_version integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_p public.pedidos%rowtype;
 v_fecha date;
 v_previo text;
BEGIN
 IF p_pedido IS NULL OR p_version IS NULL OR p_version<0
 THEN RAISE EXCEPTION 'Pedido o versión inválidos';END IF;
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.motoristas m
  WHERE m.id=v_p.motorista_id AND m.empresa_id=v_p.empresa_id
  AND m.usuario_id=auth.uid() AND m.activo)
 THEN RAISE EXCEPTION 'Solo el motorista asignado puede deshacer su No me fui';END IF;
 IF v_p.version_edicion IS DISTINCT FROM p_version THEN
  RAISE EXCEPTION 'El pedido cambió. Actualizá la pantalla antes de deshacer';END IF;
 IF v_p.estado<>'pendiente' OR coalesce(v_p.motivo_incidencia,'') NOT ILIKE 'No me fui:%'
 THEN RAISE EXCEPTION 'El pedido ya no está en No me fui';END IF;
 SELECT fecha INTO v_fecha FROM public.rutas_generales
 WHERE id=v_p.ruta_general_id AND empresa_id=v_p.empresa_id AND estado<>'cerrada';
 IF v_fecha IS DISTINCT FROM (now() AT TIME ZONE 'America/Asuncion')::date
 THEN RAISE EXCEPTION 'Solo se puede deshacer No me fui de la ruta activa de hoy';END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c
  WHERE c.empresa_id=v_p.empresa_id AND c.motorista_id=v_p.motorista_id AND c.fecha=v_fecha)
 THEN RAISE EXCEPTION 'La caja ya se cerró: solicitá corrección a Central';END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_p.id)
 OR EXISTS(SELECT 1 FROM public.flota_rechazos_detalle r WHERE r.pedido_id=v_p.id)
 THEN RAISE EXCEPTION 'El pedido tiene registros financieros y debe revisarlo Central';END IF;
 v_previo=v_p.motivo_incidencia;
 UPDATE public.pedidos
 SET motivo_incidencia=NULL,medio_cobro=NULL,version_edicion=p_version+1,updated_at=now()
 WHERE id=p_pedido;
 INSERT INTO public.pedidos_ediciones(
  pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios
 )VALUES(v_p.id,v_p.empresa_id,v_p.tienda_id,auth.uid(),p_version,p_version+1,
  pg_catalog.jsonb_build_object('accion','deshacer_no_me_fui',
   'estado','pendiente','motivo_anterior',v_previo,'motivo_nuevo',NULL,
   'motorista_id',v_p.motorista_id,'fecha_ruta',v_fecha,
   'movimiento_financiero',false));
 RETURN pg_catalog.jsonb_build_object('pedido_id',v_p.id,'estado','pendiente',
  'no_me_fui',false,'version',p_version+1);
END;$function$
