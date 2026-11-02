-- Reversión: quita pedidos y motoristas de Realtime (Central vuelve a la revisión cada 15 s).
alter publication supabase_realtime drop table public.pedidos;
alter publication supabase_realtime drop table public.motoristas;
