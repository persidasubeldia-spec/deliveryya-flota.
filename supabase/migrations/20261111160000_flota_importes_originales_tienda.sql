-- DeliveryYa Flota · registrar exactamente lo ingresado por la tienda al crear.
-- Los campos son independientes del importe normalizado/transformado por reglas comerciales.
-- NULL en pedidos anteriores significa: dato original no conservado; NO inventar backfill.
ALTER TABLE public.pedidos
 ADD COLUMN IF NOT EXISTS precio_mercaderia_cargado_tienda integer,
 ADD COLUMN IF NOT EXISTS precio_delivery_cargado_tienda integer;
COMMENT ON COLUMN public.pedidos.precio_mercaderia_cargado_tienda IS
 'Importe de mercadería ingresado por tienda en creación; inmutable; NULL=original no conservado.';
COMMENT ON COLUMN public.pedidos.precio_delivery_cargado_tienda IS
 'Importe bruto de envío introducido/seleccionado por tienda antes de subsidio Boom; inmutable; NULL=original no conservado.';

CREATE OR REPLACE FUNCTION public.flota_proteger_importes_originales_tienda()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $body$
BEGIN
 IF NEW.precio_mercaderia_cargado_tienda IS DISTINCT FROM OLD.precio_mercaderia_cargado_tienda
    OR NEW.precio_delivery_cargado_tienda IS DISTINCT FROM OLD.precio_delivery_cargado_tienda
 THEN
   RAISE EXCEPTION 'Los importes originales cargados por la tienda no se pueden modificar. Registrá un ajuste auditado.';
 END IF;
 RETURN NEW;
END;
$body$;
DROP TRIGGER IF EXISTS flota_importes_originales_tienda_inmutables_trg ON public.pedidos;
CREATE TRIGGER flota_importes_originales_tienda_inmutables_trg
BEFORE UPDATE OF precio_mercaderia_cargado_tienda,precio_delivery_cargado_tienda
ON public.pedidos FOR EACH ROW
EXECUTE FUNCTION public.flota_proteger_importes_originales_tienda();

-- Supabase: la tabla pedidos ya tiene sus políticas RLS y permisos vigentes.
-- La función de trigger no se expone como RPC de clientes.
REVOKE ALL ON FUNCTION public.flota_proteger_importes_originales_tienda() FROM PUBLIC,anon,authenticated;
