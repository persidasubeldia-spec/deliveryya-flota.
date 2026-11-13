-- Incidencias de visita con costo a cargo de tienda (registro administrativo verificable).
-- NO modificar movimientos históricos mediante esta migración.
CREATE TABLE IF NOT EXISTS public.flota_incidencias_visita_auditadas (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 pedido_id uuid NOT NULL REFERENCES public.pedidos(id),
 empresa_id uuid NOT NULL,
 tienda_id uuid NOT NULL,
 motorista_id uuid NOT NULL,
 fecha_operativa date NOT NULL,
 estado_anterior text NOT NULL,
 motivo_anterior text,
 motivo_facturable text NOT NULL,
 importe_delivery integer NOT NULL CHECK(importe_delivery>0),
 importe_cobrado_cliente integer NOT NULL DEFAULT 0 CHECK(importe_cobrado_cliente>=0),
 ganancia_motorista integer NOT NULL CHECK(ganancia_motorista>=0),
 ganancia_central integer NOT NULL CHECK(ganancia_central>=0),
 autorizacion text NOT NULL,
 registrado_en timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT flota_incidencias_visita_pedido_unico UNIQUE(pedido_id),
 CONSTRAINT flota_incidencias_visita_balanza CHECK (ganancia_motorista+ganancia_central=importe_delivery)
);
ALTER TABLE public.flota_incidencias_visita_auditadas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.flota_incidencias_visita_auditadas FROM PUBLIC,anon,authenticated;
COMMENT ON TABLE public.flota_incidencias_visita_auditadas IS 'Evidencia interna de reclasificación autorizada de visitas no cobradas a incidencias facturables a tienda; no reemplaza comprobante de pago.';
