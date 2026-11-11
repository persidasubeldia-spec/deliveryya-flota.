-- Respaldo exacto de public.flota_saldos_rechazos_por_tienda, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_saldos_rechazos_por_tienda()
 RETURNS TABLE(pedido_id uuid, tienda_id uuid, nombre_cliente text, fecha_ruta date, costo_rechazo integer, compensado integer, saldo_pendiente integer, estado_cobro text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT r.pedido_id,r.tienda_id,p.nombre_cliente,g.fecha,
  greatest(0,r.importe_pendiente)::integer,
  coalesce(c.importe,0)::integer,
  greatest(0,r.importe_pendiente-coalesce(c.importe,0))::integer,
  CASE WHEN c.id IS NOT NULL THEN 'compensado'
       WHEN r.importe_pendiente>0 THEN 'pendiente'
       ELSE 'sin_saldo' END::text
 FROM public.flota_rechazos_detalle r
 JOIN public.pedidos p ON p.id=r.pedido_id
 LEFT JOIN public.rutas_generales g ON g.id=p.ruta_general_id
 LEFT JOIN public.flota_compensaciones_tienda c ON c.pedido_id=r.pedido_id AND c.empresa_id=r.empresa_id
 WHERE r.responsable_pago='tienda' AND p.estado='rechazado'
 AND EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=r.empresa_id AND u.activo AND (u.rol='propietario' OR u.puede_finanzas OR u.puede_confirmar_rendiciones))
 ORDER BY g.fecha DESC,p.nombre_cliente;
$function$
