import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Script,runInNewContext} from 'node:vm';

const file=p=>readFileSync(new URL('../'+p,import.meta.url),'utf8');
const html=file('central.html');
const sql=file('supabase/migrations/20261111110000_flota_resumen_rendicion_motoristas.sql');
const rollback=file('supabase/rollback/20261111110000_flota_resumen_rendicion_motoristas.sql');
const script=html.match(/<script id="dyRendicionMotoristasJs">([\s\S]*?)<\/script>/)?.[1];

test('Panel de rendición en su propio script válido',()=>{
 assert.ok(script);
 assert.doesNotThrow(()=>new Script(script));
 const window={};runInNewContext(script,{window,Date,Number,String,Math,Array});
 assert.equal(typeof window.dyRendicionPanel,'function');
 assert.equal(typeof window.dyRendPendientes,'function');
 assert.ok(html.includes("Rendición por motorista"));
 assert.ok(html.includes('id="dyRmPendientesResumen"'));
 assert.match(html,/max-width:650px/);
 assert.ok(html.includes("data-rm-detail"));
});

test('RPC de solo lectura autorizada para Central',()=>{
 assert.match(sql,/CREATE OR REPLACE FUNCTION public\.flota_resumen_rendicion_motoristas\(p_fecha date\)/);
 assert.match(sql,/auth\.uid\(\)/);
 assert.match(sql,/u\.rol = 'propietario' OR u\.puede_finanzas/);
 assert.match(sql,/d\.empresa_id=v_empresa/);
 assert.match(sql,/REVOKE ALL ON FUNCTION .* FROM PUBLIC, anon/);
 assert.match(sql,/GRANT EXECUTE ON FUNCTION .* TO authenticated/);
 assert.doesNotMatch(sql,/\b(?:INSERT\s+INTO|UPDATE\s+public\.|DELETE\s+FROM)\b/i);
 assert.ok(rollback.includes('DROP FUNCTION IF EXISTS'));
});

test('Una sola caja por día con mañana y tarde',()=>{
 assert.match(sql,/coalesce\(rt\.fecha,\(p\.created_at AT TIME ZONE 'America\/Asuncion'\)::date\)=p_fecha/);
 assert.doesNotMatch(sql,/WHERE p\.turno='manana'/);
 assert.doesNotMatch(sql,/WHERE p\.turno='tarde'/);
 assert.match(sql,/m\.comision_motorista/);
 assert.match(sql,/ci\.a_rendir_esperado/);
 assert.match(sql,/greatest\(0::bigint,b\.ef-least\(b\.ef,b\.ganancia\)\)/);
 assert.match(sql,/c\.confirmed_at IS NOT NULL AND c\.validado_central/);
 assert.match(sql,/confirmador\.usuario_id=ci\.confirmado_por/);
 assert.match(sql,/CASE WHEN c\.cierre_id IS NOT NULL AND \(c\.confirmed_at IS NULL OR NOT c\.validado_central\)/);
 assert.match(sql,/sin_movimiento/);
 assert.match(sql,/duplicados/);
});

test('Registro de recepción real usa cierre existente y permisos fuertes',()=>{
 const confirmacion=file('supabase/migrations/20261111111000_flota_confirmar_recepcion_caja.sql');
 const rev=file('supabase/rollback/20261111111000_flota_confirmar_recepcion_caja.sql');
 assert.match(confirmacion,/CREATE OR REPLACE FUNCTION public\.flota_confirmar_recepcion_caja/);
 assert.match(confirmacion,/u\.rol='propietario' OR u\.puede_confirmar_rendiciones/);
 assert.match(confirmacion,/UPDATE public\.flota_cierres_motoristas SET/);
 assert.match(confirmacion,/Caja ya recibida por Central/);
 assert.match(confirmacion,/RETURN true; -- Reintento idéntico/);
 assert.match(rev,/DROP FUNCTION IF EXISTS public\.flota_confirmar_recepcion_caja/);
 assert.match(script,/flota_confirmar_recepcion_caja/);
 assert.match(script,/Registrar dinero recibido/);
 assert.match(script,/Completá ambos importes/);
});

test('Interfaz no confunde dinero confirmado con caja sin rendir',()=>{
 assert.match(script,/Transferencias/);
 assert.match(script,/DEBE RENDIR AL JEFE/);
 assert.match(script,/entrego===null/);
 assert.match(script,/debe_rendir-r\.entrego/);
 assert.match(script,/Sin confirmar/);
 assert.match(script,/Ir a rendición y PDF/);
});
