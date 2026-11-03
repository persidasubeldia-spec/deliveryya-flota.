import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const read = path => readFileSync(new URL('../'+path,import.meta.url),'utf8');
const central=read('central.html');
const motorista=read('motorista.html');
const tienda=read('index.html');
const acceso=read('app.html');
const cloudflare=read('cloudflare-live-proxy.js');

test('Todos los scripts inline de Central, Motorista, Tienda y acceso tienen sintaxis válida',()=>{
 for(const [nombre,html] of [['central',central],['motorista',motorista],['tienda',tienda],['acceso',acceso]]){
  const blocks=[...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)].map(m=>m[1].trim()).filter(Boolean);
  assert.ok(blocks.length>0, nombre+' debe tener scripts');
  blocks.forEach((script,i)=>assert.doesNotThrow(()=>new Function(script),nombre+' script #'+i));
 }
});
test('Central conserva asignación segura, fecha operativa y filtros sincronizados',()=>{
 for(const token of [
  "flota_asignar_lote",
  "admin_confirmar_ruta_optimizada",
  "fechaOperativa(o)",
  "function visiblesTurno()",
  "barra(ps);dibujar(vistos);st.firma=firma()",
  "st.sel.clear();st.fit=false;refrescar()",
  "https://deliveryya-flota.pages.dev/motorista.html"
 ])assert.ok(central.includes(token),'Falta '+token);
});
test('Motorista conserva entrega, rendición, GPS y fecha operativa real',()=>{
 for(const token of [
  "motorista_cerrar_entrega",
  "motorista_registrar_rechazo_detallado",
  "motorista_presentar_cierre",
  "motorista_guardar_orden",
  "getCurrentPosition(resolve,reject",
  "const pedidosJornada=(data||[]).filter(p=>fechaPedido(p)===hoyOperativo)",
  "_fecha_operativa:fechaPedido(p)",
  "p._fecha_operativa&&p._fecha_operativa!==dyHoyAsu()"
 ])assert.ok(motorista.includes(token),'Falta '+token);
});
test('Tienda conserva carga, ruta, ubicación y controles de empleados',()=>{
 for(const token of ["saveOrder(draft)","tienda_agregar_pedido_a_ruta","/api/resolve-map","revocar_empleado_tienda"]){
  assert.ok(tienda.includes(token),'Falta '+token);
 }
});
test('Acceso Android mantiene tres roles y sesión compartida',()=>{
 for(const token of ["dyf-auth","/motorista","/central","Mi tienda","persistSession:true"])assert.ok(acceso.includes(token),'Falta '+token);
});
test('Proxy Cloudflare conserva páginas Android y resolución segura de Maps',()=>{
 for(const token of ["'/api/resolve-map'","resolveGoogleMapLink(request)","env.ASSETS.fetch(request)","deliveryya-flota-persida.vercel.app","maps.app.goo.gl","https:"]){
  assert.ok(cloudflare.includes(token),'Falta '+token);
 }
 assert.doesNotThrow(()=>new Function(cloudflare.replace('export default','const worker =')));
});
