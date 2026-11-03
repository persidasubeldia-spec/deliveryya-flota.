-- La Central puede editar todos los datos de un pedido pendiente aunque ya esté asignado
-- (precios, cobro, dirección, ubicación, producto). Sigue bloqueado con cobros registrados
-- o rendición presentada, y cada cambio queda en pedidos_ediciones.
CREATE OR REPLACE FUNCTION public.editar_pedido_seguro(p_pedido_id uuid, p_version integer, p_cambios jsonb)
 RETURNS pedidos
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE o public.pedidos%ROWTYPE; v public.pedidos%ROWTYPE; f text; antes jsonb; despues jsonb; permitido text[]; admin boolean; tienda boolean; moto boolean; sensible boolean; ubica boolean;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Iniciá sesión'; END IF;
 SELECT * INTO o FROM public.pedidos WHERE id=p_pedido_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
 IF p_version IS DISTINCT FROM o.version_edicion THEN RAISE EXCEPTION 'El pedido cambió. Actualizá los datos antes de guardar'; END IF;
 IF p_cambios IS NULL OR jsonb_typeof(p_cambios)<>'object' OR p_cambios='{}'::jsonb THEN RAISE EXCEPTION 'No hay cambios'; END IF;
 SELECT EXISTS(SELECT 1 FROM public.flota_usuarios x WHERE x.empresa_id=o.empresa_id AND x.usuario_id=auth.uid() AND x.activo AND x.rol IN ('propietario','socio','operador')) INTO admin;
 SELECT EXISTS(SELECT 1 FROM public.tienda_miembros x WHERE x.tienda_id=o.tienda_id AND x.usuario_id=auth.uid() AND x.activo) INTO tienda;
 SELECT EXISTS(SELECT 1 FROM public.motoristas x WHERE x.id=o.motorista_id AND x.usuario_id=auth.uid() AND x.activo) INTO moto;
 IF NOT (admin OR tienda OR moto) THEN RAISE EXCEPTION 'No autorizado para este pedido'; END IF;
 IF o.estado <> 'pendiente' THEN RAISE EXCEPTION 'Pedido concluido o en incidencia: requiere corrección administrativa auditada'; END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros x WHERE x.pedido_id=o.id) THEN RAISE EXCEPTION 'Pedido con cobros: no se puede editar'; END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas x WHERE x.motorista_id=o.motorista_id AND x.estado IN ('presentada','confirmada','diferencia') AND x.fecha=(now() AT TIME ZONE 'America/Asuncion')::date) THEN RAISE EXCEPTION 'Rendición presentada: edición bloqueada'; END IF;
 -- La Central (propietario/socio/operador) edita todo, aunque el pedido ya esté asignado.
 permitido:=CASE WHEN admin THEN ARRAY['nombre_cliente','telefono_cliente','direccion_cliente','lat','lng','referencias','observaciones','precio_mercaderia','precio_delivery','modalidad_pago','producto'] WHEN moto THEN ARRAY['referencias','observaciones','telefono_cliente'] WHEN o.motorista_id IS NOT NULL THEN ARRAY['nombre_cliente','telefono_cliente','referencias','observaciones'] ELSE ARRAY['nombre_cliente','telefono_cliente','direccion_cliente','lat','lng','referencias','observaciones','precio_mercaderia','precio_delivery','modalidad_pago','producto'] END;
 FOR f IN SELECT jsonb_object_keys(p_cambios) LOOP
  IF NOT f=ANY(permitido) THEN RAISE EXCEPTION 'Campo no editable en este estado: %',f; END IF;
 END LOOP;
 IF p_cambios ? 'modalidad_pago' AND NOT (p_cambios->>'modalidad_pago'=ANY(ARRAY['pendiente','producto_pagado','todo_pagado'])) THEN RAISE EXCEPTION 'Modalidad inválida'; END IF;
 IF p_cambios ? 'precio_mercaderia' AND ((p_cambios->>'precio_mercaderia')::integer<0) THEN RAISE EXCEPTION 'Precio inválido'; END IF;
 IF p_cambios ? 'precio_delivery' AND ((p_cambios->>'precio_delivery')::integer<0) THEN RAISE EXCEPTION 'Envío inválido'; END IF;
 IF p_cambios ? 'producto' AND length(coalesce(p_cambios->>'producto',''))>160 THEN RAISE EXCEPTION 'Producto demasiado largo'; END IF;
 IF p_cambios ? 'lat' OR p_cambios ? 'lng' THEN
  IF (p_cambios ? 'lat') <> (p_cambios ? 'lng') THEN RAISE EXCEPTION 'Actualizá latitud y longitud juntas'; END IF;
  IF p_cambios->>'lat' IS NULL OR p_cambios->>'lng' IS NULL THEN
    IF (p_cambios->>'lat') IS DISTINCT FROM (p_cambios->>'lng') THEN RAISE EXCEPTION 'Coordenadas incompletas'; END IF;
  ELSIF (p_cambios->>'lat')::double precision NOT BETWEEN -90 AND 90 OR (p_cambios->>'lng')::double precision NOT BETWEEN -180 AND 180 THEN RAISE EXCEPTION 'Coordenadas inválidas'; END IF;
 END IF;
 antes=to_jsonb(o);
 despues=antes || p_cambios;
 SELECT * INTO v FROM jsonb_populate_record(NULL::public.pedidos,despues);
 ubica=(p_cambios ? 'lat' OR p_cambios ? 'lng' OR p_cambios ? 'direccion_cliente') AND (o.ruta_general_id IS NOT NULL);
 UPDATE public.pedidos SET
 nombre_cliente=v.nombre_cliente,telefono_cliente=v.telefono_cliente,direccion_cliente=v.direccion_cliente,lat=v.lat,lng=v.lng,
 referencias=v.referencias,observaciones=v.observaciones,precio_mercaderia=v.precio_mercaderia,precio_delivery=v.precio_delivery,modalidad_pago=v.modalidad_pago,producto=v.producto,
 version_edicion=o.version_edicion+1, requiere_revisar_ruta=o.requiere_revisar_ruta OR ubica,updated_at=now()
 WHERE id=o.id RETURNING * INTO v;
 INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 VALUES(o.id,o.empresa_id,o.tienda_id,auth.uid(),o.version_edicion,v.version_edicion,
 (SELECT jsonb_object_agg(k,jsonb_build_object('antes',antes->k,'despues',to_jsonb(v)->k)) FROM jsonb_object_keys(p_cambios) k));
 RETURN v;
END $function$;
