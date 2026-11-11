-- Confirma recepción REAL de dinero en el cierre existente, sin crear caja paralela.
-- Pensada para cierres autodeclarados 'confirmada' por motorista_presentar_cierre:
-- dicho estado/confirmed_at por sí solo NO acredita recepción por Central.
-- No modifica comisiones ni movimientos originales. Ejecutar solo tras pruebas y aprobación.
CREATE OR REPLACE FUNCTION public.flota_confirmar_recepcion_caja(
  p_cierre uuid,p_efectivo_recibido integer,p_transferencia_confirmada integer
) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE
 v public.flota_cierres_motoristas%rowtype;
 v_es_central boolean;
BEGIN
 IF p_cierre IS NULL OR p_efectivo_recibido IS NULL OR p_transferencia_confirmada IS NULL
   OR p_efectivo_recibido<0 OR p_transferencia_confirmada<0
 THEN RAISE EXCEPTION 'Indicá importes válidos de efectivo y transferencia recibidos'; END IF;
 SELECT * INTO v FROM public.flota_cierres_motoristas WHERE id=p_cierre FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'No existe esa rendición'; END IF;
 IF NOT EXISTS (
   SELECT 1 FROM public.flota_usuarios u
   WHERE u.usuario_id=auth.uid() AND u.empresa_id=v.empresa_id
     AND u.activo AND (u.rol='propietario' OR u.puede_confirmar_rendiciones)
 ) THEN RAISE EXCEPTION 'Solo Central autorizada puede confirmar dinero recibido'; END IF;
 IF v.estado NOT IN ('presentada','diferencia','confirmada')
 THEN RAISE EXCEPTION 'El cierre no está disponible para confirmar'; END IF;
 SELECT EXISTS (
  SELECT 1 FROM public.flota_usuarios u
   WHERE u.usuario_id=v.confirmado_por AND u.empresa_id=v.empresa_id
     AND (u.rol='propietario' OR u.puede_confirmar_rendiciones)
 ) INTO v_es_central;
 IF v_es_central AND v.confirmed_at IS NOT NULL THEN
   IF v.efectivo_recibido=p_efectivo_recibido AND v.transferencia_confirmada=p_transferencia_confirmada THEN
     RETURN true; -- Reintento idéntico: idempotente.
   END IF;
   RAISE EXCEPTION 'Caja ya recibida por Central. Para modificarla, usá una corrección auditada.';
 END IF;
 UPDATE public.flota_cierres_motoristas SET
   efectivo_recibido=p_efectivo_recibido,
   transferencia_confirmada=p_transferencia_confirmada,
   diferencia=p_efectivo_recibido-v.a_rendir_esperado,
   diferencia_transferencia=p_transferencia_confirmada-v.transferencia_registrada,
   estado=CASE WHEN p_efectivo_recibido=v.a_rendir_esperado AND p_transferencia_confirmada=v.transferencia_registrada THEN 'confirmada' ELSE 'diferencia' END,
   confirmado_por=auth.uid(),
   confirmed_at=now()
 WHERE id=v.id;
 RETURN true;
END;$function$;

REVOKE ALL ON FUNCTION public.flota_confirmar_recepcion_caja(uuid,integer,integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.flota_confirmar_recepcion_caja(uuid,integer,integer) TO authenticated;
