-- Respaldo exacto de public.flota_asignar_pedidos_rapido, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_asignar_pedidos_rapido(p_pedidos uuid[], p_motorista uuid, p_fecha date, p_turno text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_pct integer;v_total integer;v_ruta uuid;v_fila record;v_num integer;v_valid integer;
begin
 v_total=coalesce(array_length(p_pedidos,1),0);
 if v_total<1 or v_total>200 or (select count(distinct id) from unnest(p_pedidos) as id)<>v_total then raise exception 'Selección vacía o duplicada';end if;
 if p_fecha is null or p_fecha<>(now() at time zone 'America/Asuncion')::date then raise exception 'Solo se pueden asignar pedidos de hoy';end if;
 if p_turno not in ('manana','tarde','sin_definir') then raise exception 'Turno inválido';end if;
 select m.empresa_id,m.porcentaje_empresa_pct into v_empresa,v_pct from public.motoristas m where m.id=p_motorista and m.activo for update;
 if v_empresa is null or v_pct not between 0 and 100 then raise exception 'Motorista inválido';end if;
 if not exists(select 1 from public.flota_usuarios u where u.usuario_id=auth.uid() and u.empresa_id=v_empresa and u.activo and u.rol in ('propietario','socio','operador')) then raise exception 'No autorizado para asignar';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(p_fecha::text||p_turno));
 if exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=p_motorista and c.fecha=p_fecha) then raise exception 'La caja de este motorista está cerrada';end if;
 perform 1 from public.pedidos where id=any(p_pedidos) order by id for update;
 select count(*) into v_valid from public.pedidos p
 left join public.rutas_generales r on r.id=p.ruta_general_id
 where p.id=any(p_pedidos) and p.empresa_id=v_empresa and p.estado='pendiente' and p.motorista_id is null
 and p.turno=p_turno
 and coalesce(r.fecha,(p.created_at at time zone 'America/Asuncion')::date)=p_fecha
 and (r.id is null or (r.empresa_id=v_empresa and r.fecha=p_fecha and r.turno=p_turno and r.estado in('abierta','optimizada','en_reparto')));
 if v_valid<>v_total then raise exception 'Hay pedidos no disponibles, de otro turno o ya asignados. Actualizá la Central';end if;
 select r.id into v_ruta from public.rutas_generales r where r.empresa_id=v_empresa and r.fecha=p_fecha and r.turno=p_turno and r.estado in ('abierta','optimizada','en_reparto') order by r.created_at limit 1 for update;
 if v_ruta is null then insert into public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion) values(v_empresa,p_fecha,p_turno,'en_reparto',0) returning id into v_ruta;end if;
 if exists(select 1 from public.pedidos p where p.id=any(p_pedidos) and p.ruta_general_id is not null and p.ruta_general_id<>v_ruta) then
  raise exception 'Un pedido pertenece a otra ruta; revisá el turno antes de asignar';
 end if;
 select coalesce(max(p.numero_general),0) into v_num from public.pedidos p where p.ruta_general_id=v_ruta;
 for v_fila in select p.id,p.numero_general from public.pedidos p where p.id=any(p_pedidos) order by p.created_at,p.id loop
  if v_fila.numero_general is null then v_num=v_num+1;end if;
  update public.pedidos p set ruta_general_id=v_ruta,numero_general=coalesce(v_fila.numero_general,v_num),motorista_id=p_motorista,
   porcentaje_empresa_pct=v_pct,porcentaje_motorista_pct=100-v_pct,updated_at=now() where p.id=v_fila.id;
 end loop;
 update public.rutas_generales set estado='en_reparto' where id=v_ruta and estado<>'en_reparto';
 return v_total;
end $function$
