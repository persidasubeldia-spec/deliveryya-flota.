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

-- Comprobar al crear que el original registrado coincide con el precio
-- que se guardó: única diferencia autorizada = mínimo especial T14 (20k→25k).
CREATE OR REPLACE FUNCTION public.flota_validar_importes_originales_tienda()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $body$
BEGIN
 IF NEW.precio_mercaderia_cargado_tienda IS NOT NULL
    AND NEW.precio_mercaderia_cargado_tienda IS DISTINCT FROM NEW.precio_mercaderia
 THEN RAISE EXCEPTION 'Precio original de mercadería inconsistente con lo registrado'; END IF;
 IF NEW.precio_delivery_cargado_tienda IS NOT NULL
    AND NEW.precio_delivery_cargado_tienda IS DISTINCT FROM NEW.precio_delivery
    AND NOT (NEW.regla_comercial='boom_25k_cliente_20k_v1'
      AND NEW.precio_delivery_cargado_tienda=20000
      AND NEW.precio_delivery=25000
      AND NEW.delivery_cliente=20000
      AND NEW.delivery_subsidio_tienda=5000)
 THEN RAISE EXCEPTION 'Precio original del delivery inconsistente con la tarifa aplicada'; END IF;
 RETURN NEW;
END;
$body$;
DROP TRIGGER IF EXISTS flota_validar_importes_originales_tienda_trg ON public.pedidos;
CREATE TRIGGER flota_validar_importes_originales_tienda_trg
AFTER INSERT ON public.pedidos FOR EACH ROW
EXECUTE FUNCTION public.flota_validar_importes_originales_tienda();

-- Supabase: la tabla pedidos ya tiene sus políticas RLS y permisos vigentes.
-- La función de trigger no se expone como RPC de clientes.
REVOKE ALL ON FUNCTION public.flota_proteger_importes_originales_tienda() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.flota_validar_importes_originales_tienda() FROM PUBLIC,anon,authenticated;
