import fs from 'node:fs';
import vm from 'node:vm';
const files=['index.html','central.html','motorista.html','tienda-alta.html','reporte-tienda.html','simulacros.html'];
const expect={
 'central.html':['flota_registrar_motorista','flota_asignar_lote','admin_confirmar_ruta_optimizada','flota_confirmar_cierre_completo','flota_registrar_tienda','flota_crear_invitacion'],
 'motorista.html':['motorista_cerrar_entrega','motorista_presentar_cierre','motorista_guardar_orden','motorista_compartir_gps'],
 'tienda-alta.html':['flota_aceptar_tienda_propietaria'],
 'simulacros.html':['ver_simulacros_flotas'],
 'reporte-tienda.html':['movimientos_financieros']
};
let fails=0;
for(const file of files){
 if(!fs.existsSync(file)){console.error('FALTA',file);fails++;continue;}
 const html=fs.readFileSync(file,'utf8');
 const scripts=[...html.matchAll(/<script(?![^>]*src)[^>]*>([\s\S]*?)<\/script>/gi)].map(x=>x[1]);
 if(!scripts.length){console.error('SIN SCRIPT',file);fails++;continue;}
 for(let i=0;i<scripts.length;i++)try{new vm.Script(scripts[i],{filename:file+'#'+i})}catch(e){console.error('SINTAXIS',file,e.message);fails++}
 for(const fragment of expect[file]||[]){if(!html.includes(fragment)){console.error('FUNCIÓN AUSENTE',file,fragment);fails++}}
 console.log(file,html.length,'bytes',scripts.length,'script(s)');
}
if(fails){console.error('Falló smoke estático:',fails);process.exit(1)}
console.log('Smoke estático correcto. No equivale a prueba E2E.');
