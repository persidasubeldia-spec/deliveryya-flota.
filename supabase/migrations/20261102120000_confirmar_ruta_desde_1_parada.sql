-- Permite confirmar una ruta de 1 sola parada (reparto rápido de un único pedido). Reversión: supabase/rollback/20261102120000_confirmar_ruta_desde_1_parada.sql
CREATE OR REPLACE FUNCTION public.admin_confirmar_ruta_optimizada(p_ruta_general_id uuid, p_orden_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_estado text;v_turno text;v_count integer;v_selected integer;
begin
 select empresa_id,estado,turno into v_empresa,v_estado,v_turno from public.rutas_generales where id=p_ruta_general_id for update;
 if v_empresa is null or v_estado not in('abierta','optimizada') or v_turno not in('manana','tarde','sin_definir') then raise exception 'La ruta debe estar abierta, autorizada y tener turno definido';end if;
 if not exists(select 1 from public.flota_usuarios where empresa_id=v_empresa and usuario_id=auth.uid() and activo and rol in('propietario','socio','operador')) then raise exception 'No autorizado';end if;
 v_count=coalesce(array_length(p_orden_ids,1),0);
 if v_count<1 or v_count>2000 then raise exception 'Seleccioná entre 1 y 2000 paradas';end if;
 if (select count(distinct x) from unnest(p_orden_ids) x)<>v_count then raise exception 'IDs duplicados';end if;
 perform 1 from public.pedidos where id=any(p_orden_ids) or ruta_general_id=p_ruta_general_id order by id for update;
 if exists(select 1 from public.pedidos where ruta_general_id=p_ruta_general_id and (estado<>'pendiente' or motorista_id is not null)) then raise exception 'Ruta con repartos o entregas: no puede renumerarse';end if;
 if exists(select 1 from public.pedidos p where p.ruta_general_id=p_ruta_general_id and not(p.id=any(p_orden_ids))) then raise exception 'Hay pedidos preparados que no están en el cálculo: incluilos antes de confirmar para evitar que desaparezcan de la ruta';end if;
 select count(*) into v_selected from public.pedidos p where p.id=any(p_orden_ids) and p.empresa_id=v_empresa and p.estado='pendiente' and p.motorista_id is null and p.lat is not null and p.lng is not null
 and coalesce(p.turno,'sin_definir')=v_turno and (p.ruta_general_id is null or p.ruta_general_id=p_ruta_general_id);
 if v_selected<>v_count then raise exception 'Todos los pedidos deben pertenecer a una misma empresa, turno y ruta';end if;
 update public.pedidos p set numero_general=u.numero,ruta_general_id=p_ruta_general_id,updated_at=now()
 from unnest(p_orden_ids) with ordinality u(id,numero) where p.id=u.id;
 update public.rutas_generales set estado='optimizada',version_optimizacion=coalesce(version_optimizacion,0)+1 where id=p_ruta_general_id;
end $function$

;
