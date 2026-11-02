do $$declare r record;begin
for r in select p.oid::regprocedure f, p.proname, pg_get_function_identity_arguments(p.oid) a from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prokind='f' and not exists(select 1 from pg_depend d where d.objid=p.oid and d.deptype='e') loop
 execute format('revoke all on function %s from public, anon, authenticated',r.f);
 if not (r.proname in ('provisionar_tienda_v2','deliveryya_propietario_membresia','registrar_movimiento_financiero','flota_impedir_cobros_con_caja_presentada') or (r.proname='tienda_agregar_pedido_a_ruta' and r.a='p_pedido uuid')) then
   execute format('grant execute on function %s to authenticated',r.f); end if;
end loop;end$$;
grant select,insert,update,delete on all tables in schema public to anon, authenticated;
revoke all on public.flota_solicitudes_tienda from anon, authenticated;
revoke all on public.pedidos_ediciones from anon, authenticated; grant select on public.pedidos_ediciones to authenticated;
grant all on all tables in schema public to service_role;
