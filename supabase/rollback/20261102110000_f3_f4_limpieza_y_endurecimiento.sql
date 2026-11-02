-- Reversión de 20261102110000: recrea las funciones eliminadas (definición exacta de producción 2026-11-02) y restaura permisos.
CREATE OR REPLACE FUNCTION public.admin_asignar_pedido_motorista(p_pedido_id uuid, p_motorista_id uuid, p_numero_general integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_estado text;v_asignado uuid;
begin
 select empresa_id,estado,motorista_id into v_empresa,v_estado,v_asignado from public.pedidos where id=p_pedido_id for update;
 if v_empresa is null or not exists(select 1 from public.flota_usuarios where empresa_id=v_empresa and usuario_id=auth.uid() and activo and rol in('propietario','socio','operador')) then raise exception 'No autorizado';end if;
 if v_estado not in('pendiente','no_responde','pasa_manana') or v_asignado is not null then raise exception 'Pedido no disponible para asignar';end if;
 if p_numero_general is null or p_numero_general<1 then raise exception 'Numero invalido';end if;
 if not exists(select 1 from public.motoristas where id=p_motorista_id and empresa_id=v_empresa and activo) then raise exception 'Motorista no autorizado';end if;
 update public.pedidos set motorista_id=p_motorista_id,numero_general=p_numero_general,updated_at=now() where id=p_pedido_id;
end $function$
;
CREATE OR REPLACE FUNCTION public.cerrar_caja_motorista(p_empresa_id uuid, p_motorista_id uuid, p_efectivo integer, p_transferencia integer, p_comision integer, p_a_rendir integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 raise exception 'Cierre no habilitado: requiere conciliacion financiera verificable';
end $function$
;
CREATE OR REPLACE FUNCTION public.flota_crear_ruta(p_fecha date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_id uuid;
begin
select empresa_id into v_empresa from public.flota_usuarios where usuario_id=auth.uid() and activo and rol in ('propietario','socio','operador') order by created_at limit 1;
if v_empresa is null then raise exception 'No autorizado';end if;
if p_fecha is null then raise exception 'Fecha requerida';end if;
select id into v_id from public.rutas_generales where empresa_id=v_empresa and fecha=p_fecha and estado in ('abierta','optimizada') order by created_at limit 1 for update;
if v_id is null then
insert into public.rutas_generales(empresa_id,fecha,estado,version_optimizacion) values(v_empresa,p_fecha,'abierta',0) returning id into v_id;
end if;
return v_id;
end $function$
;
CREATE OR REPLACE FUNCTION public.tienda_agregar_pedido_a_ruta(p_pedido uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.pedidos%rowtype; r uuid; day date:=(now() at time zone 'America/Asuncion')::date;
begin
 if auth.uid() is null then raise exception 'Iniciá sesión';end if;
 select * into v from public.pedidos where id=p_pedido for update;
 if not found then raise exception 'Pedido inexistente';end if;
 if not exists(select 1 from public.tienda_miembros m join public.tiendas t on t.id=m.tienda_id where m.tienda_id=v.tienda_id and m.usuario_id=auth.uid() and m.activo and t.activo and t.empresa_id=v.empresa_id) then raise exception 'No autorizado para esta tienda';end if;
 if v.estado<>'pendiente' or v.motorista_id is not null then raise exception 'Pedido asignado o procesado: no puede agregarse';end if;
 if v.lat is null or v.lng is null or v.lat not between -28 and -19 or v.lng not between -63 and -54 then raise exception 'Primero corregí la ubicación GPS del pedido';end if;
 if exists(select 1 from public.movimientos_financieros m where m.pedido_id=v.id) then raise exception 'Pedido con cobros bloqueado';end if;
 if v.ruta_general_id is not null then
  select id into r from public.rutas_generales where id=v.ruta_general_id;
  if r is not null then return r;end if;
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v.empresa_id::text),17524);
 select id into r from public.rutas_generales where empresa_id=v.empresa_id and fecha=day and estado='abierta' order by created_at limit 1;
 if r is null then
  insert into public.rutas_generales(empresa_id,fecha,estado,version_optimizacion) values(v.empresa_id,day,'abierta',0) returning id into r;
 end if;
 update public.pedidos set ruta_general_id=r,numero_general=null,updated_at=now() where id=v.id;
 return r;
end $function$
;
CREATE OR REPLACE FUNCTION public.flota_confirmar_cierre(p_cierre uuid, p_efectivo_recibido integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_transfer integer;
begin
select transferencia_registrada into v_transfer from public.flota_cierres_motoristas where id=p_cierre;
if v_transfer is null then raise exception 'Rendición inexistente';end if;
if v_transfer<>0 then raise exception 'Rendición con transferencias: verificar con la confirmación completa';end if;
return public.flota_confirmar_cierre_completo(p_cierre,p_efectivo_recibido,0);
end $function$
;
revoke all on function public.admin_asignar_pedido_motorista(uuid,uuid,integer) from public, anon; grant execute on function public.admin_asignar_pedido_motorista(uuid,uuid,integer) to authenticated;
revoke all on function public.cerrar_caja_motorista(uuid,uuid,integer,integer,integer,integer) from public, anon; grant execute on function public.cerrar_caja_motorista(uuid,uuid,integer,integer,integer,integer) to authenticated;
revoke all on function public.flota_crear_ruta(date) from public, anon; grant execute on function public.flota_crear_ruta(date) to authenticated;
revoke all on function public.tienda_agregar_pedido_a_ruta(uuid) from public, anon, authenticated;
revoke all on function public.flota_confirmar_cierre(uuid,integer) from public, anon; grant execute on function public.flota_confirmar_cierre(uuid,integer) to authenticated;
grant select, insert, update, delete on all tables in schema public to anon;
revoke all on public.flota_solicitudes_tienda from anon;
revoke all on public.pedidos_ediciones from anon;
grant execute on function public.deliveryya_asignar_codigo_tienda() to anon, authenticated;
grant execute on function public.deliveryya_fijar_autor_pedido() to anon, authenticated;
