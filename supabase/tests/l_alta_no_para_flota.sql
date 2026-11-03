\set ON_ERROR_STOP 0
reset role;
insert into public.empresas(id,nombre,porcentaje_empresa_general) values('a0000000-0000-0000-0000-000000000001','Flota Real (copia)',25) on conflict do nothing;
insert into auth.users(id,email,email_confirmed_at) values('a0000000-0000-0000-0000-00000000aa01','jefe.real@test.local',now()),('a0000000-0000-0000-0000-00000000bb01','tienda.nueva@test.local',now()),('a0000000-0000-0000-0000-00000000cc01','moto.real@test.local',now()),('a0000000-0000-0000-0000-00000000dd01','moto.tienda@test.local',now());
insert into public.flota_usuarios(empresa_id,usuario_id,rol,activo,nombre) values('a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-00000000aa01','propietario',true,'Jefe');
insert into public.perfiles(id,empresa_id,rol,nombre) values('a0000000-0000-0000-0000-00000000cc01','a0000000-0000-0000-0000-000000000001','tienda','Moto con perfil tienda (como Freddy)');
insert into public.motoristas(id,empresa_id,usuario_id,nombre,telefono,activo,porcentaje_empresa_pct,modalidad_liquidacion,email) values('90000000-0000-0000-0000-00000000cc01','a0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-00000000cc01','Moto Real','0981000000',true,25,'rendir_todo','moto.real@test.local');
delete from t.results;
do $$declare e text;n int;begin
 perform t.login('a0000000-0000-0000-0000-00000000aa01');
 e:=t.err('select public.flota_solicitar_alta_tienda_simple()');perform t.check('A1 Central NO recibe tienda automática',e ilike '%otro rol%',e);
 perform t.login('a0000000-0000-0000-0000-00000000cc01');
 e:=t.err('select public.flota_solicitar_alta_tienda_simple()');perform t.check('A2 Motorista NO recibe tienda automática',e ilike '%otro rol%',e);
 perform t.login('a0000000-0000-0000-0000-00000000bb01');
 e:=t.err('select public.flota_solicitar_alta_tienda_simple()');perform t.check('A3 cuenta nueva sí se activa',e is null,e);
 e:=t.err('select public.flota_solicitar_alta_tienda_simple()');perform t.check('A4 segunda vez devuelve la misma (idempotente)',e is null,e);
 reset role;select count(*) into n from public.tiendas where usuario_id in ('a0000000-0000-0000-0000-00000000aa01','a0000000-0000-0000-0000-00000000cc01');perform t.check('A5 no se creó ninguna tienda para Central/Moto',n=0,n::text);
end$$;
reset role;select string_agg(case when ok then 'OK   ' else 'FALLA' end||' '||name||coalesce(' — '||detail,''),E'\n' order by name) from t.results;
select count(*) filter(where ok)||'/'||count(*) from t.results;
