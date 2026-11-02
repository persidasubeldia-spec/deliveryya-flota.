-- F1: rescatar pedidos pendientes atrapados en rutas viejas (sin turno o de días anteriores)
-- F2: la función de incidencias ya no permite marcar Entregado/Rechazado (evita cobros sin validar)
-- F6: pedido que llega con la ruta del turno ya confirmada queda "para revisión" (sin error técnico)
--     y Central puede sumarlo al final de la ruta sin renumerar lo ya repartido.
-- Reversión: supabase/rollback/20261102100000_f1_f2_f6_rescate_rutas_y_cobros.sql

-- ---------- F1 ----------
create or replace function public.flota_reorganizar_pendientes_heredados(p_fecha date, p_turno text)
 returns integer
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare v_empresa uuid; v_destino uuid; v_dest_estado text; v_total integer := 0; r record;
begin
 if p_turno is null or p_turno not in ('manana','tarde','sin_definir') or p_fecha is null then raise exception 'Fecha y turno inválidos'; end if;
 select empresa_id into v_empresa from public.flota_usuarios
  where usuario_id = auth.uid() and activo and rol in ('propietario','socio','operador') order by created_at limit 1;
 if v_empresa is null then raise exception 'No autorizado'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text), pg_catalog.hashtext(p_fecha::text || p_turno));
 select id, estado into v_destino, v_dest_estado from public.rutas_generales
  where empresa_id = v_empresa and fecha = p_fecha and turno = p_turno and estado in ('abierta','optimizada','en_reparto')
  order by created_at limit 1 for update;
 if v_destino is null then raise exception 'Primero creá la ruta del turno'; end if;
 for r in
  select p.id, p.version_edicion, p.tienda_id, p.ruta_general_id, p.numero_general
  from public.pedidos p join public.rutas_generales g on g.id = p.ruta_general_id
  where g.empresa_id = v_empresa and g.id <> v_destino
    and ((g.turno is null and g.estado = 'abierta' and g.fecha <= p_fecha)
      or (g.fecha < p_fecha and g.estado <> 'cerrada'))
    and p.empresa_id = v_empresa and p.estado = 'pendiente' and p.motorista_id is null
    and coalesce(p.turno, 'sin_definir') = p_turno
    and not exists (select 1 from public.movimientos_financieros mf where mf.pedido_id = p.id)
  order by p.id
  for update of p
 loop
  update public.pedidos
     set ruta_general_id = case when v_dest_estado = 'abierta' then v_destino end,
         numero_general = null, requiere_revisar_ruta = (v_dest_estado <> 'abierta'),
         version_edicion = coalesce(version_edicion, 0) + 1, updated_at = now()
   where id = r.id;
  insert into public.pedidos_ediciones(pedido_id, empresa_id, tienda_id, usuario_id, version_anterior, version_nueva, cambios)
  values (r.id, v_empresa, r.tienda_id, auth.uid(), coalesce(r.version_edicion, 0), coalesce(r.version_edicion, 0) + 1,
          jsonb_build_object('ruta_general_id', jsonb_build_object('antes', r.ruta_general_id, 'despues', case when v_dest_estado = 'abierta' then v_destino end),
                             'numero_general', jsonb_build_object('antes', r.numero_general, 'despues', null),
                             'motivo', 'rescate de pedido pendiente desde ruta anterior'));
  v_total := v_total + 1;
 end loop;
 update public.rutas_generales g set estado = 'cerrada'
  where g.empresa_id = v_empresa and g.id <> v_destino and g.estado <> 'cerrada'
    and ((g.turno is null and g.fecha <= p_fecha) or g.fecha < p_fecha)
    and not exists (select 1 from public.pedidos p where p.ruta_general_id = g.id);
 return v_total;
end $function$;

-- ---------- F2 ----------
create or replace function public.motorista_actualizar_estado_pedido(p_pedido_id uuid, p_motorista_id uuid, p_nuevo_estado text, p_medio_cobro text, p_motivo_incidencia text)
 returns void
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare v_empresa uuid; v_estado text; v_moto uuid;
begin
 if p_nuevo_estado is null or p_nuevo_estado not in ('no_recibio','no_responde','pasa_manana') then
  raise exception 'Usá Entregado o Rechazado desde su botón; aquí solo se registran incidencias';
 end if;
 select empresa_id, estado, motorista_id into v_empresa, v_estado, v_moto from public.pedidos where id = p_pedido_id for update;
 if v_empresa is null or v_moto is distinct from p_motorista_id then raise exception 'Pedido no asignado'; end if;
 if not exists (select 1 from public.motoristas m where m.id = p_motorista_id and m.usuario_id = auth.uid() and m.empresa_id = v_empresa and m.activo)
    and not exists (select 1 from public.flota_usuarios f where f.empresa_id = v_empresa and f.usuario_id = auth.uid() and f.activo and f.rol in ('propietario','socio')) then
  raise exception 'No autorizado';
 end if;
 if v_estado not in ('pendiente','no_recibio','no_responde','pasa_manana') then raise exception 'Pedido cerrado'; end if;
 if p_motivo_incidencia is null or length(trim(p_motivo_incidencia)) < 3 then raise exception 'Motivo obligatorio'; end if;
 update public.pedidos set estado = p_nuevo_estado, medio_cobro = null, motivo_incidencia = trim(p_motivo_incidencia), updated_at = now()
  where id = p_pedido_id;
end $function$;

