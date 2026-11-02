-- Restaura la versión anterior exacta de motorista_aceptar_invitacion.
CREATE OR REPLACE FUNCTION public.motorista_aceptar_invitacion(p_token text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_inv public.motorista_invitaciones%rowtype;v_moto public.motoristas%rowtype;v_email text;v_perfil public.perfiles%rowtype;
begin
if auth.uid() is null or p_token !~ '^[a-f0-9]{48}$' then raise exception 'Invitación inválida';end if;
select * into v_inv from public.motorista_invitaciones where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
if not found or v_inv.vence_en<now() or v_inv.usada_por is not null then raise exception 'Invitación vencida o utilizada';end if;
select * into v_moto from public.motoristas where id=v_inv.motorista_id and activo and usuario_id is null for update;
if not found then raise exception 'Motorista no disponible';end if;
select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
if v_email is null or v_email is distinct from lower(v_moto.email) then raise exception 'Correo no verificado o incorrecto';end if;
if exists(select 1 from public.motoristas where usuario_id=auth.uid()) then raise exception 'Cuenta ya vinculada a otro motorista';end if;
select * into v_perfil from public.perfiles where id=auth.uid();
if found and (v_perfil.rol<>'motorista' or v_perfil.empresa_id is distinct from v_moto.empresa_id) then raise exception 'Esta cuenta ya tiene un rol incompatible';end if;
insert into public.perfiles(id,empresa_id,rol,nombre,telefono,activo)
values(auth.uid(),v_moto.empresa_id,'motorista',v_moto.nombre,v_moto.telefono,true)
on conflict(id) do nothing;
update public.motoristas set usuario_id=auth.uid() where id=v_moto.id;
update public.motorista_invitaciones set usada_por=auth.uid() where id=v_inv.id;
return v_moto.id;
end $function$;
