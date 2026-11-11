-- Respaldo exacto de public.flota_reprogramar_asignar_historico, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_reprogramar_asignar_historico(p_pedidos uuid[], p_motorista uuid, p_fecha_origen date, p_turno_destino text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_empresa uuid;v_pct integer;v_hoy date;v_total integer;v_valid integer;
 v_destino uuid;v_n integer;v record;
begin
 v_hoy=(now() at time zone 'America/Asuncion')::date;
 v_total=coalesce(array_length(p_pedidos,1),0);
 if p_fecha_origen is null or p_fecha_origen>=v_hoy or p_turno_destino not in ('manana','tarde')
 or v_total<1 or v_total>100 or (select count(distinct x) from unnest(p_pedidos) as x)<>v_total then raise exception 'Fecha, turno o selección inválida';end if;
 select m.empresa_id,m.porcentaje_empresa_pct into v_empresa,v_pct
 from public.motoristas m where m.id=p_motorista and m.activo for update;
 if v_empresa is null then raise exception 'Motorista inexistente o inactivo';end if;
 if not exists(select 1 from public.flota_usuarios u where u.usuario_id=auth.uid() and u.empresa_id=v_empresa and u.activo and u.rol in ('propietario','socio','operador')) then raise exception 'No autorizado';end if;
 if exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=p_motorista and c.fecha=v_hoy) then raise exception 'Motorista con jornada cerrada';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(v_hoy::text||p_turno_destino));
 perform 1 from public.pedidos p where p.id=any(p_pedidos) order by p.id for update;
 select count(*) into v_valid from public.pedidos p
 left join public.rutas_generales g on g.id=p.ruta_general_id
 where p.id=any(p_pedidos) and p.empresa_id=v_empresa and p.estado='pendiente'
 and p.motorista_id is null and p.lat is not null and p.lng is not null
 and coalesce(g.fecha,(p.created_at at time zone 'America/Asuncion')::date)=p_fecha_origen
 and not exists(select 1 from public.movimientos_financieros mf where mf.pedido_id=p.id);
 if v_valid<>v_total then raise exception 'Hay pedidos ya entregados, asignados, sin GPS o con movimientos de caja. Actualizá el historial';end if;
 select g.id into v_destino from public.rutas_generales g
 where g.empresa_id=v_empresa and g.fecha=v_hoy and g.turno=p_turno_destino
 and g.estado in ('abierta','optimizada','en_reparto')
 order by g.created_at limit 1 for update;
 if v_destino is null then
  insert into public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion)
  values(v_empresa,v_hoy,p_turno_destino,'en_reparto',0) returning id into v_destino;
 end if;
 select coalesce(max(numero_general),0) into v_n from public.pedidos where ruta_general_id=v_destino;
 for v in
 select p.id,p.tienda_id,p.ruta_general_id,p.numero_general,p.turno,p.version_edicion
 from public.pedidos p where p.id=any(p_pedidos) order by p.created_at,p.id
 loop
  v_n=v_n+1;
  update public.pedidos p set ruta_general_id=v_destino,numero_general=v_n,
  turno=p_turno_destino,motorista_id=p_motorista,
  porcentaje_empresa_pct=v_pct,porcentaje_motorista_pct=100-v_pct,
  requiere_revisar_ruta=false,version_edicion=coalesce(p.version_edicion,0)+1,updated_at=now()
  where p.id=v.id;
  insert into public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  values (v.id,v_empresa,v.tienda_id,auth.uid(),coalesce(v.version_edicion,0),coalesce(v.version_edicion,0)+1,
   jsonb_build_object('accion','reprogramado_desde_historico',
   'fecha_origen',p_fecha_origen,'fecha_destino',v_hoy,
   'ruta_general_id',jsonb_build_object('antes',v.ruta_general_id,'despues',v_destino),
   'numero_general',jsonb_build_object('antes',v.numero_general,'despues',v_n),
   'turno',jsonb_build_object('antes',v.turno,'despues',p_turno_destino),
   'motorista_nuevo',p_motorista));
 end loop;
 update public.rutas_generales set estado='en_reparto' where id=v_destino and estado<>'en_reparto';
 return v_total;
end $function$
