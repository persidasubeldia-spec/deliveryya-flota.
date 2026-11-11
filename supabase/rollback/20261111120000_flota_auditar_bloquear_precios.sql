-- Reversión estructural, nunca borrar datos sin una copia aprobada.
DROP TRIGGER IF EXISTS flota_precio_inicial_audit_trg ON public.pedidos;
DROP TRIGGER IF EXISTS flota_precio_modificado_audit_trg ON public.pedidos;
DROP TRIGGER IF EXISTS flota_precio_finalizado_guard_trg ON public.pedidos;
DROP FUNCTION IF EXISTS public.flota_guardar_auditoria_precios();
DROP FUNCTION IF EXISTS public.flota_bloquear_precio_finalizado();
-- Se conserva flota_auditoria_precios: es evidencia financiera y no debe borrarse en rollback.
