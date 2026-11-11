\set ON_ERROR_STOP on
DO $checks$
DECLARE p uuid;v public.pedidos%ROWTYPE;n integer;
BEGIN
  -- 1/8: la tienda ingresó 20k, Supabase conserva tarifa interna 25k.
  INSERT INTO public.pedidos(id,empresa_id,tienda_id,precio_mercaderia,precio_mercaderia_cargado_tienda,precio_delivery,precio_delivery_cargado_tienda)
  VALUES('55555555-5555-4555-8555-555555555555','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111',100000,100000,25000,20000) RETURNING id INTO p;
  SELECT * INTO v FROM public.pedidos WHERE id=p;
  IF v.precio_delivery<>25000 OR v.precio_delivery_cargado_tienda<>20000 OR v.delivery_cliente<>20000 OR v.delivery_subsidio_tienda<>5000 THEN
    RAISE EXCEPTION 'FAIL 1: precio original cambió por el subsidio'; END IF;
  RAISE NOTICE 'PASS 1/8: 20000 ingresados por tienda no se sustituyen por 25000 internos';
  -- 2/8: mercadería inicial preservada.
  IF v.precio_mercaderia_cargado_tienda<>100000 THEN RAISE EXCEPTION 'FAIL 2';END IF;
  RAISE NOTICE 'PASS 2/8: mercadería original conservada';
  -- 3/8: nueva edición de mercadería no reescribe original.
  UPDATE public.pedidos SET precio_mercaderia=105000 WHERE id=p;
  SELECT * INTO v FROM public.pedidos WHERE id=p;
  IF v.precio_mercaderia<>105000 OR v.precio_mercaderia_cargado_tienda<>100000 THEN RAISE EXCEPTION 'FAIL 3';END IF;
  RAISE NOTICE 'PASS 3/8: modificación posterior conserva mercadería original';
  -- 4/8: intento de reescribir valor inicial es rechazado.
  BEGIN
   UPDATE public.pedidos SET precio_delivery_cargado_tienda=25000 WHERE id=p;
   RAISE EXCEPTION 'FAIL 4: aceptó mutación';
  EXCEPTION WHEN OTHERS THEN
   IF SQLERRM NOT LIKE 'Los importes originales cargados por la tienda no se pueden modificar.%' THEN RAISE;END IF;
  END;
  RAISE NOTICE 'PASS 4/8: original inmutable';
  -- 5/8: histórico sin dato original permanece NULL (sin backfill falso).
  INSERT INTO public.pedidos(id,empresa_id,tienda_id,precio_mercaderia,precio_delivery)
  VALUES('66666666-6666-4666-8666-666666666666','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111',70000,25000);
  SELECT precio_delivery_cargado_tienda INTO v.precio_delivery_cargado_tienda
  FROM public.pedidos WHERE id='66666666-6666-4666-8666-666666666666';
  IF v.precio_delivery_cargado_tienda IS NOT NULL THEN RAISE EXCEPTION 'FAIL 5';END IF;
  RAISE NOTICE 'PASS 5/8: histórico se etiqueta no registrado';
  -- 6/8: entrada inconsistente contra precio final se rechaza.
  BEGIN
   INSERT INTO public.pedidos(id,empresa_id,tienda_id,precio_mercaderia,precio_mercaderia_cargado_tienda,precio_delivery,precio_delivery_cargado_tienda)
   VALUES('77777777-7777-4777-8777-777777777777','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111',100000,80000,25000,20000);
   RAISE EXCEPTION 'FAIL 6: aceptó precio falso';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'Precio original de mercadería inconsistente%' THEN RAISE;END IF;
  END;
  RAISE NOTICE 'PASS 6/8: inconsistencia de mercadería bloqueada';
  -- 7/8: otras tiendas sin subsidio: tarifa inicial = tarifa interna.
  INSERT INTO public.pedidos(id,empresa_id,tienda_id,precio_mercaderia,precio_mercaderia_cargado_tienda,precio_delivery,precio_delivery_cargado_tienda)
  VALUES('88888888-8888-4888-8888-888888888888','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','22222222-2222-4222-8222-222222222222',50000,50000,30000,30000);
  IF NOT EXISTS(SELECT 1 FROM public.pedidos WHERE id='88888888-8888-4888-8888-888888888888' AND precio_delivery_cargado_tienda=30000 AND precio_delivery=30000)
  THEN RAISE EXCEPTION 'FAIL 7'; END IF;
  RAISE NOTICE 'PASS 7/8: tienda sin regla especial preserva original';
  -- 8/8: no se pueden atribuir falsos originales a registros históricos.
  BEGIN
    UPDATE public.pedidos SET precio_delivery_cargado_tienda=20000 WHERE id='66666666-6666-4666-8666-666666666666';
    RAISE EXCEPTION 'FAIL 8: permitió backfill no auditado';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE 'Los importes originales cargados por la tienda no se pueden modificar.%' THEN RAISE;END IF;
  END;
  RAISE NOTICE 'PASS 8/8: no se inventan originales históricos';
END;
$checks$;
SELECT '8/8 pruebas de importes originales aprobadas' AS resultado;
