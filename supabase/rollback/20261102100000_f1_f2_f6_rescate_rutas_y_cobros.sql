-- Reversión de 20261102100000: restaura las definiciones previas exactas (tomadas de producción 2026-11-02)
-- y elimina la función nueva. No modifica datos.
drop function if exists public.flota_anexar_pedidos_a_ruta(uuid, uuid[]);
CREATE OR REPLACE FUNCTION public.flota_reorganizar_pendientes_heredados(p_fecha date, p_turno text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_destino uuid;v_total integer;v_legacy uuid;
begin
 if p_turno not in('manana','tarde','sin_definir') or p_fecha is null then raise exception 'Fecha y turno inválidos';end if;
 select empresa_id into v_empresa from public.flota_usuarios where usuario_id=auth.uid() and activo and rol in('propietario','socio','operador') order by created_at limit 1;
 if v_empresa is null then raise exception 'No autorizado';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(p_fecha::text||p_turno));
 select id into v_destino from public.rutas_generales where empresa_id=v_empresa and fecha=p_fecha and turno=p_turno and estado='abierta' order by created_at limit 1 for update;
 if v_destino is null then raise exception 'Primero creá una ruta abierta para el turno';end if;
 -- Only move unassigned/unprocessed/unnumbered orders from legacy untyped OPEN routes.
 perform 1 from public.pedidos p join public.rutas_generales r on r.id=p.ruta_general_id
 where r.empresa_id=v_empresa and r.fecha=p_fecha and r.turno is null and r.estado='abierta'
 and p.empresa_id=v_empresa and p.estado='pendiente' and p.motorista_id is null and p.numero_general is null
 and coalesce(p.turno,'sin_definir')=p_turno order by p.id for update of p;
 update public.pedidos p set ruta_general_id=v_destino,updated_at=now()
 from public.rutas_generales r
 where r.id=p.ruta_general_id and r.empresa_id=v_empresa and r.fecha=p_fecha and r.turno is null and r.estado='abierta'
 and p.empresa_id=v_empresa and p.estado='pendiente' and p.motorista_id is null and p.numero_general is null
 and coalesce(p.turno,'sin_definir')=p_turno
 and not exists(select 1 from public.movimientos_financieros mf where mf.pedido_id=p.id);
 get diagnostics v_total=row_count;
 return v_total;
end $function$
;
CREATE OR REPLACE FUNCTION public.motorista_actualizar_estado_pedido(p_pedido_id uuid, p_motorista_id uuid, p_nuevo_estado text, p_medio_cobro text, p_motivo_incidencia text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_estado text;v_moto uuid;
begin
select empresa_id,estado,motorista_id into v_empresa,v_estado,v_moto from public.pedidos where id=p_pedido_id for update;
if v_empresa is null or v_moto is distinct from p_motorista_id then raise exception 'Pedido no asignado';end if;
if not exists(select 1 from public.motoristas m where m.id=p_motorista_id and m.usuario_id=auth.uid() and m.empresa_id=v_empresa and m.activo)
and not exists(select 1 from public.flota_usuarios f where f.empresa_id=v_empresa and f.usuario_id=auth.uid() and f.activo and f.rol in('propietario','socio')) then raise exception 'No autorizado';end if;
if v_estado in('entregado','rechazado','cancelado') then raise exception 'Pedido cerrado';end if;
if p_nuevo_estado not in('entregado','rechazado','no_recibio','no_responde','pasa_manana') then raise exception 'Estado invalido';end if;
if p_nuevo_estado='entregado' and p_medio_cobro not in('efectivo','transferencia','pagado_previo') then raise exception 'Medio de cobro obligatorio';end if;
if p_nuevo_estado<>'entregado' and (p_motivo_incidencia is null or length(trim(p_motivo_incidencia))<3) then raise exception 'Motivo obligatorio';end if;
update public.pedidos set estado=p_nuevo_estado,medio_cobro=case when p_nuevo_estado='entregado' then p_medio_cobro else null end,motivo_incidencia=p_motivo_incidencia,updated_at=now() where id=p_pedido_id;
end $function$
;
CREATE OR REPLACE FUNCTION public.tienda_agregar_pedido_a_ruta(p_pedido uuid, p_turno text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.pedidos%rowtype;r uuid;day date:=(now() at time zone 'America/Asuncion')::date;
begin
 if p_turno is null or p_turno not in('manana','tarde') then raise exception 'Seleccioná Mañana o Tarde';end if;
 if auth.uid() is null then raise exception 'Iniciá sesión';end if;
 select * into v from public.pedidos where id=p_pedido for update;
 if not found then raise exception 'Pedido inexistente';end if;
 if not exists(select 1 from public.tienda_miembros m join public.tiendas t on t.id=m.tienda_id where m.tienda_id=v.tienda_id and m.usuario_id=auth.uid() and m.activo and t.activo and t.empresa_id=v.empresa_id) then raise exception 'No autorizado';end if;
 if v.estado<>'pendiente' or v.motorista_id is not null then raise exception 'Pedido ya asignado o procesado';end if;
 if v.lat is null or v.lng is null or v.lat not between -28 and -19 or v.lng not between -63 and -54 then raise exception 'GPS inválido';end if;
 if exists(select 1 from public.movimientos_financieros m where m.pedido_id=v.id) then raise exception 'Pedido con cobros: no puede cambiarse';end if;
 if v.ruta_general_id is not null then
  select id into r from public.rutas_generales where id=v.ruta_general_id and empresa_id=v.empresa_id and estado='abierta' and turno=p_turno;
  if r is not null and v.turno=p_turno then return r;end if;
  if exists(select 1 from public.rutas_generales where id=v.ruta_general_id and estado<>'abierta') then raise exception 'Ruta confirmada: solicitá reorganización a Central';end if;
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v.empresa_id::text),pg_catalog.hashtext(day::text||p_turno));
 select id into r from public.rutas_generales where empresa_id=v.empresa_id and fecha=day and turno=p_turno and estado='abierta' limit 1;
 if r is null then insert into public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion) values(v.empresa_id,day,p_turno,'abierta',0) returning id into r;end if;
 update public.pedidos set ruta_general_id=r,turno=p_turno,numero_general=null,version_edicion=coalesce(version_edicion,0)+1,updated_at=now() where id=v.id;
 return r;
end $function$
;
