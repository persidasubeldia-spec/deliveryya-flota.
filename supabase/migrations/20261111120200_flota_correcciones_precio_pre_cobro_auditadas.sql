-- Compatibility-only schema for audited pre-collection price corrections.
-- Created in the authorized production incident resolution on 2026-11-11.
-- Does NOT repeat historical edits or include any client identifiers/data.
CREATE TABLE IF NOT EXISTS public.flota_correcciones_precio_pre_cobro_auditadas (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 clave_operacion text NOT NULL UNIQUE,
 empresa_id uuid NOT NULL,
 tienda_id uuid NOT NULL,
 pedido_id uuid NOT NULL REFERENCES public.pedidos(id),
 precio_anterior integer NOT NULL,
 precio_nuevo integer NOT NULL,
 version_anterior integer NOT NULL,
 version_nueva integer NOT NULL,
 valores_delivery jsonb NOT NULL,
 motivo text NOT NULL,
 origen_autorizacion text NOT NULL,
 actor_tipo text NOT NULL,
 registrado_en timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.flota_correcciones_precio_pre_cobro_auditadas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.flota_correcciones_precio_pre_cobro_auditadas FROM PUBLIC,anon,authenticated;
