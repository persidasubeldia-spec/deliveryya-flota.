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
  "barra(ps);dibujar(ps);st.firma=firma()",
  "st.sel.clear();st.fit=false;refrescar()",
  "https://deliveryya-flota.pages.dev/motorista.html"
 ])assert.ok(central.includes(token),'Falta '+token);
});
test('Motorista conserva entrega, rendición, GPS y fecha operativa real',()=>{
 for(const token of [
  "motorista_cerrar_entrega",
  "motorista_registrar_rechazo_detallado",
  "motorista_presentar_cierre",
  "motorista_guardar_recorrido",
  "motorista_recorrido_actual",
  "p_coordenadas:coordenadas",
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

test('Cerrar jornada del motorista solo sin pendientes y con recibo automático explícito',()=>{
 for(const token of [
  "b.disabled=!r.cierre&&abiertos>0",
  "if(!r.cierre&&pend){msg.textContent=",
  "Central registra automáticamente el dinero",
  "Cerrar tu jornada y dar el dinero declarado por recibido",
  "No se permite cerrar hasta terminarlos o reprogramarlos",
  "Jornada cerrada · dinero declarado recibido",
  "dyHojaEnvio(pdf,dyTextoRendicion(a,r,cierre),cierre)"
 ]) assert.ok(motorista.includes(token),'Protección de cierre ausente: '+token);
});

test('Motorista no modifica montos ya recibidos por Central',()=>{
 assert.ok(motorista.includes("&&!r.cierre.confirmed_at&&"),'No bloquear ajuste confirmado');
 assert.ok(motorista.includes("if(r.cierre?.confirmed_at)"),'No comprobar cierre previo a corrección');
});

test('Android valida sesión y permisos antes de abrir el panel de la tienda',()=>{
 assert.ok(acceso.includes("const {data,error}=await db.auth.getUser()"),'Falta comprobar credenciales vigentes');
 assert.ok(acceso.includes("if(!error&&data?.user)"),'Falta validar usuario');
 assert.ok(acceso.includes("if(permisosError)throw Error("),'Falta informar error al consultar permisos');
 assert.ok(acceso.includes("La sesión anterior venció"),'Falta recuperación de token caducado');
 assert.ok(!acceso.includes("if(s&&s.refresh_token)location.replace("),'No debe redirigir solo por token en localStorage');
});

test('Recuperación desde Tienda usa formulario específico',()=>{
 assert.ok(tienda.includes("resetPasswordForEmail(email,{redirectTo:location.origin+'/tienda-registro.html'})"),'Destino de recuperación incorrecto');
});

test('Rendición oficial separa motociclista, tienda y administración',()=>{
 for(const token of [
  "rdPdfMotoCentral","async function rdPdf(t,fecha)","rdPdfAdministracion",
  "flota_resumen_ajustes_tienda","flota_confirmar_compensacion_tienda",
  "flota_registrar_pago_tienda","rdAuditar(d)",
  "Rechazos pendientes (no descontados)","PROVISIONAL / NO LIQUIDADO",
  "Compensaciones de rechazo confirmadas (-)",
  "if(audit.errores.length)throw Error('Conciliación inconsistente:"
 ]) assert.ok(central.includes(token),'Falta norma de rendición: '+token);
 const tiendaPdf=central.slice(central.indexOf('async function rdPdf(t,fecha)'),central.indexOf('</script>',central.indexOf('async function rdPdf(t,fecha)')));
 for(const interno of ["Retiene motorista 75%","comision_empresa","comision_motorista","Porcentaje de ganancia","Entrega a central"]){
  assert.ok(!tiendaPdf.includes(interno),'No exponer '+interno+' en informe a tienda');
 }
});
