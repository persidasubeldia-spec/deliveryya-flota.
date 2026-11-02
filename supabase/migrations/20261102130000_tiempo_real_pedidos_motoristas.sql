-- Activa Supabase Realtime para pedidos y motoristas (Central ve entregas y GPS al instante).
-- Realtime respeta RLS: cada usuario solo recibe cambios de filas que puede leer.
-- Reversión: supabase/rollback/20261102130000_tiempo_real_pedidos_motoristas.sql
do $$begin
 if not exists(select 1 from pg_publication where pubname='supabase_realtime') then create publication supabase_realtime; end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='pedidos') then alter publication supabase_realtime add table public.pedidos; end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='motoristas') then alter publication supabase_realtime add table public.motoristas; end if;
end$$;
