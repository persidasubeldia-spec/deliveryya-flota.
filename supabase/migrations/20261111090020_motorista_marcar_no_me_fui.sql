-- Respaldo exacto de public.motorista_marcar_no_me_fui, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.motorista_marcar_no_me_fui(p_pedido uuid, p_version integer, p_motivo text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_p public.pedidos%rowtype;
 v_fecha date;
 v_motivo text;
BEGIN
 v_motivo=btrim(coalesce(p_motivo,''));
 IF char_length(v_motivo)<3 OR char_length(v_motivo)>180 THEN RAISE EXCEPTION 'Indicá un motivo de 3 a 180 caracteres'; END IF;
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
 IF NOT EXISTS(
  SELECT 1 FROM public.motoristas m WHERE m.id=v_p.motorista_id AND m.empresa_id=v_p.empresa_id AND m.activo AND m.usuario_id=auth.uid()
 ) AND NOT EXISTS(
  SELECT 1 FROM public.flota_usuarios u WHERE u.empresa_id=v_p.empresa_id AND u.activo AND u.usuario_id=auth.uid() AND u.rol IN ('propietario','socio')
 ) THEN RAISE EXCEPTION 'No estás autorizado para este pedido'; END IF;
 IF v_p.estado<>'pendiente' THEN RAISE EXCEPTION 'El pedido ya tiene otro estado. No se modificó'; END IF;
 IF coalesce(v_p.version_edicion,0) IS DISTINCT FROM p_version THEN RAISE EXCEPTION 'El pedido cambió: actualizá la pantalla';END IF;
 SELECT r.fecha INTO v_fecha FROM public.rutas_generales r
 WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_p.empresa_id AND r.estado<>'cerrada';
 IF v_fecha IS NULL OR v_fecha<>(now() AT TIME ZONE 'America/Asuncion')::date THEN
  RAISE EXCEPTION 'Solo se permite marcar No me fui en la jornada abierta de hoy';
 END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c WHERE c.empresa_id=v_p.empresa_id AND c.motorista_id=v_p.motorista_id AND c.fecha=v_fecha)
 THEN RAISE EXCEPTION 'La caja ya fue presentada o cerrada'; END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_p.id)
 THEN RAISE EXCEPTION 'El pedido tiene un movimiento financiero y requiere revisión en Central'; END IF;
 IF coalesce(v_p.motivo_incidencia,'') LIKE 'No me fui:%' THEN
  RAISE EXCEPTION 'Este pedido ya está marcado No me fui';
 END IF;
 UPDATE public.pedidos SET motivo_incidencia='No me fui: '||v_motivo,
  medio_cobro=NULL,version_edicion=p_version+1,updated_at=now()
 WHERE id=p_pedido;
 INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 VALUES(v_p.id,v_p.empresa_id,v_p.tienda_id,auth.uid(),p_version,p_version+1,
 jsonb_build_object('accion','no_me_fui_sin_cobro','motivo',v_motivo,
 'estado','pendiente','importe_cobrado',0,'comision_motorista',0,'comision_empresa',0,
 'fecha_ruta',v_fecha,'motorista_id',v_p.motorista_id));
 RETURN jsonb_build_object('pedido_id',p_pedido,'estado','pendiente','no_me_fui',true,'movimiento_financiero',false,'version',p_version+1);
END;
$function$
