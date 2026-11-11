-- Respaldo exacto de public.flota_historial_reprogramados_fecha, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_historial_reprogramados_fecha(p_fecha date)
 RETURNS TABLE(pedido_id uuid, tienda_id uuid, tienda_nombre text, cliente text, fecha_origen date, fecha_destino date, motorista_anterior text, motivo text, momento timestamp with time zone, accion text, fecha_carga date)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT e.pedido_id,e.tienda_id,t.nombre_comercial,p.nombre_cliente,
  (e.cambios->>'fecha_anterior')::date,(e.cambios->>'fecha_nueva')::date,
  coalesce(m.nombre,'Sin asignar')::text,
  coalesce(e.cambios->>'motivo_reprogramacion',e.cambios->>'motivo_nuevo','Reprogramado')::text,
  e.momento,e.cambios->>'accion',
  (p.created_at AT TIME ZONE 'America/Asuncion')::date
 FROM public.pedidos_ediciones e
 JOIN public.pedidos p ON p.id=e.pedido_id AND p.empresa_id=e.empresa_id
 JOIN public.tiendas t ON t.id=e.tienda_id AND t.empresa_id=e.empresa_id
 LEFT JOIN public.motoristas m ON m.id=(e.cambios->>'motorista_anterior')::uuid AND m.empresa_id=e.empresa_id
 WHERE (e.cambios->>'accion') IN ('pasar_manana_automatico','pasar_manana_central')
 AND (e.cambios->>'fecha_anterior')=p_fecha::text
 AND EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.empresa_id=e.empresa_id AND u.usuario_id=auth.uid()
 AND u.activo AND u.rol IN ('propietario','socio','operador'))
 ORDER BY t.nombre_comercial,p.nombre_cliente,e.momento;
$function$
