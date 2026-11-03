-- Vuelve a la versión anterior (sin el control de Central/Motorista).
CREATE OR REPLACE FUNCTION public.flota_solicitar_alta_tienda_simple()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_email text;v_empresa uuid:='a0000000-0000-0000-0000-000000000001';v_codigo text;v_next integer;v_tienda uuid;v_perfil public.perfiles%rowtype;
begin
 if auth.uid() is null then raise exception 'Iniciá sesión con tu correo y contraseña';end if;
 select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
 if v_email is null then raise exception 'Confirmá tu correo electrónico para activar tu tienda';end if;
 select t.id,t.codigo into v_tienda,v_codigo from public.tiendas t
 where t.usuario_id=auth.uid() and t.empresa_id=v_empresa and t.activo limit 1;
 if found then return v_codigo;end if;
 select * into v_perfil from public.perfiles where id=auth.uid();
 if found and (v_perfil.rol<>'tienda' or v_perfil.empresa_id is distinct from v_empresa)
 then raise exception 'Esta cuenta pertenece a otro rol. Ingresá por el acceso correspondiente';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),17291);
 insert into public.perfiles(id,empresa_id,rol,nombre,telefono,activo)
 values(auth.uid(),v_empresa,'tienda',split_part(v_email,'@',1),'',true)
 on conflict(id) do update set activo=true;
 select coalesce(max(substring(t.codigo from 2)::integer),0)+1 into v_next
 from public.tiendas t where t.empresa_id=v_empresa and t.codigo ~ '^T[0-9]{1,7}$';
 v_codigo='T'||v_next;
 insert into public.tiendas(empresa_id,codigo,usuario_id,nombre_comercial,responsable,telefono,email,direccion,activo)
 values(v_empresa,v_codigo,auth.uid(),'Tienda '||v_codigo,split_part(v_email,'@',1),'Pendiente de completar',v_email,'Pendiente de completar',true)
 returning id into v_tienda;
 insert into public.tienda_miembros(tienda_id,usuario_id,rol,activo)
 values(v_tienda,auth.uid(),'propietario',true)
 on conflict(tienda_id,usuario_id) do update set activo=true;
 update public.flota_solicitudes_tienda set estado='aprobada',tienda_id=v_tienda,revisada_en=now()
 where empresa_id=v_empresa and usuario_id=auth.uid() and estado='pendiente';
 return v_codigo;
end $function$;
