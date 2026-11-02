-- Reversión: quita la función. La columna 'producto' se conserva para no perder datos cargados;
-- para quitarla también (borra esos textos): alter table public.pedidos drop column producto;
drop function if exists public.motorista_mis_tiendas();
