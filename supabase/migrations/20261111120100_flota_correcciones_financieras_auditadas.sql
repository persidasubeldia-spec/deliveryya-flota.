-- Registro histórico de correcciones FINANCIERAS autorizadas fuera del flujo normal.
-- Estructura ya creada para la conciliación puntual del 11/11/2026 en producción.
-- Esta migración de compatibilidad NO reproduce datos particulares de clientes,
-- NO altera filas y no vuelve a ejecutar una corrección ya registrada.
CREATE TABLE IF NOT EXISTS public.flota_correcciones_financieras_auditadas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clave_operacion text NOT NULL UNIQUE,
  empresa_id uuid NOT NULL,
  tienda_id uuid NOT NULL,
  pedido_id uuid NOT NULL REFERENCES public.pedidos(id),
  movimiento_id uuid NOT NULL REFERENCES public.movimientos_financieros(id),
  antes_pedido jsonb NOT NULL,
  despues_pedido jsonb NOT NULL,
  antes_movimiento jsonb NOT NULL,
  despues_movimiento jsonb NOT NULL,
  diferencia_efectivo integer NOT NULL,
  motivo text NOT NULL,
  origen_autorizacion text NOT NULL,
  actor_tipo text NOT NULL,
  registrado_en timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.flota_correcciones_financieras_auditadas ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.flota_correcciones_financieras_auditadas FROM PUBLIC,anon,authenticated;
