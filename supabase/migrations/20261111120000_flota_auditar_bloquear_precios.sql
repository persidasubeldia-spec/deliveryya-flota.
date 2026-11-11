-- DeliveryYa Flota / 2026-11-11 / Protección de precios sin afectar filas históricas.
-- NO aplicar a producción sin validación en Supabase de ensayo.
-- Guarda un registro inmutable de importes desde su creación y ante cada cambio futuro.
CREATE TABLE IF NOT EXISTS public.flota_auditoria_precios (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empresa_id uuid NOT NULL,
  tienda_id uuid NOT NULL,
  pedido_id uuid NOT NULL REFERENCES public.pedidos(id),
  evento text NOT NULL CHECK (evento IN ('creacion','modificacion')),
  valores_anteriores jsonb,
  valores_nuevos jsonb NOT NULL,
  estado_anterior text,
  estado_nuevo text NOT NULL,
  autor_uid uuid,
  registrado_en timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS flota_auditoria_precios_pedido_fecha_idx
  ON public.flota_auditoria_precios(pedido_id,registrado_en DESC);
CREATE INDEX IF NOT EXISTS flota_auditoria_precios_empresa_fecha_idx
  ON public.flota_auditoria_precios(empresa_id,registrado_en DESC);
ALTER TABLE public.flota_auditoria_precios ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.flota_auditoria_precios FROM PUBLIC,anon,authenticated;
REVOKE ALL ON SEQUENCE public.flota_auditoria_precios_id_seq FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.flota_guardar_auditoria_precios()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_old jsonb;v_new jsonb;
BEGIN
  IF TG_OP='UPDATE' AND
    NEW.precio_mercaderia IS NOT DISTINCT FROM OLD.precio_mercaderia AND
    NEW.precio_delivery IS NOT DISTINCT FROM OLD.precio_delivery AND
    NEW.delivery_cliente IS NOT DISTINCT FROM OLD.delivery_cliente AND
    NEW.delivery_subsidio_tienda IS NOT DISTINCT FROM OLD.delivery_subsidio_tienda
  THEN RETURN NEW;END IF;

  IF TG_OP='UPDATE' THEN
    v_old=pg_catalog.jsonb_build_object(
      'mercaderia',OLD.precio_mercaderia,'tarifa_real',OLD.precio_delivery,
      'delivery_cliente',OLD.delivery_cliente,'subsidio_tienda',OLD.delivery_subsidio_tienda,
      'modalidad_pago',OLD.modalidad_pago);
  END IF;
  v_new=pg_catalog.jsonb_build_object(
      'mercaderia',NEW.precio_mercaderia,'tarifa_real',NEW.precio_delivery,
      'delivery_cliente',NEW.delivery_cliente,'subsidio_tienda',NEW.delivery_subsidio_tienda,
      'modalidad_pago',NEW.modalidad_pago);
  INSERT INTO public.flota_auditoria_precios(
    empresa_id,tienda_id,pedido_id,evento,valores_anteriores,valores_nuevos,
    estado_anterior,estado_nuevo,autor_uid
  ) VALUES(
    NEW.empresa_id,NEW.tienda_id,NEW.id,
    CASE WHEN TG_OP='INSERT' THEN 'creacion' ELSE 'modificacion' END,
    v_old,v_new,
    CASE WHEN TG_OP='UPDATE' THEN OLD.estado ELSE NULL END,NEW.estado,auth.uid()
  );
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.flota_bloquear_precio_finalizado()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
BEGIN
  IF NEW.precio_mercaderia IS DISTINCT FROM OLD.precio_mercaderia
    OR NEW.precio_delivery IS DISTINCT FROM OLD.precio_delivery
    OR NEW.delivery_cliente IS DISTINCT FROM OLD.delivery_cliente
    OR NEW.delivery_subsidio_tienda IS DISTINCT FROM OLD.delivery_subsidio_tienda
  THEN
    IF OLD.estado <> 'pendiente' OR NEW.estado <> 'pendiente'
      OR EXISTS(SELECT 1 FROM public.movimientos_financieros m WHERE m.pedido_id=OLD.id)
    THEN
      RAISE EXCEPTION 'Pedido finalizado o con cobro: no se puede cambiar el precio. Usá una corrección financiera auditada.';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS flota_precio_finalizado_guard_trg ON public.pedidos;
CREATE TRIGGER flota_precio_finalizado_guard_trg
BEFORE UPDATE OF precio_mercaderia,precio_delivery,delivery_cliente,delivery_subsidio_tienda
ON public.pedidos
FOR EACH ROW EXECUTE FUNCTION public.flota_bloquear_precio_finalizado();

DROP TRIGGER IF EXISTS flota_precio_inicial_audit_trg ON public.pedidos;
CREATE TRIGGER flota_precio_inicial_audit_trg
AFTER INSERT ON public.pedidos
FOR EACH ROW EXECUTE FUNCTION public.flota_guardar_auditoria_precios();

DROP TRIGGER IF EXISTS flota_precio_modificado_audit_trg ON public.pedidos;
CREATE TRIGGER flota_precio_modificado_audit_trg
AFTER UPDATE OF precio_mercaderia,precio_delivery,delivery_cliente,delivery_subsidio_tienda
ON public.pedidos
FOR EACH ROW EXECUTE FUNCTION public.flota_guardar_auditoria_precios();

REVOKE ALL ON FUNCTION public.flota_guardar_auditoria_precios() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.flota_bloquear_precio_finalizado() FROM PUBLIC,anon,authenticated;
