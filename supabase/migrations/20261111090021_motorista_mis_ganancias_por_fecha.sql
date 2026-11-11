-- Respaldo exacto de public.motorista_mis_ganancias_por_fecha, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.motorista_mis_ganancias_por_fecha(p_fecha date)
 RETURNS TABLE(pedido_id uuid, estado text, ganancia_prevista integer, ganancia_confirmada integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT p.id,p.estado,
 CASE WHEN p.estado IN ('pendiente','no_responde','no_recibio','pasa_manana')
       AND NOT (p.estado='pendiente' AND coalesce(p.motivo_incidencia,'') ILIKE 'No me fui:%')
       AND p.precio_delivery>=0 AND p.porcentaje_empresa_pct BETWEEN 0 AND 100
 THEN greatest(0,p.precio_delivery-round((p.precio_delivery::numeric*p.porcentaje_empresa_pct)/100)::integer)
 ELSE CASE WHEN p.estado='pendiente' AND coalesce(p.motivo_incidencia,'') ILIKE 'No me fui:%' OR p.estado='cancelado' THEN 0 ELSE null END END AS ganancia_prevista,
 CASE WHEN p.estado IN ('entregado','rechazado') THEN mf.comision_motorista
      WHEN p.estado='cancelado' OR (p.estado='pendiente' AND coalesce(p.motivo_incidencia,'') ILIKE 'No me fui:%') THEN 0
      ELSE null END AS ganancia_confirmada
 FROM public.pedidos p
 JOIN public.motoristas m ON m.id=p.motorista_id AND m.usuario_id=auth.uid() AND m.activo AND m.empresa_id=p.empresa_id
 JOIN public.rutas_generales r ON r.id=p.ruta_general_id AND r.fecha=p_fecha AND r.empresa_id=p.empresa_id
 LEFT JOIN public.movimientos_financieros mf ON mf.pedido_id=p.id AND mf.motorista_id=m.id
 WHERE p_fecha IS NOT NULL AND p_fecha BETWEEN (now() AT TIME ZONE 'America/Asuncion')::date-365 AND (now() AT TIME ZONE 'America/Asuncion')::date+30
$function$
