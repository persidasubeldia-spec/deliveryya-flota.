-- Respaldo exacto de public.motorista_guardar_recorrido, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.motorista_guardar_recorrido(p_pedidos uuid[], p_coordenadas jsonb, p_origen_lat double precision, p_origen_lng double precision)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto uuid;v_empresa uuid;v_fecha date;v_total int;v_geocodificados int;v_version bigint;v_punto jsonb;v_cantidad int;
begin
 select m.id,m.empresa_id into v_moto,v_empresa from public.motoristas m where m.usuario_id=(select auth.uid()) and m.activo order by m.created_at limit 1;
 if v_moto is null then raise exception 'Motorista no autorizado';end if;
 v_fecha=(now() at time zone 'America/Asuncion')::date;
 v_total=coalesce(array_length(p_pedidos,1),0);
 if v_total<2 or v_total>26 or (select count(distinct x.id) from unnest(p_pedidos) as x(id))<>v_total then raise exception 'Orden incompleto o duplicado';end if;
 if p_origen_lat is null or p_origen_lng is null or not(p_origen_lat between -29 and -18 and p_origen_lng between -64 and -53) then raise exception 'Origen GPS inválido';end if;
 if p_coordenadas is null or jsonb_typeof(p_coordenadas)<>'array' or pg_catalog.octet_length(p_coordenadas::text)>1800000 then raise exception 'Geometría vial ausente, inválida o demasiado extensa';end if;
 v_cantidad=jsonb_array_length(p_coordenadas);
 if v_cantidad<2 or v_cantidad>50000 then raise exception 'Geometría vial incompleta';end if;
 if exists(select 1 from jsonb_array_elements(p_coordenadas) as t(j) where jsonb_typeof(t.j)<>'array' or jsonb_array_length(t.j)<>2 or jsonb_typeof(t.j->0)<>'number' or jsonb_typeof(t.j->1)<>'number') then
  raise exception 'Las coordenadas de la geometría no son válidas';
 end if;
 if exists(select 1 from jsonb_array_elements(p_coordenadas) as t(j) where (t.j->>0)::double precision not between -64 and -53 or (t.j->>1)::double precision not between -29 and -18) then
  raise exception 'La geometría contiene puntos fuera del área permitida';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_moto::text),pg_catalog.hashtext(v_fecha::text));
 perform 1 from public.pedidos p where p.id=any(p_pedidos) order by p.id for update;
 select count(*) into v_geocodificados from public.pedidos p
  join public.rutas_generales r on r.id=p.ruta_general_id
  where p.motorista_id=v_moto and p.empresa_id=v_empresa and r.fecha=v_fecha
  and p.estado in('pendiente','no_responde','pasa_manana','no_recibio')
  and p.lat is not null and p.lng is not null;
 if v_geocodificados<>v_total then raise exception 'Hay pedidos nuevos, faltantes o estados diferentes. Actualizá tu ruta';end if;
 if (select count(*) from public.pedidos p join public.rutas_generales r on r.id=p.ruta_general_id where p.id=any(p_pedidos)
 and p.motorista_id=v_moto and p.empresa_id=v_empresa and r.fecha=v_fecha
 and p.estado in('pendiente','no_responde','pasa_manana','no_recibio') and p.lat is not null and p.lng is not null)<>v_total then
  raise exception 'Tu selección contiene pedidos que ya no están disponibles';
 end if;
 -- La transacción completa asegura que orden y geometría sean siempre la misma versión.
 delete from public.motorista_ordenes_pedidos where motorista_id=v_moto and fecha=v_fecha;
 insert into public.motorista_ordenes_pedidos(motorista_id,fecha,pedido_id,posicion)
  select v_moto,v_fecha,x.id,x.posicion::integer from unnest(p_pedidos) with ordinality as x(id,posicion);
 insert into public.motorista_recorridos_confirmados(motorista_id,empresa_id,fecha,version,pedido_ids,coordenadas,origen_lat,origen_lng,confirmado_en)
 values(v_moto,v_empresa,v_fecha,1,p_pedidos,p_coordenadas,p_origen_lat,p_origen_lng,now())
 on conflict(motorista_id,fecha) do update set
   version=public.motorista_recorridos_confirmados.version+1,
   pedido_ids=excluded.pedido_ids,coordenadas=excluded.coordenadas,
   origen_lat=excluded.origen_lat,origen_lng=excluded.origen_lng,confirmado_en=now()
 returning version into v_version;
 return v_version;
end $function$
