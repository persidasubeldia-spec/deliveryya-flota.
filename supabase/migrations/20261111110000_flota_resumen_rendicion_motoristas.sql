-- DeliveryYa Flota · vista financiera para Central (SOLO LECTURA).
-- Se alimenta de movimientos reales por fecha contable America/Asuncion y
-- de cierres existentes. NO recalcula comisiones por porcentaje.
-- La vista previa de efectivo aplica exactamente la regla de motorista_presentar_cierre;
-- si ya hay cierre, a_rendir_esperado del cierre es la fuente de verdad.
CREATE OR REPLACE FUNCTION public.flota_resumen_rendicion_motoristas(p_fecha date)
RETURNS TABLE (
  motorista_id uuid,
  motorista_nombre text,
  modalidad_liquidacion text,
  pedidos bigint,
  entregados bigint,
  rechazados bigint,
  pendientes bigint,
  pasa_manana bigint,
  efectivo bigint,
  transferencia bigint,
  ganancia_motorista bigint,
  debe_rendir bigint,
  entrego bigint,
  diferencia bigint,
  diferencia_transferencia bigint,
  estado text,
  motivo text,
  cierre_id uuid,
  cierre_estado text,
  fecha_confirmacion timestamptz,
  detalle jsonb
)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE v_empresa uuid;
BEGIN
  IF p_fecha IS NULL THEN RAISE EXCEPTION 'Seleccioná una fecha válida'; END IF;
  SELECT u.empresa_id INTO v_empresa
    FROM public.flota_usuarios u
    WHERE u.usuario_id = auth.uid() AND u.activo
      AND (u.rol = 'propietario' OR u.puede_finanzas)
    LIMIT 1;
  IF v_empresa IS NULL THEN RAISE EXCEPTION 'Solo Central autorizada puede consultar las rendiciones'; END IF;

  RETURN QUERY
  WITH base AS (
    SELECT d.id, d.nombre, d.modalidad_liquidacion AS modalidad,
      coalesce(pc.total,0)::bigint AS pedidos,
      coalesce(pc.ok,0)::bigint AS entregados,
      coalesce(pc.rej,0)::bigint AS rechazados,
      coalesce(pc.abiertos,0)::bigint AS pendientes,
      coalesce(pc.manana,0)::bigint AS pasa_manana,
      coalesce(pc.sin_movimiento,0)::bigint AS sin_movimiento,
      coalesce(pc.fecha_distinta,0)::bigint AS fecha_distinta,
      coalesce(mv.ef,0)::bigint AS ef,
      coalesce(mv.tr,0)::bigint AS tr,
      coalesce(mv.ganancia,0)::bigint AS ganancia,
      coalesce(mv.duplicados,0)::bigint AS duplicados,
      ci.id AS cierre_id, ci.estado AS cierre_estado,
      ci.confirmed_at,
      EXISTS(SELECT 1 FROM public.flota_usuarios confirmador
        WHERE confirmador.usuario_id=ci.confirmado_por
          AND confirmador.empresa_id=v_empresa
          AND (confirmador.rol='propietario' OR confirmador.puede_confirmar_rendiciones)) AS validado_central,
      ci.a_rendir_esperado,
      ci.efectivo_recibido, ci.diferencia AS cierre_diferencia,
      ci.diferencia_transferencia AS cierre_diferencia_transferencia,
      coalesce(pd.detalle,'[]'::jsonb) AS detalle
    FROM public.motoristas d
    LEFT JOIN LATERAL (
      SELECT count(*) AS total,
        count(*) FILTER (WHERE p.estado='entregado') AS ok,
        count(*) FILTER (WHERE p.estado='rechazado') AS rej,
        count(*) FILTER (WHERE p.estado NOT IN ('entregado','rechazado','cancelado')) AS abiertos,
        count(*) FILTER (WHERE p.estado='pasa_manana') AS manana,
        count(*) FILTER (WHERE p.estado='entregado' AND NOT EXISTS
          (SELECT 1 FROM public.movimientos_financieros m WHERE m.pedido_id=p.id AND m.empresa_id=v_empresa AND m.motorista_id=d.id)) AS sin_movimiento,
        count(*) FILTER (WHERE EXISTS
          (SELECT 1 FROM public.movimientos_financieros m WHERE m.pedido_id=p.id AND m.empresa_id=v_empresa AND m.motorista_id=d.id AND (m.created_at AT TIME ZONE 'America/Asuncion')::date <> p_fecha)) AS fecha_distinta
      FROM public.pedidos p
      LEFT JOIN public.rutas_generales rt ON rt.id=p.ruta_general_id AND rt.empresa_id=v_empresa
      WHERE p.empresa_id=v_empresa AND p.motorista_id=d.id
        AND coalesce(rt.fecha,(p.created_at AT TIME ZONE 'America/Asuncion')::date)=p_fecha
    ) pc ON true
    LEFT JOIN LATERAL (
      SELECT coalesce(sum(m.efectivo_cobrado),0)::bigint AS ef,
             coalesce(sum(m.transferencia_cobrada),0)::bigint AS tr,
             coalesce(sum(m.comision_motorista),0)::bigint AS ganancia,
             (SELECT count(*) FROM (
               SELECT m2.pedido_id
               FROM public.movimientos_financieros m2
               WHERE m2.empresa_id=v_empresa AND m2.motorista_id=d.id
                 AND (m2.created_at AT TIME ZONE 'America/Asuncion')::date=p_fecha
               GROUP BY m2.pedido_id HAVING count(*)>1
             ) dup)::bigint AS duplicados
      FROM public.movimientos_financieros m
      WHERE m.empresa_id=v_empresa AND m.motorista_id=d.id
        AND (m.created_at AT TIME ZONE 'America/Asuncion')::date=p_fecha
    ) mv ON true
    LEFT JOIN LATERAL (
      SELECT c.* FROM public.flota_cierres_motoristas c
      WHERE c.empresa_id=v_empresa AND c.motorista_id=d.id AND c.fecha=p_fecha
      ORDER BY c.created_at DESC,c.id DESC LIMIT 1
    ) ci ON true
    LEFT JOIN LATERAL (
      SELECT coalesce(jsonb_agg(jsonb_build_object(
        'pedido_id',p.id,'numero',p.numero_general,'cliente',p.nombre_cliente,
        'tienda',coalesce(t.codigo,t.nombre_comercial,'—'),
        'turno',p.turno,'estado',p.estado,'modalidad_pago',p.modalidad_pago,
        'precio_mercaderia',p.precio_mercaderia,'precio_delivery',p.precio_delivery,
        'efectivo',coalesce(mm.ef,0),'transferencia',coalesce(mm.tr,0),
        'ganancia',coalesce(mm.ganancia,0),'movimientos',coalesce(mm.cantidad,0),
        'cobros_otra_fecha',coalesce(mm.otras_fechas,0),
        'sin_movimiento',p.estado='entregado' AND coalesce(mm.todos_movimientos,0)=0
      ) ORDER BY p.numero_general NULLS LAST,p.created_at,p.id),'[]'::jsonb) AS detalle
      FROM public.pedidos p
      LEFT JOIN public.rutas_generales rt ON rt.id=p.ruta_general_id AND rt.empresa_id=v_empresa
      LEFT JOIN public.tiendas t ON t.id=p.tienda_id AND t.empresa_id=v_empresa
      LEFT JOIN LATERAL (
        SELECT sum(CASE WHEN (m.created_at AT TIME ZONE 'America/Asuncion')::date=p_fecha THEN m.efectivo_cobrado ELSE 0 END)::bigint AS ef,
          sum(CASE WHEN (m.created_at AT TIME ZONE 'America/Asuncion')::date=p_fecha THEN m.transferencia_cobrada ELSE 0 END)::bigint AS tr,
          sum(CASE WHEN (m.created_at AT TIME ZONE 'America/Asuncion')::date=p_fecha THEN m.comision_motorista ELSE 0 END)::bigint AS ganancia,
          count(*) FILTER (WHERE (m.created_at AT TIME ZONE 'America/Asuncion')::date=p_fecha) AS cantidad,
          count(*) FILTER (WHERE (m.created_at AT TIME ZONE 'America/Asuncion')::date<>p_fecha) AS otras_fechas,
          count(*) AS todos_movimientos
        FROM public.movimientos_financieros m WHERE m.pedido_id=p.id AND m.empresa_id=v_empresa AND m.motorista_id=d.id
      ) mm ON true
      WHERE p.empresa_id=v_empresa AND p.motorista_id=d.id
        AND coalesce(rt.fecha,(p.created_at AT TIME ZONE 'America/Asuncion')::date)=p_fecha
    ) pd ON true
    WHERE d.empresa_id=v_empresa
  ),
  calculado AS (
    SELECT b.*,
      CASE WHEN b.cierre_id IS NOT NULL THEN b.a_rendir_esperado::bigint
           WHEN b.modalidad='retener_comision' THEN greatest(0::bigint,b.ef-least(b.ef,b.ganancia))
           ELSE b.ef END AS esperado
    FROM base b
    WHERE b.pedidos>0 OR b.ef<>0 OR b.tr<>0 OR b.cierre_id IS NOT NULL
  )
  SELECT
    c.id, c.nombre::text, c.modalidad::text,
    c.pedidos,c.entregados,c.rechazados,c.pendientes,c.pasa_manana,
    c.ef,c.tr,c.ganancia,c.esperado,
    CASE WHEN (c.confirmed_at IS NOT NULL AND c.validado_central) THEN c.efectivo_recibido::bigint END,
    CASE WHEN (c.confirmed_at IS NOT NULL AND c.validado_central) THEN (c.efectivo_recibido-c.esperado)::bigint END,
    CASE WHEN (c.confirmed_at IS NOT NULL AND c.validado_central) THEN c.cierre_diferencia_transferencia::bigint END,
    CASE WHEN c.duplicados>0 OR c.sin_movimiento>0
         OR ((c.confirmed_at IS NOT NULL AND c.validado_central) AND (c.efectivo_recibido IS DISTINCT FROM c.esperado
            OR coalesce(c.cierre_diferencia_transferencia,0)<>0))
         THEN 'rojo'
         WHEN c.pendientes>0 OR c.confirmed_at IS NULL OR NOT c.validado_central OR c.cierre_estado<>'confirmada'
           OR c.fecha_distinta>0 THEN 'amarillo'
         ELSE 'verde' END::text,
    concat_ws(' · ',
      CASE WHEN c.sin_movimiento>0 THEN c.sin_movimiento||' entregado(s) sin movimiento' END,
      CASE WHEN c.duplicados>0 THEN c.duplicados||' movimiento(s) duplicado(s)' END,
      CASE WHEN c.pendientes>0 THEN c.pendientes||' pedido(s) sin resolver' END,
      CASE WHEN c.fecha_distinta>0 THEN c.fecha_distinta||' pedido(s) con cobro de otra fecha' END,
      CASE WHEN c.cierre_id IS NULL THEN 'Caja sin presentar' END,
      CASE WHEN c.cierre_id IS NOT NULL AND (c.confirmed_at IS NULL OR NOT c.validado_central) THEN 'Caja declarada, recepción de Central sin confirmar' END,
      CASE WHEN (c.confirmed_at IS NOT NULL AND c.validado_central) AND c.efectivo_recibido IS DISTINCT FROM c.esperado THEN 'Efectivo diferente al esperado' END,
      CASE WHEN (c.confirmed_at IS NOT NULL AND c.validado_central) AND coalesce(c.cierre_diferencia_transferencia,0)<>0 THEN 'Transferencia sin conciliar' END,
      CASE WHEN (c.confirmed_at IS NOT NULL AND c.validado_central) AND c.cierre_estado='confirmada'
        AND c.pendientes=0 AND c.sin_movimiento=0 AND c.duplicados=0 AND c.fecha_distinta=0
        AND c.efectivo_recibido=c.esperado AND coalesce(c.cierre_diferencia_transferencia,0)=0
        THEN 'Caja conciliada' END
    )::text,
    c.cierre_id,c.cierre_estado,CASE WHEN c.validado_central THEN c.confirmed_at END,c.detalle
  FROM calculado c ORDER BY
    CASE WHEN c.duplicados>0 OR c.sin_movimiento>0 OR
      ((c.confirmed_at IS NOT NULL AND c.validado_central) AND (c.efectivo_recibido IS DISTINCT FROM c.esperado OR coalesce(c.cierre_diferencia_transferencia,0)<>0))
      THEN 0 WHEN c.pendientes>0 OR c.confirmed_at IS NULL OR NOT c.validado_central OR c.cierre_estado<>'confirmada' OR c.fecha_distinta>0 THEN 1 ELSE 2 END,
    c.esperado DESC,c.nombre;
END;
$function$;

-- El rol autenticado puede invocar la RPC, pero la función verifica autorización
-- explícita en flota_usuarios y limita todas las filas a su propia empresa.
REVOKE ALL ON FUNCTION public.flota_resumen_rendicion_motoristas(date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.flota_resumen_rendicion_motoristas(date) TO authenticated;
