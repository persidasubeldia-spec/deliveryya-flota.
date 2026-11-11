-- Respaldo exacto de public.motorista_corregir_pedido, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.motorista_corregir_pedido(p_pedido uuid, p_version integer, p_cambios jsonb, p_deshacer boolean DEFAULT false)
 RETURNS pedidos
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.pedidos%rowtype;v_n public.pedidos%rowtype;
v_fecha date;v_hoy date:=(now() at time zone 'America/Asuncion')::date;
v_mov public.movimientos_financieros%rowtype;v_rech jsonb;v_antes jsonb;v_despues jsonb;
v_campo text;v_permitidos text[]:=array['nombre_cliente','telefono_cliente','referencias','observaciones','producto','precio_mercaderia','precio_delivery','modalidad_pago'];
v_precio int;v_envio int;v_modal text;v_ubicacion boolean;
begin
 if auth.uid() is null then raise exception 'Iniciá sesión';end if;
 select * into v from public.pedidos where id=p_pedido for update;
 if not found then raise exception 'Pedido inexistente';end if;
 if not exists(select 1 from public.motoristas m where m.id=v.motorista_id and m.usuario_id=auth.uid() and m.activo) then raise exception 'Este pedido no está asignado a tu cuenta';end if;
 if p_version is distinct from v.version_edicion then raise exception 'El pedido fue modificado. Actualizá antes de guardar';end if;
 select coalesce(r.fecha,(v.created_at at time zone 'America/Asuncion')::date) into v_fecha from (select 1) z left join public.rutas_generales r on r.id=v.ruta_general_id;
 if v_fecha<>v_hoy then raise exception 'Solo se puede corregir un pedido de la jornada actual';end if;
 if exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=v.motorista_id and c.fecha=v_fecha) then raise exception 'Jornada cerrada o presentada. Solicitá corrección administrativa';end if;
 if p_cambios is null or jsonb_typeof(p_cambios)<>'object' then raise exception 'Datos incorrectos';end if;
 for v_campo in select jsonb_object_keys(p_cambios) loop
  if not(v_campo=any(v_permitidos)) then raise exception 'Campo no autorizado: %',v_campo;end if;
 end loop;
 if p_cambios='{}'::jsonb and not p_deshacer then raise exception 'No hay cambios';end if;
 if p_deshacer then
   if v.estado not in ('entregado','rechazado') then raise exception 'Solo se puede deshacer entregado o rechazado';end if;
 else
   if v.estado not in ('pendiente','no_responde','no_recibio','pasa_manana') then
     raise exception 'Primero deshacé el estado para poder editar este pedido';
   end if;
 end if;
 select * into v_mov from public.movimientos_financieros where pedido_id=v.id for update;
 if found then
  if not p_deshacer then raise exception 'El pedido tiene un cobro; primero deshacé el estado';end if;
  if v_mov.liquidado then raise exception 'Cobro liquidado; requiere ajuste administrativo';end if;
  select to_jsonb(d) into v_rech from public.flota_rechazos_detalle d where d.pedido_id=v.id;
 elsif p_deshacer then raise exception 'El pedido no tiene movimiento financiero registrado; solicitá revisión de Central';end if;
 v_antes=to_jsonb(v);
 v_despues=v_antes||p_cambios;
 select * into v_n from jsonb_populate_record(null::public.pedidos,v_despues);
 if v_n.precio_mercaderia is null or v_n.precio_mercaderia<0 or v_n.precio_mercaderia>100000000 then raise exception 'Precio de mercadería inválido';end if;
 if v_n.precio_delivery is null or v_n.precio_delivery<0 or v_n.precio_delivery>10000000 then raise exception 'Costo de envío inválido';end if;
 if v_n.modalidad_pago not in ('pendiente','producto_pagado','todo_pagado') then raise exception 'Modalidad de pago inválida';end if;
 if length(coalesce(v_n.nombre_cliente,''))>200 or length(coalesce(v_n.producto,''))>160 or length(coalesce(v_n.telefono_cliente,''))>40
 or length(coalesce(v_n.observaciones,''))>2000 or length(coalesce(v_n.referencias,''))>2000 then raise exception 'Texto demasiado largo';end if;
 -- La auditoría guarda importes anteriores y una copia de los movimientos retirados.
 if p_deshacer then
   delete from public.flota_rechazos_detalle where pedido_id=v.id;
   delete from public.movimientos_financieros where pedido_id=v.id and liquidado=false;
 end if;
 update public.pedidos p set
 nombre_cliente=v_n.nombre_cliente,telefono_cliente=v_n.telefono_cliente,producto=v_n.producto,
 referencias=v_n.referencias,observaciones=v_n.observaciones,
 precio_mercaderia=v_n.precio_mercaderia,precio_delivery=v_n.precio_delivery,modalidad_pago=v_n.modalidad_pago,
 estado=case when p_deshacer then 'pendiente' else v.estado end,
 medio_cobro=case when p_deshacer then null else v.medio_cobro end,
 motivo_incidencia=case when p_deshacer then null else v.motivo_incidencia end,
 version_edicion=coalesce(v.version_edicion,0)+1,updated_at=now()
 where p.id=v.id returning * into v_n;
 insert into public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 values(v.id,v.empresa_id,v.tienda_id,auth.uid(),coalesce(v.version_edicion,0),v_n.version_edicion,
  jsonb_build_object('accion',case when p_deshacer then 'motorista_deshacer_estado' else 'motorista_editar_pedido' end,
   'estado_anterior',v.estado,'estado_nuevo',v_n.estado,'movimiento_anterior',case when p_deshacer then to_jsonb(v_mov) else null end,
   'detalle_rechazo_anterior',v_rech,
   'campos',(select coalesce(jsonb_object_agg(k,jsonb_build_object('antes',v_antes->k,'despues',to_jsonb(v_n)->k)),'{}'::jsonb) from jsonb_object_keys(p_cambios) k)
  ));
 return v_n;
end $function$
