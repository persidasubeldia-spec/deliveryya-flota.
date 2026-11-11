-- Respaldo exacto de public.flota_reservar_optimizacion_google, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_reservar_optimizacion_google()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_empresa uuid;
 v_hoy date := (now() at time zone 'America/Asuncion')::date;
 v_mes text := to_char(now() at time zone 'America/Asuncion','YYYY-MM');
 v_clave text;
 v_consumido integer;
begin
 select m.empresa_id into v_empresa
 from public.motoristas m where m.usuario_id=auth.uid() and m.activo order by m.created_at limit 1;
 if v_empresa is null then raise exception 'No autorizado';end if;
 -- Bloqueo global: evita que varias flotas simultáneas sobrepasen el cupo del proyecto.
 perform pg_catalog.pg_advisory_xact_lock(764000,764001);
 -- Margen conservador frente a 5.000 consultas gratuitas mensuales del SKU Pro,
 -- NO constituye garantía de que el proyecto Google no tenga otros consumos.
 foreach v_clave in array array[
 'proyecto:mes:'||v_mes,
 'proyecto:dia:'||v_hoy::text,
 'empresa:'||v_empresa::text||':dia:'||v_hoy::text
 ] loop
  select c.cantidad into v_consumido from public.flota_cupo_optimizacion_google c where c.clave=v_clave;
  if (v_clave like 'proyecto:mes:%' and coalesce(v_consumido,0)>=1500)
    or (v_clave like 'proyecto:dia:%' and coalesce(v_consumido,0)>=60)
    or (v_clave like 'empresa:%' and coalesce(v_consumido,0)>=20)
  then return jsonb_build_object('autorizado',false,'motivo','Límite preventivo de optimizaciones Google alcanzado. Usaremos OSRM sin bloquear entregas.');end if;
 end loop;
 foreach v_clave in array array[
 'proyecto:mes:'||v_mes,
 'proyecto:dia:'||v_hoy::text,
 'empresa:'||v_empresa::text||':dia:'||v_hoy::text
 ] loop
  insert into public.flota_cupo_optimizacion_google(clave,cantidad)
  values(v_clave,1)
  on conflict(clave) do update
  set cantidad=public.flota_cupo_optimizacion_google.cantidad+1, actualizado_en=now();
 end loop;
 return jsonb_build_object('autorizado',true,'cupo_mensual_interno',1500);
end $function$
