-- Respaldo exacto de public.flota_reasignar_lote_seguro, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_reasignar_lote_seguro(p_pedidos uuid[], p_motorista_destino uuid, p_versiones jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_id uuid;v_n integer;v_result jsonb;v_results jsonb:='[]'::jsonb;v_total integer;
BEGIN
 v_total:=coalesce(pg_catalog.array_length(p_pedidos,1),0);
 IF v_total<1 OR v_total>100 OR (SELECT count(DISTINCT z) FROM unnest(p_pedidos) AS z)<>v_total THEN
 RAISE EXCEPTION 'Seleccioná de 1 a 100 pedidos sin duplicados';
 END IF;
 IF p_motorista_destino IS NULL OR p_versiones IS NULL OR jsonb_typeof(p_versiones)<>'object' THEN
 RAISE EXCEPTION 'Falta motorista o versión de los pedidos';
 END IF;
 FOR v_id IN SELECT z FROM unnest(p_pedidos) z ORDER BY z LOOP
   IF NOT (p_versiones ? v_id::text) OR (p_versiones->>v_id::text) !~ '^[0-9]+$' THEN
      RAISE EXCEPTION 'Falta la versión del pedido %. Actualizá Central',v_id;
   END IF;
   v_n:=(p_versiones->>v_id::text)::integer;
   v_result:=public.flota_reasignar_pedido_seguro(v_id,p_motorista_destino,v_n);
   v_results:=v_results || jsonb_build_array(v_result);
 END LOOP;
 RETURN jsonb_build_object('total',v_total,'resultados',v_results);
END;
$function$
