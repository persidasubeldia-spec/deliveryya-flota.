-- Pruebas automáticas del ciclo DeliveryYa Flota (datos sintéticos)
\set ON_ERROR_STOP 0
\set ADMIN '''a0000000-0000-0000-0000-000000000001'''
-- Atajos de IDs
create or replace function t.p(n int) returns uuid language sql immutable as $$select ('10000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid$$;
create or replace function t.hoy() returns date language sql stable as $$select (now() at time zone 'America/Asuncion')::date$$;
grant execute on all functions in schema t to authenticated, anon;

-- ===== A. Aislamiento entre tiendas =====
do $$declare n int; e text; begin
 perform t.login(null);
 e:=t.err('select count(*) from public.pedidos'); begin select count(*) into n from public.pedidos; exception when others then n:=0; end;
 perform t.check('A1 anon no ve pedidos', n=0, coalesce(e,n::text));
 perform t.login('b1000000-0000-0000-0000-000000000001');
 select count(*) into n from public.pedidos where tienda_id='f3000000-0000-0000-0000-000000000001'; perform t.check('A2 T1 no ve pedidos de T3', n=0, n::text);
 select count(*) into n from public.pedidos where tienda_id='f1000000-0000-0000-0000-000000000001'; perform t.check('A3 T1 ve sus pedidos', n>0, n::text);
 update public.pedidos set precio_delivery=1 where tienda_id='f3000000-0000-0000-0000-000000000001'; get diagnostics n=row_count;
 perform t.check('A4 T1 no modifica pedidos de T3', n=0, n::text);
 e:=t.err(format('select public.tienda_agregar_pedido_a_ruta(%L,%L)', t.p(2),'manana')); perform t.check('A5 T1 no agrega a ruta pedido de T3', e is not null, e);
 e:=t.err($q$insert into public.pedidos(empresa_id,tienda_id,nombre_cliente,telefono_cliente,direccion_cliente,modalidad_pago,precio_mercaderia,precio_delivery) values ('e0000000-0000-0000-0000-000000000001','f3000000-0000-0000-0000-000000000001','x','1','x','pendiente',1,1)$q$);
 perform t.check('A6 T1 no crea pedidos a nombre de T3', e is not null, e);
 select count(*) into n from public.movimientos_financieros; perform t.check('A7 T1 no lee caja de flota', n=0, n::text);
 perform t.login('d0000000-0000-0000-0000-000000000001');
 select count(*) into n from public.pedidos; perform t.check('A8 usuario ajeno no ve pedidos', n=0, n::text);
 e:=t.err(format('select public.flota_asignar_lote(array[%L]::uuid[],%L)', t.p(1),'90000000-0000-0000-0000-000000000001')); perform t.check('A9 usuario ajeno no reparte', e is not null, e);
 perform t.login('b1000000-0000-0000-0000-000000000002');
 e:=t.err($q$insert into public.pedidos(empresa_id,tienda_id,nombre_cliente,telefono_cliente,direccion_cliente,modalidad_pago,precio_mercaderia,precio_delivery,lat,lng) values ('e0000000-0000-0000-0000-000000000001','f1000000-0000-0000-0000-000000000001','Emp','1','x','pendiente',1,1,-25.3,-57.6)$q$);
 perform t.check('A10 empleada crea pedido en su tienda', e is null, e);
end$$;

-- ===== B. F1: pedidos en ruta vieja sin turno (día anterior) =====
do $$declare r uuid; n int; legacy uuid:='20000000-0000-0000-0000-000000000099'; begin
 insert into public.rutas_generales(id,empresa_id,fecha,estado,version_optimizacion,turno) values (legacy,'e0000000-0000-0000-0000-000000000001',t.hoy()-1,'abierta',0,null);
 update public.pedidos set ruta_general_id=legacy, turno='manana' where id in (t.p(1),t.p(3));
 update public.pedidos set ruta_general_id=legacy, turno='tarde' where id=t.p(21);
 perform t.login('a0000000-0000-0000-0000-000000000001');
 r:=public.flota_crear_ruta_turno(t.hoy(),'manana');
 n:=public.flota_reorganizar_pendientes_heredados(t.hoy(),'manana');
 perform t.check('B1 Preparar Mañana rescata los 2 pedidos de la ruta vieja de ayer', n=2, n::text);
 perform t.check('B2 el de Tarde no se mueve a Mañana', (select ruta_general_id from public.pedidos where id=t.p(21)) is distinct from r, null);
 perform public.flota_crear_ruta_turno(t.hoy(),'tarde');
 n:=public.flota_reorganizar_pendientes_heredados(t.hoy(),'tarde');
 perform t.check('B3 Preparar Tarde rescata el de Tarde y cierra la ruta vieja vacía', n=1 and (select estado from public.rutas_generales where id=legacy)='cerrada', n::text);
 perform t.check('B4 rescate queda auditado', (select count(*) from public.pedidos_ediciones where pedido_id in (t.p(1),t.p(3),t.p(21)))=3, null);
end$$;

-- ===== C. Tienda agrega a ruta =====
do $$declare r1 uuid; r2 uuid; e text; begin
 perform t.login('b1000000-0000-0000-0000-000000000001');
 r1:=public.tienda_agregar_pedido_a_ruta(t.p(5),'manana');
 perform public.tienda_agregar_pedido_a_ruta(x,'manana') from unnest(array[t.p(7),t.p(9),t.p(11),t.p(13),t.p(15),t.p(19)]) x;
 r2:=public.tienda_agregar_pedido_a_ruta(t.p(9),'manana');
 perform t.check('C1 repetir Agregar a ruta es idempotente', r1=r2, null);
 perform t.check('C2 pedido queda con turno y ruta', (select turno='manana' and ruta_general_id=r1 and numero_general is null from public.pedidos where id=t.p(5)), null);
 e:=t.err(format('select public.tienda_agregar_pedido_a_ruta(%L,%L)', t.p(17),'noche')); perform t.check('C3 turno inválido rechazado', e is not null, e);
 perform t.login('b3000000-0000-0000-0000-000000000001');
 perform public.tienda_agregar_pedido_a_ruta(t.p(2),'tarde');
 perform t.login('a0000000-0000-0000-0000-000000000001');
 perform t.check('C4 pedido de T3 en Tarde va a ruta de Tarde', (select r.turno from public.pedidos p join public.rutas_generales r on r.id=p.ruta_general_id where p.id=t.p(2))='tarde', null);
end$$;

-- ===== D. Central confirma ruta Mañana =====
do $$declare r uuid; ids uuid[]; e text; n int; begin
 perform t.login('a0000000-0000-0000-0000-000000000001');
 r:=public.flota_crear_ruta_turno(t.hoy(),'manana');
 select array_agg(id order by lat) into ids from public.pedidos where ruta_general_id=r;
 e:=t.err(format('select public.admin_confirmar_ruta_optimizada(%L,%L::uuid[])', r, ids[2:]));
 perform t.check('D1 no confirma si falta un pedido preparado', e is not null, e);
 perform public.admin_confirmar_ruta_optimizada(r, ids);
 select count(*) into n from public.pedidos where ruta_general_id=r and numero_general between 1 and array_length(ids,1);
 perform t.check('D2 numeración 1..N consecutiva', n=array_length(ids,1) and (select count(distinct numero_general) from public.pedidos where ruta_general_id=r)=n, n::text);
 perform public.admin_confirmar_ruta_optimizada(r, ids);
 perform t.check('D3 reconfirmar antes de repartir mantiene 1..N', (select max(numero_general) from public.pedidos where ruta_general_id=r)=array_length(ids,1), null);
end$$;

-- ===== E. Pedido tardío con ruta ya confirmada =====
do $$declare e text; r uuid; begin
 perform t.login('b1000000-0000-0000-0000-000000000001');
 e:=t.err(format('select public.tienda_agregar_pedido_a_ruta(%L,%L)', t.p(17),'manana'));
 perform t.check('E1 pedido tardío Mañana: sin error técnico de duplicado', e is null or e not ilike '%duplicate%', e);
 perform t.check('E2 pedido tardío queda en Mañana para revisión de Central', (select turno='manana' and requiere_revisar_ruta and ruta_general_id is null from public.pedidos where id=t.p(17)), null);
 e:=t.err(format('select public.tienda_agregar_pedido_a_ruta(%L,%L)', t.p(17),'manana'));
 perform t.check('E3 reintento del pedido tardío no da error', e is null, e);
 perform t.login('a0000000-0000-0000-0000-000000000001');
 select id into r from public.rutas_generales where fecha=t.hoy() and turno='manana' and estado<>'cerrada';
 perform public.flota_anexar_pedidos_a_ruta(r, array[t.p(17)]);
 perform t.check('E4 Central lo suma al final (N+1) sin renumerar', (select numero_general from public.pedidos where id=t.p(17))=(select count(*) from public.pedidos where ruta_general_id=r) and (select numero_general from public.pedidos where id=t.p(5)) is not null, null);
 e:=t.err(format('select public.flota_anexar_pedidos_a_ruta(%L,array[%L]::uuid[])', r, t.p(2)));
 perform t.check('E5 no anexa pedidos de otro turno', e is not null, e);
end$$;

-- ===== F. Reparto =====
do $$declare r uuid; e text; n int; begin
 perform t.login('a0000000-0000-0000-0000-000000000002'); -- operador
 r:=public.flota_crear_ruta_turno(t.hoy(),'manana');
 n:=public.flota_asignar_lote(array[t.p(5),t.p(7),t.p(9),t.p(19)],'90000000-0000-0000-0000-000000000001');
 perform t.check('F1 operador asigna lote a Moto Uno', n=4, n::text);
 e:=t.err(format('select public.flota_asignar_lote(array[%L]::uuid[],%L)', t.p(5),'90000000-0000-0000-0000-000000000002'));
 perform t.check('F2 no se reasigna pedido ya asignado', e is not null, e);
 e:=t.err(format('select public.flota_asignar_lote(array[%L,%L]::uuid[],%L)', t.p(11),t.p(2),'90000000-0000-0000-0000-000000000002'));
 perform t.check('F3 lote con pedido de otra ruta/turno se rechaza entero', e is not null and (select motorista_id from public.pedidos where id=t.p(11)) is null, e);
 perform public.flota_asignar_lote(array[t.p(11),t.p(13),t.p(15)],'90000000-0000-0000-0000-000000000002');
 perform t.check('F4 comisión de Moto Dos fijada 30/70', (select porcentaje_empresa_pct=30 and porcentaje_motorista_pct=70 from public.pedidos where id=t.p(13)), null);
 perform t.check('F5 numero_general intacto al repartir', (select numero_general is not null from public.pedidos where id=t.p(13)), null);
end$$;

-- ===== G. Motorista ve solo lo suyo y registra =====
do $$declare n int; e text; m record; ok boolean; begin
 perform t.login('c0000000-0000-0000-0000-000000000001');
 select count(*) into n from public.pedidos where motorista_id is distinct from '90000000-0000-0000-0000-000000000001'; perform t.check('G1 moto solo ve sus pedidos', n=0, n::text);
 e:=t.err(format('select public.motorista_cerrar_entrega(%L,%L,%L,null)', t.p(9),'pagado_previo','entregado'));
 perform t.check('G2 no acepta "ya pagado" en pedido a cobrar', e is not null, e);
 perform public.motorista_cerrar_entrega(t.p(5),'pagado_previo','entregado',null);  -- todo_pagado
 perform public.motorista_cerrar_entrega(t.p(7),'efectivo','entregado',null);       -- producto_pagado
 perform public.motorista_cerrar_entrega(t.p(9),'transferencia','entregado',null);  -- pendiente
 select * into m from public.movimientos_financieros where pedido_id=t.p(5);
 perform t.check('G3 todo pagado: no entra dinero', m.efectivo_cobrado=0 and m.transferencia_cobrada=0, row(m.efectivo_cobrado,m.transferencia_cobrada)::text);
 select * into m from public.movimientos_financieros where pedido_id=t.p(7);
 perform t.check('G4 producto pagado: solo envío 25.000', m.efectivo_cobrado=25000 and m.transferencia_cobrada=0, row(m.efectivo_cobrado,m.transferencia_cobrada)::text);
 perform t.check('G5 comisión 25%: empresa 6.250 / moto 18.750', m.comision_empresa=6250 and m.comision_motorista=18750, row(m.comision_empresa,m.comision_motorista)::text);
 select * into m from public.movimientos_financieros where pedido_id=t.p(9);
 perform t.check('G6 pendiente: mercadería+envío por transferencia', m.transferencia_cobrada=109000+25000 and m.efectivo_cobrado=0, row(m.efectivo_cobrado,m.transferencia_cobrada)::text);
 select count(*) into n from public.movimientos_financieros where pedido_id in (t.p(5),t.p(7),t.p(9)); perform t.check('G7 un movimiento por pedido', n=3, n::text);
 e:=t.err(format('select public.motorista_cerrar_entrega(%L,%L,%L,null)', t.p(7),'efectivo','entregado'));
 perform t.check('G8 no se puede cobrar dos veces', e is not null, e);

 -- F2: atajo de estado
 perform t.login('c0000000-0000-0000-0000-000000000002');
 begin
   perform public.motorista_actualizar_estado_pedido(t.p(15),'90000000-0000-0000-0000-000000000002','entregado','pagado_previo',null);
   ok:=false; raise exception 'deshacer';
 exception when others then ok:= (sqlerrm<>'deshacer'); end;
 perform t.check('G9 F2: incidencias no permiten marcar Entregado sin cobro', ok, null);

 perform public.motorista_actualizar_estado_pedido(t.p(13),'90000000-0000-0000-0000-000000000002','no_responde',null,'No atiende');
 perform public.motorista_cerrar_entrega(t.p(13),'efectivo','entregado',null);
 select * into m from public.movimientos_financieros where pedido_id=t.p(13);
 perform t.check('G10 entrega tras "No responde" registra cobro', m.efectivo_cobrado=25000 and m.comision_empresa=7500, row(m.efectivo_cobrado,m.comision_empresa)::text);
 perform public.motorista_registrar_rechazo_detallado(t.p(11),'Cliente rechazó','cliente',15000,'efectivo');
 select * into m from public.movimientos_financieros where pedido_id=t.p(11);
 perform t.check('G11 rechazo cobra solo lo recibido (15.000 < 20.000)', m.efectivo_cobrado=15000, m.efectivo_cobrado::text);
 perform t.check('G12 rechazo deja saldo 10.000 pendiente', (select importe_pendiente from public.flota_rechazos_detalle where pedido_id=t.p(11))=10000, null);
 perform public.motorista_cerrar_entrega(t.p(15),'efectivo','entregado',null);
end$$;

-- ===== H. Caja y rendición directa (sin confirmación del jefe) =====
do $$declare c1 uuid; c2 uuid; e text; v record; j record; begin
 perform t.login('c0000000-0000-0000-0000-000000000001');
 select * into j from public.motorista_contacto_jefe();
 perform t.check('H0 la moto obtiene el WhatsApp de su empresa', j.empresa='Flota Prueba', coalesce(j.empresa,'(nada)'));
 c1:=public.motorista_presentar_cierre(t.hoy(),25000,134000);
 select * into v from public.flota_cierres_motoristas where id=c1;
 perform t.check('H1 Moto Uno: a rendir 25.000 y cierre directo CONFIRMADO al cuadrar', v.a_rendir_esperado=25000 and v.transferencia_registrada=134000 and v.estado='confirmada' and v.diferencia=0, row(v.a_rendir_esperado,v.transferencia_registrada,v.estado)::text);
 e:=t.err(format('select public.motorista_cerrar_entrega(%L,%L,%L,null)', t.p(19),'efectivo','entregado'));
 perform t.check('H2 tras rendir no se aceptan cobros del día', e is not null, e);
 e:=t.err(format('select public.motorista_presentar_cierre(%L,0,0)', t.hoy()));
 perform t.check('H3 no hay doble cierre del día', e is not null, e);
 perform t.login('c0000000-0000-0000-0000-000000000002');
 c2:=public.motorista_presentar_cierre(t.hoy(),140000,0);
 select * into v from public.flota_cierres_motoristas where id=c2;
 perform t.check('H4 Moto Dos (retiene comisión): a rendir 145.000; entrega 140.000 → DIFERENCIA -5.000', v.efectivo_esperado=180000 and v.a_rendir_esperado=145000 and v.estado='diferencia' and v.diferencia=-5000, row(v.efectivo_esperado,v.a_rendir_esperado,v.estado,v.diferencia)::text);
 e:=t.err(format('select public.flota_confirmar_cierre_completo(%L,145000,0)', c2));
 perform t.check('H5 la moto no puede corregir su propia caja', e is not null, e);
 perform t.login('a0000000-0000-0000-0000-000000000002');
 e:=t.err(format('select public.flota_confirmar_cierre_completo(%L,145000,0)', c2));
 perform t.check('H6 operador sin permiso financiero no corrige', e is not null, e);
 perform t.login('a0000000-0000-0000-0000-000000000001');
 perform public.flota_confirmar_cierre_completo(c2,145000,0);
 perform t.check('H7 el jefe puede corregir una diferencia (opcional)', (select estado from public.flota_cierres_motoristas where id=c2)='confirmada', null);
 e:=t.err(format('select public.flota_confirmar_cierre_completo(%L,1,1)', c1));
 perform t.check('H8 una rendición confirmada no se vuelve a tocar', e is not null, e);
end$$;

-- ===== I. Cierre de ruta =====
do $$declare e text; r uuid; begin
 perform t.login('a0000000-0000-0000-0000-000000000001');
 select id into r from public.rutas_generales where fecha=t.hoy() and turno='manana' and estado<>'cerrada';
 e:=t.err(format('select public.flota_cerrar_ruta(%L)', r));
 perform t.check('I1 no cierra ruta con pedidos sin resolver', e is not null, e);
end$$;

-- ===== J. Limpieza y endurecimiento =====
do $$declare e text; begin
 perform t.login('a0000000-0000-0000-0000-000000000001');
 e:=t.err(format('select public.admin_asignar_pedido_motorista(%L,%L,1)', t.p(23),'90000000-0000-0000-0000-000000000001'));
 perform t.check('J1 ya no existe la asignación manual sin ruta', e is not null, e);
 e:=t.err(format('select public.flota_crear_ruta(%L)', t.hoy()));
 perform t.check('J2 ya no se pueden crear rutas sin turno', e is not null, e);
 perform t.login(null);
 e:=t.err('select count(*) from public.tiendas');
 perform t.check('J3 sin sesión no hay acceso directo a tablas', e is not null, e);
end$$;

select case when ok then 'OK   ' else 'FALLA' end || ' ' || name || coalesce('  → '||detail,'') from t.results order by id;
select format('%s aprobadas / %s fallidas', count(*) filter(where ok), count(*) filter(where not ok)) from t.results;
