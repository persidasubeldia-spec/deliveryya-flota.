-- La Central puede corregir nombre, teléfono y correo de un motorista.
-- Si el motorista todavía no vinculó su cuenta, corregir el correo alcanza:
-- el mismo enlace de invitación sigue sirviendo con el correo nuevo.
CREATE OR REPLACE FUNCTION public.flota_editar_motorista(p_motorista uuid, p_nombre text, p_telefono text, p_correo text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto public.motoristas%rowtype;v_correo text:=lower(trim(coalesce(p_correo,'')));
begin
 select * into v_moto from public.motoristas where id=p_motorista for update;
 if not found then raise exception 'Motorista no encontrado';end if;
 if not exists(select 1 from public.flota_usuarios f where f.empresa_id=v_moto.empresa_id and f.usuario_id=auth.uid() and f.activo and (f.rol='propietario' or f.puede_motoristas))
 then raise exception 'No autorizado para editar motoristas';end if;
 if length(trim(coalesce(p_nombre,'')))<3 then raise exception 'Escribí el nombre y apellido';end if;
 if length(regexp_replace(coalesce(p_telefono,''),'[^0-9]','','g'))<6 then raise exception 'Revisá el teléfono';end if;
 if v_correo !~* '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' then raise exception 'Revisá el correo electrónico';end if;
 if v_moto.usuario_id is not null and v_correo is distinct from lower(trim(coalesce(v_moto.email,'')))
 then raise exception 'Este motorista ya tiene su cuenta vinculada; el correo no se puede cambiar';end if;
 if exists(select 1 from public.motoristas m where m.empresa_id=v_moto.empresa_id and m.id<>v_moto.id and lower(trim(coalesce(m.email,'')))=v_correo)
 then raise exception 'Ese correo ya está cargado en otro motorista';end if;
 update public.motoristas set nombre=trim(p_nombre),telefono=trim(p_telefono),email=v_correo where id=v_moto.id;
end $function$;
revoke all on function public.flota_editar_motorista(uuid,text,text,text) from public, anon;
grant execute on function public.flota_editar_motorista(uuid,text,text,text) to authenticated;
