-- PostgreSQL 17 aislado: no conecta a Supabase ni contiene datos reales.
CREATE SCHEMA IF NOT EXISTS auth;
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS 'SELECT NULL::uuid';
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF; IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF; END $$;
CREATE TABLE public.tiendas(id uuid PRIMARY KEY,empresa_id uuid NOT NULL,codigo text,nombre_comercial text);
CREATE TABLE public.pedidos(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),empresa_id uuid NOT NULL,tienda_id uuid NOT NULL,
 estado text NOT NULL DEFAULT 'pendiente',precio_mercaderia integer NOT NULL,precio_delivery integer,
 delivery_cliente integer,delivery_subsidio_tienda integer,regla_comercial text,
 modalidad_pago text DEFAULT 'pendiente',created_at timestamptz DEFAULT now()
);
CREATE TABLE public.movimientos_financieros(id uuid DEFAULT gen_random_uuid() PRIMARY KEY,pedido_id uuid NOT NULL REFERENCES public.pedidos(id));
INSERT INTO public.tiendas VALUES('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','T14','Boom Store');
INSERT INTO public.tiendas VALUES('22222222-2222-4222-8222-222222222222','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','T2','Tienda de prueba');
-- Definición vigente del trigger especial leída en producción SOLO LECTURA.
CREATE OR REPLACE FUNCTION public.flota_boom_tarifa_minima_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_es_boom boolean;v_fecha_ingreso date;
begin
 select exists(select 1 from public.tiendas t where t.id=new.tienda_id and t.empresa_id=new.empresa_id and t.codigo='T14' and lower(trim(t.nombre_comercial))='boom store') into v_es_boom;
 if not v_es_boom then
  if tg_op='INSERT' and (new.delivery_cliente is not null or new.delivery_subsidio_tienda is not null or new.regla_comercial is not null) then raise exception 'Regla especial de Boom Store no autorizada para esta tienda'; end if;
  if tg_op='UPDATE' and (new.delivery_cliente is distinct from old.delivery_cliente or new.delivery_subsidio_tienda is distinct from old.delivery_subsidio_tienda or new.regla_comercial is distinct from old.regla_comercial) then raise exception 'No está permitido modificar los campos comerciales de otra tienda'; end if;
  return new;
 end if;
 -- Fecha de corte fija: sólo pedidos ingresados desde el 10/11/2026, hora de Paraguay.
 v_fecha_ingreso=coalesce((new.created_at at time zone 'America/Asuncion')::date,(now() at time zone 'America/Asuncion')::date);
 if v_fecha_ingreso<'2026-11-10'::date then
  if tg_op='UPDATE' and (new.delivery_cliente is distinct from old.delivery_cliente or new.delivery_subsidio_tienda is distinct from old.delivery_subsidio_tienda or new.regla_comercial is distinct from old.regla_comercial) then
   raise exception 'Pedido anterior al 10/11/2026: no modificar ni aplicar subsidio retroactivo';
  end if;
  return new;
 end if;
 if tg_op='INSERT' then
  if new.precio_delivery is null or (new.precio_delivery<20000 or (new.precio_delivery>20000 and new.precio_delivery<25000)) then raise exception 'Tarifa mínima Boom Store: Gs. 25.000 reales, cliente Gs. 20.000';end if;
  if new.precio_delivery in (20000,25000) then new.precio_delivery=25000;new.delivery_cliente=20000;new.delivery_subsidio_tienda=5000;
  else new.delivery_cliente=new.precio_delivery;new.delivery_subsidio_tienda=0;end if;
  new.regla_comercial='boom_25k_cliente_20k_v1';
 else
  if old.regla_comercial is distinct from 'boom_25k_cliente_20k_v1' then
   if new.delivery_cliente is distinct from old.delivery_cliente or new.delivery_subsidio_tienda is distinct from old.delivery_subsidio_tienda or new.regla_comercial is distinct from old.regla_comercial then raise exception 'Pedido sin regla comercial: no modificar campos de subsidio';end if;
   return new;
  end if;
  if new.regla_comercial is distinct from old.regla_comercial then raise exception 'No se puede eliminar la regla comercial del pedido';end if;
  if new.precio_delivery is distinct from old.precio_delivery then
   if old.estado<>'pendiente' or exists(select 1 from public.movimientos_financieros where pedido_id=new.id) then raise exception 'Movimiento financiero existente';end if;
   if new.precio_delivery<20000 or (new.precio_delivery>20000 and new.precio_delivery<25000) then raise exception 'Tarifa real mínima Boom Store Gs. 25.000';end if;
   if new.precio_delivery in (20000,25000) then new.precio_delivery=25000;new.delivery_cliente=20000;new.delivery_subsidio_tienda=5000;
   else new.delivery_cliente=new.precio_delivery;new.delivery_subsidio_tienda=0;end if;
  elsif new.delivery_cliente is distinct from old.delivery_cliente or new.delivery_subsidio_tienda is distinct from old.delivery_subsidio_tienda then
   raise exception 'No se puede alterar manualmente el aporte de tienda';
  end if;
 end if;
 return new;
end $function$;
CREATE TRIGGER zz_flota_boom_tarifa_minima_v1
BEFORE INSERT OR UPDATE OF precio_delivery,delivery_cliente,delivery_subsidio_tienda,regla_comercial
ON public.pedidos FOR EACH ROW EXECUTE FUNCTION public.flota_boom_tarifa_minima_v1();
