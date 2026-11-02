-- La moto puede corregir lo que declara entregar mientras su rendición del día NO esté cerrada
-- ('presentada' o 'diferencia' y sin corrección del jefe). Si coincide con lo esperado queda 'confirmada'.
-- Reversión: supabase/rollback/20261102160000_motorista_corrige_rendicion.sql
create or replace function public.motorista_corregir_cierre(p_fecha date, p_efectivo integer, p_transferencia integer)
 returns text
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare v_moto public.motoristas%rowtype; c public.flota_cierres_motoristas%rowtype; v_estado text;
begin
 select * into v_moto from public.motoristas where usuario_id=auth.uid() and activo limit 1;
 if not found then raise exception 'Motorista no autorizado'; end if;
 if p_efectivo is null or p_transferencia is null or p_efectivo<0 or p_transferencia<0 then raise exception 'Importes inválidos'; end if;
 select * into c from public.flota_cierres_motoristas where motorista_id=v_moto.id and fecha=p_fecha for update;
 if not found then raise exception 'No hay rendición de ese día'; end if;
 if c.estado='confirmada' then raise exception 'La rendición ya está cerrada'; end if;
 if c.confirmado_por is not null and c.confirmado_por<>auth.uid() then raise exception 'El jefe ya revisó esta rendición: pedile a él que la corrija'; end if;
 -- El motorista solo declara; la conciliación definitiva corresponde a la Central.
 v_estado:=case when p_efectivo=c.a_rendir_esperado and p_transferencia=c.transferencia_registrada then 'presentada' else 'diferencia' end;
 update public.flota_cierres_motoristas
    set efectivo_declarado=p_efectivo, transferencia_declarada=p_transferencia,
        efectivo_recibido=p_efectivo, transferencia_confirmada=p_transferencia,
        diferencia=p_efectivo-a_rendir_esperado, diferencia_transferencia=p_transferencia-transferencia_registrada,
        estado=v_estado, confirmado_por=null, confirmed_at=null
  where id=c.id;
 return v_estado;
end $function$;
revoke all on function public.motorista_corregir_cierre(date,integer,integer) from public, anon;
grant execute on function public.motorista_corregir_cierre(date,integer,integer) to authenticated;
