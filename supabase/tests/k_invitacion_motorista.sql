\set ON_ERROR_STOP 0
-- Datos: Freddy socio (perfil admin), dueña T1 (perfil tienda), una cuenta de otra empresa
reset role;
insert into auth.users(id,email,email_confirmed_at) values
 ('a0000000-0000-0000-0000-0000000000f1','freddy@test.local',now()),
 ('a0000000-0000-0000-0000-0000000000f2','otra@test.local',now()),
 ('a0000000-0000-0000-0000-0000000000f3','sinconfirmar@test.local',null);
update auth.users set email_confirmed_at=now() where id='b1000000-0000-0000-0000-000000000001';
insert into public.flota_usuarios(empresa_id,usuario_id,rol,activo,nombre) values('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-0000000000f1','socio',true,'Freddy');
insert into public.perfiles(id,empresa_id,rol,nombre) values('a0000000-0000-0000-0000-0000000000f1','e0000000-0000-0000-0000-000000000001','admin','Freddy');
insert into public.empresas(id,nombre,porcentaje_empresa_general) values('e0000000-0000-0000-0000-000000000002','Otra Flota',25);
insert into public.flota_usuarios(empresa_id,usuario_id,rol,activo,nombre) values('e0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-0000000000f2','propietario',true,'Otra');
insert into public.motoristas(id,empresa_id,nombre,telefono,email,activo,porcentaje_empresa_pct,modalidad_liquidacion) values
 ('90000000-0000-0000-0000-0000000000f1','e0000000-0000-0000-0000-000000000001','Freddy Fernández','0981000009','Freddy@Test.local',true,25,'rendir_todo'),
 ('90000000-0000-0000-0000-0000000000f2','e0000000-0000-0000-0000-000000000001','Dueña moto','0981000008','duena.t1@test.local',true,25,'rendir_todo'),
 ('90000000-0000-0000-0000-0000000000f3','e0000000-0000-0000-0000-000000000001','Otra moto','0981000007','otra@test.local',true,25,'rendir_todo'),
 ('90000000-0000-0000-0000-0000000000f4','e0000000-0000-0000-0000-000000000001','Sin confirmar','0981000006','sinconfirmar@test.local',true,25,'rendir_todo'),
 ('90000000-0000-0000-0000-0000000000f5','e0000000-0000-0000-0000-000000000001','Vencida','0981000005','freddy2@test.local',true,25,'rendir_todo');
create or replace function t.tok(c text) returns text language sql immutable as $$select repeat(c,48)$$;
insert into public.motorista_invitaciones(motorista_id,token_hash,vence_en) values
 ('90000000-0000-0000-0000-0000000000f1',encode(sha256(convert_to(t.tok('a'),'UTF8')),'hex'),now()+interval '1 day'),
 ('90000000-0000-0000-0000-0000000000f2',encode(sha256(convert_to(t.tok('b'),'UTF8')),'hex'),now()+interval '1 day'),
 ('90000000-0000-0000-0000-0000000000f3',encode(sha256(convert_to(t.tok('c'),'UTF8')),'hex'),now()+interval '1 day'),
 ('90000000-0000-0000-0000-0000000000f4',encode(sha256(convert_to(t.tok('d'),'UTF8')),'hex'),now()+interval '1 day'),
 ('90000000-0000-0000-0000-0000000000f1',encode(sha256(convert_to(t.tok('e'),'UTF8')),'hex'),now()-interval '1 day');
grant execute on all functions in schema t to authenticated, anon;
delete from t.results;
do $$declare e text; r text; n int; begin
 perform t.login('a0000000-0000-0000-0000-0000000000f1');
 e:=t.err(format('select public.motorista_aceptar_invitacion(%L)',t.tok('a')));
 perform t.check('K1 socio con perfil admin acepta invitación', e is null, e);
 reset role; select coalesce(usuario_id::text,'null') into r from public.motoristas where id='90000000-0000-0000-0000-0000000000f1';
 perform t.check('K2 ficha vinculada a Freddy', r='a0000000-0000-0000-0000-0000000000f1', r);
 select rol into r from public.perfiles where id='a0000000-0000-0000-0000-0000000000f1'; perform t.check('K3 perfil admin intacto', r='admin', r);
 select count(*) into n from public.flota_usuarios where usuario_id='a0000000-0000-0000-0000-0000000000f1' and activo and rol='socio'; perform t.check('K4 sigue siendo socio en Central', n=1, n::text);
 perform t.login('a0000000-0000-0000-0000-0000000000f1');
 e:=t.err(format('select public.motorista_aceptar_invitacion(%L)',t.tok('a'))); perform t.check('K5 reintento con el mismo enlace no falla', e is null, e);
 select count(*) into n from public.motoristas where usuario_id=auth.uid(); perform t.check('K6 como moto ve su ficha', n=1, n::text);
 e:=t.err(format('select public.motorista_aceptar_invitacion(%L)',t.tok('e'))); perform t.check('K7 enlace vencido de la propia ficha ya vinculada: éxito', e is null, e);
 perform t.login('b1000000-0000-0000-0000-000000000001');
 e:=t.err(format('select public.motorista_aceptar_invitacion(%L)',t.tok('b'))); perform t.check('K8 dueña de tienda misma empresa puede ser moto', e is null, e);
 perform t.login('a0000000-0000-0000-0000-0000000000f2');
 e:=t.err(format('select public.motorista_aceptar_invitacion(%L)',t.tok('c'))); perform t.check('K9 cuenta de otra empresa bloqueada', e like '%otra empresa%', e);
 perform t.login('a0000000-0000-0000-0000-0000000000f3');
 e:=t.err(format('select public.motorista_aceptar_invitacion(%L)',t.tok('d'))); perform t.check('K10 correo sin confirmar bloqueado', e like '%no verificado%', e);
 perform t.login('d0000000-0000-0000-0000-000000000001');
 e:=t.err(format('select public.motorista_aceptar_invitacion(%L)',t.tok('d'))); perform t.check('K11 otro correo no puede usar enlace ajeno', e like '%no verificado o incorrecto%', e);
 perform t.login(null);
 e:=t.err(format('select public.motorista_aceptar_invitacion(%L)',t.tok('d'))); perform t.check('K12 sin sesión bloqueado', e is not null, e);
end$$;
reset role;
select case when ok then 'OK    ' else 'FALLA ' end||name||coalesce('  → '||detail,'') from t.results order by name;
