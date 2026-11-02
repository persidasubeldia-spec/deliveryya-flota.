-- Reversión de 20261102140000: vuelve al cierre 'presentada' con confirmación del jefe.
drop function if exists public.motorista_contacto_jefe();
CREATE OR REPLACE FUNCTION public.motorista_presentar_cierre(p_fecha date, p_efectivo integer, p_transferencia integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto public.motoristas%rowtype;v_cash integer;v_transfer integer;v_comm integer;v_emp integer;v_del_comm integer;v_render integer;v_id uuid;
begin
select * into v_moto from public.motoristas where usuario_id=auth.uid() and activo limit 1;
if not found then raise exception 'Motorista no autorizado';end if;
if p_fecha is null or p_fecha> (now() at time zone 'America/Asuncion')::date or p_efectivo<0 or p_transferencia<0 then raise exception 'Importes o fecha inválidos';end if;
perform pg_advisory_xact_lock(hashtext(v_moto.id::text||p_fecha::text));
if exists(select 1 from public.flota_cierres_motoristas where motorista_id=v_moto.id and fecha=p_fecha) then raise exception 'Ya existe cierre del día';end if;
select coalesce(sum(m.efectivo_cobrado),0),coalesce(sum(m.transferencia_cobrada),0),coalesce(sum(m.comision_motorista),0),coalesce(sum(m.comision_empresa),0),coalesce(sum(case when p.estado='entregado' then m.comision_motorista else 0 end))
into v_cash,v_transfer,v_comm,v_emp,v_del_comm
from public.movimientos_financieros m join public.pedidos p on p.id=m.pedido_id
where m.motorista_id=v_moto.id and (m.created_at at time zone 'America/Asuncion')::date=p_fecha;
if v_moto.modalidad_liquidacion='retener_comision' then v_render=greatest(0,v_cash-least(v_cash,v_del_comm));else v_render=v_cash;end if;
insert into public.flota_cierres_motoristas(empresa_id,motorista_id,fecha,efectivo_esperado,transferencia_registrada,comision_motorista,comision_empresa,a_rendir_esperado,efectivo_declarado,transferencia_declarada,presentado_por)
values(v_moto.empresa_id,v_moto.id,p_fecha,v_cash,v_transfer,v_comm,v_emp,v_render,p_efectivo,p_transferencia,auth.uid()) returning id into v_id;
return v_id;
end $function$
;
CREATE OR REPLACE FUNCTION public.flota_confirmar_cierre_completo(p_cierre uuid, p_efectivo_recibido integer, p_transferencia_confirmada integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.flota_cierres_motoristas%rowtype;
begin
select * into v from public.flota_cierres_motoristas where id=p_cierre for update;
if not found or v.estado<>'presentada' then raise exception 'Rendición no disponible para confirmar';end if;
if not exists(select 1 from public.flota_usuarios f where f.empresa_id=v.empresa_id and f.usuario_id=auth.uid() and f.activo and (f.rol='propietario' or f.puede_confirmar_rendiciones)) then raise exception 'Sin permiso financiero';end if;
if p_efectivo_recibido is null or p_transferencia_confirmada is null or p_efectivo_recibido<0 or p_transferencia_confirmada<0 then raise exception 'Importes inválidos';end if;
update public.flota_cierres_motoristas
set efectivo_recibido=p_efectivo_recibido,
transferencia_confirmada=p_transferencia_confirmada,
diferencia=p_efectivo_recibido-a_rendir_esperado,
diferencia_transferencia=p_transferencia_confirmada-transferencia_registrada,
estado=case when p_efectivo_recibido=a_rendir_esperado and p_transferencia_confirmada=transferencia_registrada then 'confirmada' else 'diferencia' end,
confirmado_por=auth.uid(),confirmed_at=now()
where id=p_cierre;
return true;
end $function$
;
