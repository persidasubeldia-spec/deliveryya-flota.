\set ON_ERROR_STOP 0
reset role;
insert into public.empresas(id,nombre,porcentaje_empresa_general) values('e0000000-0000-0000-0000-000000000009','Otra',25) on conflict do nothing;
insert into auth.users(id,email,email_confirmed_at) values('a0000000-0000-0000-0000-00000000e001','jefe.e@test.local',now()),('a0000000-0000-0000-0000-00000000e002','socio.sin@test.local',now()),('a0000000-0000-0000-0000-00000000e003','moto.e@test.local',now()),('a0000000-0000-0000-0000-00000000e004','otro.jefe@test.local',now());
insert into public.flota_usuarios(empresa_id,usuario_id,rol,activo,nombre) values('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-00000000e002','socio',true,'Socio sin permiso'),('e0000000-0000-0000-0000-000000000009','a0000000-0000-0000-0000-00000000e004','propietario',true,'Otro');
update public.flota_usuarios set puede_motoristas=false where usuario_id='a0000000-0000-0000-0000-00000000e002';
insert into public.perfiles(id,empresa_id,rol,nombre) values('a0000000-0000-0000-0000-00000000e003','e0000000-0000-0000-0000-000000000001','motorista','Moto V');
insert into public.motoristas(id,empresa_id,usuario_id,nombre,telefono,activo,porcentaje_empresa_pct,modalidad_liquidacion,email) values
('90000000-0000-0000-0000-00000000e001','e0000000-0000-0000-0000-000000000001',null,'Angel Mal','0982000000',true,25,'rendir_todo','mal@test.local'),
('90000000-0000-0000-0000-00000000e002','e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-00000000e003','Moto V','0982000001',true,25,'rendir_todo','moto.e@test.local');
delete from t.results;
do $$declare e text;r record;begin
 perform t.login('a0000000-0000-0000-0000-000000000001');
 e:=t.err($q$select public.flota_editar_motorista('90000000-0000-0000-0000-00000000e001','Angel Villalba','0982 462 467','  Angel.Bien@Test.local ')$q$);perform t.check('E1 jefe corrige nombre, teléfono y correo',e is null,e);
 reset role;select * into r from public.motoristas where id='90000000-0000-0000-0000-00000000e001';perform t.check('E2 queda guardado en minúscula y sin espacios',r.email='angel.bien@test.local' and r.nombre='Angel Villalba',r.email);
 perform t.login('a0000000-0000-0000-0000-000000000001');
 e:=t.err($q$select public.flota_editar_motorista('90000000-0000-0000-0000-00000000e002','Moto V2','0982000001','otro@test.local')$q$);perform t.check('E3 vinculado: no deja cambiar el correo',e ilike '%vinculada%',e);
 e:=t.err($q$select public.flota_editar_motorista('90000000-0000-0000-0000-00000000e002','Moto Vinculado','0982111222','moto.e@test.local')$q$);perform t.check('E4 vinculado: sí deja cambiar nombre y teléfono',e is null,e);
 e:=t.err($q$select public.flota_editar_motorista('90000000-0000-0000-0000-00000000e001','Angel Villalba','0982462467','moto.e@test.local')$q$);perform t.check('E5 correo repetido en otro motorista: rechazado',e ilike '%otro motorista%',e);
 e:=t.err($q$select public.flota_editar_motorista('90000000-0000-0000-0000-00000000e001','Al','0982462467','a@b.co')$q$);perform t.check('E6 nombre corto: rechazado',e is not null,e);
 e:=t.err($q$select public.flota_editar_motorista('90000000-0000-0000-0000-00000000e001','Angel Villalba','0982462467','sin-arroba')$q$);perform t.check('E7 correo inválido: rechazado',e is not null,e);
 perform t.login('a0000000-0000-0000-0000-00000000e002');
 e:=t.err($q$select public.flota_editar_motorista('90000000-0000-0000-0000-00000000e001','X Hacker','0982462467','x@test.local')$q$);perform t.check('E8 socio sin permiso de motoristas: rechazado',e ilike '%autorizado%',e);
 perform t.login('a0000000-0000-0000-0000-00000000e004');
 e:=t.err($q$select public.flota_editar_motorista('90000000-0000-0000-0000-00000000e001','X Hacker','0982462467','x@test.local')$q$);perform t.check('E9 jefe de otra empresa: rechazado',e ilike '%autorizado%',e);
 perform t.login('a0000000-0000-0000-0000-00000000e003');
 e:=t.err($q$select public.flota_editar_motorista('90000000-0000-0000-0000-00000000e001','X Hacker','0982462467','x@test.local')$q$);perform t.check('E10 un motorista no puede editar',e ilike '%autorizado%',e);
end$$;
reset role;select string_agg(case when ok then 'OK   ' else 'FALLA' end||' '||name||coalesce(' — '||detail,''),E'\n' order by name) from t.results;
select count(*) filter(where ok)||'/'||count(*) from t.results;
