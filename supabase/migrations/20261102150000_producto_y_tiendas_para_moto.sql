-- Producto del pedido (qué se entrega) y nombre de la tienda visible para la moto.
-- Reversión: supabase/rollback/20261102150000_producto_y_tiendas_para_moto.sql
alter table public.pedidos add column if not exists producto text;
do $$begin
 if not exists(select 1 from pg_constraint where conname='pedidos_producto_largo') then
  alter table public.pedidos add constraint pedidos_producto_largo check (producto is null or length(producto)<=200);
 end if;
end$$;

-- La moto solo ve código, nombre y teléfono de las tiendas de SUS pedidos.
create or replace function public.motorista_mis_tiendas()
 returns table(id uuid, codigo text, nombre_comercial text, telefono text)
 language sql
 stable
 security definer
 set search_path to ''
as $function$
 select distinct t.id, t.codigo, t.nombre_comercial, t.telefono
 from public.motoristas m
 join public.pedidos p on p.motorista_id=m.id
 join public.tiendas t on t.id=p.tienda_id
 where m.usuario_id=auth.uid() and m.activo
$function$;
revoke all on function public.motorista_mis_tiendas() from public, anon;
grant execute on function public.motorista_mis_tiendas() to authenticated;