-- ---------- F6 ----------
create or replace function public.tienda_agregar_pedido_a_ruta(p_pedido uuid, p_turno text)
 returns uuid
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare v public.pedidos%rowtype; r uuid; day date := (now() at time zone 'America/Asuncion')::date;
begin
 if p_turno is null or p_turno not in ('manana','tarde') then raise exception 'Seleccioná Mañana o Tarde'; end if;
 if auth.uid() is null then raise exception 'Iniciá sesión'; end if;
 select * into v from public.pedidos where id = p_pedido for update;
 if not found then raise exception 'Pedido inexistente'; end if;
 if not exists (select 1 from public.tienda_miembros m join public.tiendas t on t.id = m.tienda_id
                where m.tienda_id = v.tienda_id and m.usuario_id = auth.uid() and m.activo and t.activo and t.empresa_id = v.empresa_id) then
  raise exception 'No autorizado';
 end if;
 if v.estado <> 'pendiente' or v.motorista_id is not null then raise exception 'Pedido ya asignado o procesado'; end if;
 if v.lat is null or v.lng is null or v.lat not between -28 and -19 or v.lng not between -63 and -54 then raise exception 'GPS inválido'; end if;
 if exists (select 1 from public.movimientos_financieros m where m.pedido_id = v.id) then raise exception 'Pedido con cobros: no puede cambiarse'; end if;
 if v.ruta_general_id is not null then
  select id into r from public.rutas_generales where id = v.ruta_general_id and empresa_id = v.empresa_id and estado = 'abierta' and turno = p_turno;
  if r is not null and v.turno = p_turno then return r; end if;
  if exists (select 1 from public.rutas_generales where id = v.ruta_general_id and estado <> 'abierta') then
   raise exception 'Ruta confirmada: solicitá reorganización a Central';
  end if;
 elsif v.requiere_revisar_ruta and v.turno = p_turno then
  return null;
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v.empresa_id::text), pg_catalog.hashtext(day::text || p_turno));
 select id into r from public.rutas_generales
  where empresa_id = v.empresa_id and fecha = day and turno = p_turno and estado in ('abierta','optimizada','en_reparto')
  order by created_at limit 1;
 if r is not null and exists (select 1 from public.rutas_generales where id = r and estado <> 'abierta') then
  update public.pedidos set ruta_general_id = null, turno = p_turno, numero_general = null, requiere_revisar_ruta = true,
         version_edicion = coalesce(version_edicion, 0) + 1, updated_at = now()
   where id = v.id;
  return null;
 end if;
 if r is null then
  insert into public.rutas_generales(empresa_id, fecha, turno, estado, version_optimizacion)
  values (v.empresa_id, day, p_turno, 'abierta', 0) returning id into r;
 end if;
 update public.pedidos set ruta_general_id = r, turno = p_turno, numero_general = null, requiere_revisar_ruta = false,
        version_edicion = coalesce(version_edicion, 0) + 1, updated_at = now()
  where id = v.id;
 return r;
end $function$;

-- Central: sumar pedidos nuevos AL FINAL de una ruta confirmada, sin renumerar los existentes.
create or replace function public.flota_anexar_pedidos_a_ruta(p_ruta uuid, p_pedidos uuid[])
 returns integer
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare v_empresa uuid; v_estado text; v_turno text; v_total integer; v_valid integer; v_max integer;
begin
 select empresa_id, estado, turno into v_empresa, v_estado, v_turno from public.rutas_generales where id = p_ruta for update;
 if v_empresa is null or v_estado not in ('optimizada','en_reparto') or v_turno is null then
  raise exception 'Solo se puede anexar a una ruta confirmada con turno';
 end if;
 if not exists (select 1 from public.flota_usuarios where empresa_id = v_empresa and usuario_id = auth.uid() and activo and rol in ('propietario','socio','operador')) then
  raise exception 'No autorizado';
 end if;
 v_total := coalesce(array_length(p_pedidos, 1), 0);
 if v_total < 1 or v_total > 200 or (select count(distinct x) from unnest(p_pedidos) x) <> v_total then raise exception 'Selección inválida o duplicada'; end if;
 perform 1 from public.pedidos where id = any(p_pedidos) order by id for update;
 select count(*) into v_valid from public.pedidos p
  where p.id = any(p_pedidos) and p.empresa_id = v_empresa and p.estado = 'pendiente' and p.motorista_id is null
    and p.lat is not null and p.lng is not null and coalesce(p.turno, 'sin_definir') = v_turno
    and (p.ruta_general_id is null or (p.ruta_general_id = p_ruta and p.numero_general is null))
    and not exists (select 1 from public.movimientos_financieros mf where mf.pedido_id = p.id);
 if v_valid <> v_total then raise exception 'Todos los pedidos deben ser pendientes, sin número, del mismo turno y sin ruta confirmada'; end if;
 select coalesce(max(numero_general), 0) into v_max from public.pedidos where ruta_general_id = p_ruta;
 update public.pedidos p set ruta_general_id = p_ruta, numero_general = v_max + u.n, requiere_revisar_ruta = false,
        version_edicion = coalesce(p.version_edicion, 0) + 1, updated_at = now()
  from unnest(p_pedidos) with ordinality u(id, n) where p.id = u.id;
 return v_total;
end $function$;

revoke all on function public.flota_anexar_pedidos_a_ruta(uuid, uuid[]) from public, anon;
grant execute on function public.flota_anexar_pedidos_a_ruta(uuid, uuid[]) to authenticated;
