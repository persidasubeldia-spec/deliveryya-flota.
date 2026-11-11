-- Respaldo exacto de public.tienda_cancelar_pedido_seguro, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.tienda_cancelar_pedido_seguro(p_pedido_id uuid, p_version integer)
 RETURNS pedidos
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  o public.pedidos%ROWTYPE;
  v public.pedidos%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Iniciá sesión para cancelar'; END IF;
  SELECT * INTO o FROM public.pedidos WHERE id=p_pedido_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.tienda_miembros m
    WHERE m.tienda_id=o.tienda_id AND m.usuario_id=auth.uid() AND m.activo
  ) THEN
    RAISE EXCEPTION 'No tenés permiso sobre este pedido';
  END IF;
  IF p_version IS DISTINCT FROM o.version_edicion THEN
    RAISE EXCEPTION 'Este pedido cambió. Actualizá la lista y volvé a intentar';
  END IF;
  IF o.estado <> 'pendiente' THEN RAISE EXCEPTION 'Solo se pueden cancelar pedidos pendientes'; END IF;
  IF o.motorista_id IS NOT NULL OR o.ruta_general_id IS NOT NULL OR o.numero_general IS NOT NULL THEN
    RAISE EXCEPTION 'El pedido ya está en una ruta o asignado. Pedí a la Central que lo gestione';
  END IF;
  IF EXISTS (SELECT 1 FROM public.movimientos_financieros mf WHERE mf.pedido_id=o.id) THEN
    RAISE EXCEPTION 'El pedido tiene movimientos financieros y no se puede cancelar';
  END IF;
  UPDATE public.pedidos SET estado='cancelado',version_edicion=o.version_edicion+1,updated_at=now()
  WHERE id=o.id RETURNING * INTO v;
  INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  VALUES(o.id,o.empresa_id,o.tienda_id,auth.uid(),o.version_edicion,v.version_edicion,
    jsonb_build_object('estado',jsonb_build_object('antes',o.estado,'despues','cancelado')));
  RETURN v;
END;
$function$
