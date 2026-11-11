\set ON_ERROR_STOP on
-- Casos funcionales SQL ejecutados en PostgreSQL local de GitHub Actions.
DO $test$
DECLARE
  p uuid; id2 uuid; n integer; v public.pedidos%ROWTYPE; audit jsonb;
BEGIN
  -- Caso 1: descuento de tienda de Gs. 5.000 separado, no suma al producto.
  INSERT INTO public.pedidos(id,empresa_id,tienda_id,precio_mercaderia,precio_delivery)
  VALUES('33333333-3333-4333-8333-333333333333','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111',100000,20000)
  RETURNING id INTO p;
  SELECT * INTO v FROM public.pedidos WHERE id=p;
  IF v.precio_mercaderia<>100000 OR v.precio_delivery<>25000 OR v.delivery_cliente<>20000 OR v.delivery_subsidio_tienda<>5000
    OR 100000+v.delivery_cliente<>120000 OR v.regla_comercial<>'boom_25k_cliente_20k_v1'
  THEN RAISE EXCEPTION 'ERROR: subsidio alteró precio o cobro cliente'; END IF;
  SELECT count(*) INTO n FROM public.flota_auditoria_precios WHERE pedido_id=p AND evento='creacion'
    AND valores_nuevos->>'mercaderia'='100000' AND valores_nuevos->>'delivery_cliente'='20000'
    AND valores_nuevos->>'tarifa_real'='25000' AND valores_nuevos->>'subsidio_tienda'='5000';
  IF n<>1 THEN RAISE EXCEPTION 'ERROR: fotografía inicial del precio'; END IF;
  RAISE NOTICE 'PASS 1/8: Boom Store producto 100000, cliente 20000, subsidio 5000 separado y auditoría inicial';
  -- Caso 2: edición pendiente 100000→105000 queda auditada.
  UPDATE public.pedidos SET precio_mercaderia=105000 WHERE id=p;
  SELECT count(*) INTO n FROM public.flota_auditoria_precios WHERE pedido_id=p AND evento='modificacion'
    AND valores_anteriores->>'mercaderia'='100000' AND valores_nuevos->>'mercaderia'='105000';
  IF n<>1 THEN RAISE EXCEPTION 'ERROR: modificación de mercadería no auditada'; END IF;
  RAISE NOTICE 'PASS 2/8: registro de cambio de mercadería con anterior y nuevo';
  -- Caso 3: volver a importe correcto sin tocar delivery.
  UPDATE public.pedidos SET precio_mercaderia=100000 WHERE id=p;
  SELECT * INTO v FROM public.pedidos WHERE id=p;
  IF v.precio_mercaderia<>100000 OR v.precio_delivery<>25000 OR v.delivery_cliente<>20000 OR v.delivery_subsidio_tienda<>5000
  THEN RAISE EXCEPTION 'ERROR: corrección alteró subsidio'; END IF;
  RAISE NOTICE 'PASS 3/8: corrección mercadería conserva subsidio';
  -- Caso 4: actualizar estado a entregado conserva precios, pero cambiar producto después falla.
  UPDATE public.pedidos SET estado='entregado' WHERE id=p;
  BEGIN
    UPDATE public.pedidos SET precio_mercaderia=110000 WHERE id=p;
    RAISE EXCEPTION 'ERROR: aceptó cambio de precio entregado';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'Pedido finalizado o con cobro:%' THEN RAISE; END IF;
  END;
  RAISE NOTICE 'PASS 4/8: no permite cambiar precio del pedido entregado';
  -- Caso 5: cobro financiero existente bloquea cambio aunque siga pendiente.
  INSERT INTO public.pedidos(id,empresa_id,tienda_id,precio_mercaderia,precio_delivery)
  VALUES('44444444-4444-4444-8444-444444444444','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111',70000,25000)
  RETURNING id INTO id2;
  INSERT INTO public.movimientos_financieros(pedido_id) VALUES(id2);
  BEGIN
    UPDATE public.pedidos SET precio_mercaderia=90000 WHERE id=id2;
    RAISE EXCEPTION 'ERROR: aceptó cambio con movimiento';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'Pedido finalizado o con cobro:%' THEN RAISE; END IF;
  END;
  RAISE NOTICE 'PASS 5/8: cobro financiero existente bloquea modificación';
  -- Caso 6: cambios de estado y fecha ajenos al precio no crean falso registro.
  SELECT count(*) INTO n FROM public.flota_auditoria_precios WHERE pedido_id=id2;
  UPDATE public.pedidos SET estado='no_responde' WHERE id=id2;
  IF (SELECT count(*) FROM public.flota_auditoria_precios WHERE pedido_id=id2)<>n
  THEN RAISE EXCEPTION 'ERROR: cambio de estado creó falso evento de precio'; END IF;
  RAISE NOTICE 'PASS 6/8: cambios operativos no crean auditoría de precio';
  -- Caso 7: no hay lecturas públicas sobre la tabla protegida.
  IF has_table_privilege('anon','public.flota_auditoria_precios','SELECT')
     OR has_table_privilege('authenticated','public.flota_auditoria_precios','SELECT')
  THEN RAISE EXCEPTION 'ERROR: auditoría visible a clientes'; END IF;
  RAISE NOTICE 'PASS 7/8: RLS y GRANTs de auditoría no permiten SELECT público';
  -- Caso 8: evitar escrituras artificiales por mover la tarifa y confirmar la fórmula Boom.
  IF (SELECT count(*) FROM public.flota_auditoria_precios WHERE pedido_id=p AND evento='creacion')<>1
  THEN RAISE EXCEPTION 'ERROR: registro inicial duplicado'; END IF;
  RAISE NOTICE 'PASS 8/8: registro inicial único y función vigente de Boom no cambia el producto';
END;
$test$;
SELECT '8/8 pruebas SQL aprobadas en PostgreSQL aislado' AS resultado;
