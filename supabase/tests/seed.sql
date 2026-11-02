-- Datos 100% sintéticos para pruebas. Nada de producción.
create schema if not exists t;
create table if not exists t.results(id serial, name text, ok boolean, detail text);
grant usage on schema t to authenticated, anon;
grant all on t.results to authenticated, anon;
grant usage, select on sequence t.results_id_seq to authenticated, anon;

create or replace function t.login(u uuid) returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claim.sub', coalesce(u::text,''), true);
  perform set_config('request.jwt.claim.role', case when u is null then 'anon' else 'authenticated' end, true);
  execute case when u is null then 'set local role anon' else 'set local role authenticated' end;
end $$;
create or replace function t.check(n text, ok boolean, d text default null) returns void language sql as $$
  insert into t.results(name, ok, detail) values (n, coalesce(ok,false), d) $$;
create or replace function t.err(sql text) returns text language plpgsql as $$
begin execute sql; return null; exception when others then return sqlerrm; end $$;
grant execute on all functions in schema t to authenticated, anon;

-- Usuarios
insert into auth.users(id,email) values
 ('a0000000-0000-0000-0000-000000000001','admin@test.local'),
 ('a0000000-0000-0000-0000-000000000002','operador@test.local'),
 ('b1000000-0000-0000-0000-000000000001','duena.t1@test.local'),
 ('b1000000-0000-0000-0000-000000000002','empleada.t1@test.local'),
 ('b3000000-0000-0000-0000-000000000001','duena.t3@test.local'),
 ('c0000000-0000-0000-0000-000000000001','moto1@test.local'),
 ('c0000000-0000-0000-0000-000000000002','moto2@test.local'),
 ('d0000000-0000-0000-0000-000000000001','extrano@test.local');

insert into public.empresas(id,nombre,porcentaje_empresa_general) values ('e0000000-0000-0000-0000-000000000001','Flota Prueba',25);
insert into public.flota_usuarios(empresa_id,usuario_id,rol,activo,puede_finanzas,puede_comisiones,puede_motoristas,puede_tiendas,puede_confirmar_rendiciones,nombre)
values ('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','propietario',true,true,true,true,true,true,'Admin'),
       ('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000002','operador',true,false,false,false,false,false,'Operador');

insert into public.perfiles(id,empresa_id,rol,nombre) values
 ('b1000000-0000-0000-0000-000000000001','e0000000-0000-0000-0000-000000000001','tienda','Dueña T1'),
 ('b3000000-0000-0000-0000-000000000001','e0000000-0000-0000-0000-000000000001','tienda','Dueña T3'),
 ('c0000000-0000-0000-0000-000000000001','e0000000-0000-0000-0000-000000000001','motorista','Moto Uno'),
 ('c0000000-0000-0000-0000-000000000002','e0000000-0000-0000-0000-000000000001','motorista','Moto Dos');
insert into public.tiendas(id,empresa_id,usuario_id,nombre_comercial,telefono,direccion,lat,lng,activo,codigo) values
 ('f1000000-0000-0000-0000-000000000001','e0000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000001','Tienda Uno','0981000001','Asunción',-25.2867,-57.6470,true,'T1'),
 ('f3000000-0000-0000-0000-000000000001','e0000000-0000-0000-0000-000000000001','b3000000-0000-0000-0000-000000000001','Tienda Tres','0981000003','Luque',-25.2700,-57.4870,true,'T3');
insert into public.tienda_miembros(tienda_id,usuario_id,rol,activo) values
 ('f1000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000001','propietario',true),
 ('f1000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000002','empleado',true),
 ('f3000000-0000-0000-0000-000000000001','b3000000-0000-0000-0000-000000000001','propietario',true)
on conflict do nothing;

insert into public.motoristas(id,empresa_id,usuario_id,nombre,telefono,color_identificador,activo,porcentaje_empresa_pct,modalidad_liquidacion,porcentaje_personalizado) values
 ('90000000-0000-0000-0000-000000000001','e0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001','Moto Uno','0982000001','#16A34A',true,25,'rendir_todo',false),
 ('90000000-0000-0000-0000-000000000002','e0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000002','Moto Dos','0982000002','#9333EA',true,30,'retener_comision',true);

-- Pedidos: 30, GPS del Gran Asunción, 3 modalidades, turnos variados
insert into public.pedidos(id,empresa_id,tienda_id,nombre_cliente,telefono_cliente,direccion_cliente,lat,lng,precio_mercaderia,precio_delivery,modalidad_pago,estado,turno,version_edicion)
select ('10000000-0000-0000-0000-'||lpad(g::text,12,'0'))::uuid,
 'e0000000-0000-0000-0000-000000000001',
 case when g%2=0 then 'f3000000-0000-0000-0000-000000000001'::uuid else 'f1000000-0000-0000-0000-000000000001'::uuid end,
 'Cliente '||g, '09710000'||lpad(g::text,2,'0'), 'Calle '||g,
 -25.25-(g%10)*0.012, -57.55-(g%7)*0.015,
 100000+g*1000, 25000,
 (array['pendiente','producto_pagado','todo_pagado'])[1+g%3],
 'pendiente', 'sin_definir', 0
from generate_series(1,30) g;
