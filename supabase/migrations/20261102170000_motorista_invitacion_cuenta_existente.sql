-- Invitación de motorista con una cuenta que ya existe (socio, operador o tienda de la MISMA empresa).
-- Antes: si el correo ya tenía un perfil con otro rol ('admin', 'tienda'), la invitación fallaba con
-- "Esta cuenta ya tiene un rol incompatible" y el motorista no podía entrar nunca.
-- Ahora: el jefe invitó a ese correo exacto (verificado), así que se vincula. Solo se bloquea si la cuenta
-- trabaja activamente para OTRA empresa. El perfil existente no se modifica (la cuenta conserva su otro acceso).
-- También es idempotente: si la cuenta ya está vinculada a ese motorista, devuelve su id.
-- Reversión: supabase/rollback/20261102170000_motorista_invitacion_cuenta_existente.sql
create or replace function public.motorista_aceptar_invitacion(p_token text)
 returns uuid
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare v_inv public.motorista_invitaciones%rowtype;v_moto public.motoristas%rowtype;v_email text;
begin
if auth.uid() is null or p_token !~ '^[a-f0-9]{48}$' then raise exception 'Invitación inválida';end if;
select * into v_inv from public.motorista_invitaciones where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
if not found then raise exception 'Invitación inválida';end if;
-- Ya vinculada a esta misma cuenta: éxito (reintento o segundo dispositivo).
select * into v_moto from public.motoristas where id=v_inv.motorista_id and usuario_id=auth.uid() and activo;
if found then return v_moto.id;end if;
if v_inv.vence_en<now() or v_inv.usada_por is not null then raise exception 'Invitación vencida o utilizada';end if;
select * into v_moto from public.motoristas where id=v_inv.motorista_id and activo and usuario_id is null for update;
if not found then raise exception 'Motorista no disponible';end if;
select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
if v_email is null or v_email is distinct from lower(trim(v_moto.email)) then raise exception 'Correo no verificado o incorrecto';end if;
if exists(select 1 from public.motoristas where usuario_id=auth.uid()) then raise exception 'Cuenta ya vinculada a otro motorista';end if;
-- Solo bloquea si la cuenta está activa en OTRA empresa (tienda, equipo de flota).
if exists(select 1 from public.flota_usuarios f where f.usuario_id=auth.uid() and f.activo and f.empresa_id<>v_moto.empresa_id)
 or exists(select 1 from public.tiendas t where t.usuario_id=auth.uid() and t.activo and t.empresa_id<>v_moto.empresa_id)
 or exists(select 1 from public.tienda_miembros tm join public.tiendas t on t.id=tm.tienda_id where tm.usuario_id=auth.uid() and tm.activo and t.empresa_id<>v_moto.empresa_id)
then raise exception 'Esta cuenta pertenece a otra empresa';end if;
insert into public.perfiles(id,empresa_id,rol,nombre,telefono,activo)
values(auth.uid(),v_moto.empresa_id,'motorista',v_moto.nombre,v_moto.telefono,true)
on conflict(id) do nothing;
update public.motoristas set usuario_id=auth.uid() where id=v_moto.id;
update public.motorista_invitaciones set usada_por=auth.uid() where id=v_inv.id;
return v_moto.id;
end $function$;
