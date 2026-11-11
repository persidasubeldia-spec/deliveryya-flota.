-- Respaldo exacto de public.flota_quitar_pedidos_ruta_seguros, lectura de producción 2026-11-11.
-- Idempotente: CREATE OR REPLACE FUNCTION. No ejecutar automáticamente contra producción.
CREATE OR REPLACE FUNCTION public.flota_quitar_pedidos_ruta_seguros(p_pedidos uuid[], p_versiones jsonb, p_fecha date)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid:='a0000000-0000-0000-0000-000000000001'::uuid;
 v_total integer; v_validados integer; v_p public.pedidos%rowtype; v_version integer;
begin
 v_total=coalesce(array_length(p_pedidos,1),0);
 if v_total<1 or v_total>100 or (select count(distinct x) from unnest(p_pedidos) as x)<>v_total
 then raise exception 'Selección inválida';end if;
 if p_fecha is distinct from (now() at time zone 'America/Asuncion')::date then raise exception 'Solo se pueden quitar pedidos de la jornada de hoy';end if;
 if not exists(select 1 from public.flota_usuarios f where f.empresa_id=v_empresa and f.usuario_id=auth.uid() and f.activo and f.rol in ('propietario','socio','operador'))
 then raise exception 'Sin permisos para modificar rutas';end if;
 perform 1 from public.pedidos p where p.id=any(p_pedidos) order by p.id for update;
 select count(*) into v_validados from public.pedidos p
 left join public.rutas_generales r on r.id=p.ruta_general_id and r.empresa_id=p.empresa_id
 where p.id=any(p_pedidos) and p.empresa_id=v_empresa
 and p.estado='pendiente' and p.excluido_ruta=false
 and (coalesce(p.version_edicion,0)=nullif(p_versiones->>(p.id::text),'')::integer)
 and ((r.fecha=p_fecha and r.estado in ('abierta','optimizada','en_reparto'))
      or (p.ruta_general_id is null and p.motorista_id is null and (p.created_at at time zone 'America/Asuncion')::date=p_fecha))
 and not exists(select 1 from public.movimientos_financieros mf where mf.pedido_id=p.id)
 and not exists(select 1 from public.flota_rechazos_detalle fr where fr.pedido_id=p.id)
 and not exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=p.motorista_id and c.fecha=p_fecha);
 if v_validados<>v_total then raise exception 'Algún pedido ya se entregó, cobró, cambió o no pertenece a hoy. Actualizá Central';end if;
 for v_p in select * from public.pedidos where id=any(p_pedidos) order by id loop
  v_version=coalesce(v_p.version_edicion,0);
  update public.pedidos set motorista_id=null,ruta_general_id=null,numero_general=null,
   excluido_ruta=true,requiere_revisar_ruta=false,version_edicion=v_version+1,updated_at=now()
   where id=v_p.id;
  insert into public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  values(v_p.id,v_empresa,v_p.tienda_id,auth.uid(),v_version,v_version+1,
    pg_catalog.jsonb_build_object('accion','quitar_de_ruta_sin_borrar_pedido','fecha',p_fecha,
    'ruta_anterior',v_p.ruta_general_id,'numero_anterior',v_p.numero_general,
    'motorista_anterior',v_p.motorista_id,'estado_conservado',v_p.estado));
 end loop;
 return v_total;
end $function$
