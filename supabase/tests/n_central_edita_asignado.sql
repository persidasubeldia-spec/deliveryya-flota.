\set ON_ERROR_STOP 0
reset role;
insert into public.pedidos(id,empresa_id,tienda_id,nombre_cliente,telefono_cliente,direccion_cliente,lat,lng,precio_mercaderia,precio_delivery,modalidad_pago,estado,turno,version_edicion,motorista_id)
values('d0000000-0000-0000-0000-0000000000e1','e0000000-0000-0000-0000-000000000001','f1000000-0000-0000-0000-000000000001','Odilda','0981111111','Casa',-25.38,-57.38,120000,25000,'pendiente','pendiente','manana',1,'90000000-0000-0000-0000-000000000001'),
      ('d0000000-0000-0000-0000-0000000000e2','e0000000-0000-0000-0000-000000000001','f1000000-0000-0000-0000-000000000001','Con cobro','0981111112','Casa',-25.38,-57.38,100000,25000,'pendiente','pendiente','manana',1,'90000000-0000-0000-0000-000000000001');
delete from t.results;
do $$declare e text;r record;n int;begin
 perform t.login('a0000000-0000-0000-0000-000000000001');
 e:=t.err($q$select public.editar_pedido_seguro('d0000000-0000-0000-0000-0000000000e1',1,'{"precio_mercaderia":150000,"modalidad_pago":"producto_pagado","producto":"Blusa roja","direccion_cliente":"Nueva casa","lat":-25.40,"lng":-57.40,"observaciones":"Hasta las 19"}'::jsonb)$q$);
 perform t.check('P1 Central edita precio, cobro, producto y ubicación de un pedido ASIGNADO',e is null,e);
 reset role;select * into r from public.pedidos where id='d0000000-0000-0000-0000-0000000000e1';
 perform t.check('P2 quedó guardado y sigue con su moto',r.precio_mercaderia=150000 and r.modalidad_pago='producto_pagado' and r.producto='Blusa roja' and r.motorista_id='90000000-0000-0000-0000-000000000001' and r.version_edicion=2,r.precio_mercaderia||' '||r.producto);
 perform t.check('P3 sin ruta general no exige revisar recorrido (regla existente)',not r.requiere_revisar_ruta,'');
 select count(*) into n from public.pedidos_ediciones where pedido_id='d0000000-0000-0000-0000-0000000000e1';perform t.check('P4 cambio auditado en pedidos_ediciones',n=1,n::text);
 perform t.login('a0000000-0000-0000-0000-000000000001');
 e:=t.err($q$select public.editar_pedido_seguro('d0000000-0000-0000-0000-0000000000e1',1,'{"precio_mercaderia":1}'::jsonb)$q$);perform t.check('P5 versión vieja: rechazado (no pisa cambios)',e ilike '%cambió%',e);
 perform t.login('b1000000-0000-0000-0000-000000000001');
 e:=t.err($q$select public.editar_pedido_seguro('d0000000-0000-0000-0000-0000000000e1',2,'{"precio_mercaderia":1}'::jsonb)$q$);perform t.check('P6 la tienda NO cambia precio de un pedido asignado',e ilike '%no editable%',e);
 e:=t.err($q$select public.editar_pedido_seguro('d0000000-0000-0000-0000-0000000000e1',2,'{"observaciones":"Llamar antes"}'::jsonb)$q$);perform t.check('P7 la tienda sí cambia observaciones',e is null,e);
 perform t.login('c0000000-0000-0000-0000-000000000001');
 e:=t.err($q$select public.editar_pedido_seguro('d0000000-0000-0000-0000-0000000000e1',3,'{"precio_mercaderia":1}'::jsonb)$q$);perform t.check('P8 el motorista NO cambia precio',e ilike '%no editable%',e);
end$$;
reset role;select string_agg(case when ok then 'OK   ' else 'FALLA' end||' '||name||coalesce(' — '||detail,''),E'\n' order by name) from t.results;
select count(*) filter(where ok)||'/'||count(*) from t.results;
