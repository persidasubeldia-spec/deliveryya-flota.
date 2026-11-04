import fs from 'node:fs';
import vm from 'node:vm';
const files=['index.html','app.html','central.html','motorista.html','tienda-alta.html','tienda-registro.html','reporte-tienda.html'];
const expect={
 'index.html':['tienda_agregar_pedido_a_ruta','p_turno:turno','routeId:p.ruta_general_id','turno:p.turno','requiere_revisar_ruta'],
 'central.html':['flota_crear_ruta_turno','flota_reorganizar_pendientes_heredados','routeRequeue','selectedShift','shiftMatch','flota_registrar_motorista','flota_asignar_lote','admin_confirmar_ruta_optimizada','flota_confirmar_cierre_completo','flota_registrar_tienda','flota_crear_invitacion','flota_anexar_pedidos_a_ruta'],
 'motorista.html':['numero_general,turno','motorista_cerrar_entrega','motorista_presentar_cierre','motorista_guardar_recorrido','motorista_compartir_gps','motorista_registrar_rechazo_detallado'],
 'app.html':['dyf-auth-app','flota_usuarios','tienda_miembros'],
 'tienda-alta.html':['flota_aceptar_tienda_propietaria'],
 'tienda-registro.html':['flota_solicitar_alta_tienda_simple'],
 'reporte-tienda.html':['movimientos_financieros']
};
// Cosas que NO deben volver a aparecer en el frontend publicado.
const forbidden=[
 [/service_role/i,'clave service_role en el cliente'],
 [/eyJhbGciOi[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/,'JWT incrustado (posible clave secreta)'],
 [/vercel/i,'referencia a Vercel (no se usa)'],
 [/admin_asignar_pedido_motorista|cerrar_caja_motorista|flota_crear_ruta'/,'RPC eliminada u obsoleta'],
 [/\/api\/icon/,'ícono dinámico de Vercel (usar icon-192.png / icon-512.png)'],
 [/console\.log\([^)]*(telefono|nombre_cliente|direccion)/i,'console.log con datos personales']
];
let fails=0;
for(const file of files){
 if(!fs.existsSync(file)){console.error('FALTA',file);fails++;continue;}
 const html=fs.readFileSync(file,'utf8');
 const scripts=[...html.matchAll(/<script(?![^>]*src)[^>]*>([\s\S]*?)<\/script>/gi)].map(x=>x[1]);
 if(!scripts.length){console.error('SIN SCRIPT',file);fails++;continue;}
 for(let i=0;i<scripts.length;i++)try{new vm.Script(scripts[i],{filename:file+'#'+i})}catch(e){console.error('SINTAXIS',file,e.message);fails++}
 for(const fragment of expect[file]||[]){if(!html.includes(fragment)){console.error('FUNCIÓN AUSENTE',file,fragment);fails++}}
 const code=html.replace(/(^|\s)\/\/[^\n]*/g,'$1').replace(/\/\*[\s\S]*?\*\//g,'');
 for(const [re,why] of forbidden){if(re.test(code)){console.error('PROHIBIDO',file,why);fails++}}
 console.log(file,html.length,'bytes',scripts.length,'script(s)');
}
for(const f of ['manifest.webmanifest','sw.js','functions/api/resolve-map.js','icon-192.png','icon-512.png']){if(!fs.existsSync(f)){console.error('FALTA',f);fails++}}
try{const m=JSON.parse(fs.readFileSync('manifest.webmanifest','utf8'));for(const i of m.icons||[]){if(!fs.existsSync('.'+i.src)){console.error('ÍCONO INEXISTENTE',i.src);fails++}}}catch(e){console.error('MANIFEST INVÁLIDO',e.message);fails++}
if(fails){console.error('Falló smoke estático:',fails);process.exit(1)}
console.log('Smoke estático correcto. No equivale a prueba E2E.');
