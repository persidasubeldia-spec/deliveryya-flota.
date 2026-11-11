import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
function fixture(date='2026-11-06',owner='m1'){
 const nodes=new Map();const el=id=>{if(!nodes.has(id))nodes.set(id,{innerHTML:'',classList:{toggle(){}},querySelectorAll(){return []},remove(){}});return nodes.get(id)};
 const d={id:'m1',nombre:'Notario',activo:true,telefono:'0981000000'};
 const orders=[1,2,3].map(i=>({id:'p'+i,nombre_cliente:'Cliente '+i,motorista_id:owner,estado:'pendiente',ruta_general_id:'r1',turno:'manana',numero_general:i,lat:-25.3,lng:-57.5}));
 const opened=[];const context={Date,Set,Map,Number,String,Math,console,orders,drivers:[d],routes:[{id:'r1',fecha:date}],stores:[],location:{origin:'https://deliveryya-flota.pages.dev'},document:{getElementById:id=>id==='content'?null:el(id)},$:el,setInterval(){},confirm(){return true},dyOrdenMotorista:xs=>xs,window:{addEventListener(){},open:url=>opened.push(url)}};
 vm.createContext(context);
 const html=fs.readFileSync(new URL('../central.html',import.meta.url),'utf8');
 const script=html.match(/<script id="dyDespachoJs">([\s\S]*?)<\/script>/)[1].replace('window.dyDespacho={st,refrescar,mejorar,cercania}','window.dyDespacho={st,refrescar,mejorar,cercania,barra,waUrl}');
 vm.runInContext(script,context);
 const api=context.window.dyDespacho;Object.assign(api.st,{fecha:date,turno:'manana',moto:'m1',sel:new Set(orders.map(o=>o.id))});
 api.barra(orders);return {api,el,opened,d,orders};
}
test('Ruta de mañana ya asignada: reconoce los 3 de Notario y habilita reenvío sin reasignar',()=>{
 const f=fixture();const html=f.el('dyBarra').innerHTML;
 assert.match(html,/3 de la moto seleccionada/);assert.doesNotMatch(html,/3 de otras motos/);
 assert.match(html,/id="dyDW"/);assert.ok(f.el('dyDW').onclick);
 f.el('dyDW').onclick();assert.equal(f.opened.length,1);
 const text=new URL(f.opened[0]).searchParams.get('text');assert.match(text,/tenés 3 entrega/);assert.match(text,/2026-11-06/);
 assert.ok(f.orders.every(o=>o.motorista_id==='m1'));
});
test('Pedidos de otra moto no se ofrecen como propios para reenviar',()=>{
 const f=fixture('2026-11-06','m2');assert.doesNotMatch(f.el('dyBarra').innerHTML,/id="dyDW"/);
});
test('El enlace de WhatsApp abre la fecha operativa, no siempre la ruta de hoy',()=>{
 const f=fixture();const text=new URL(f.api.waUrl(f.d)).searchParams.get('text');assert.match(text,/motorista\.html\?fecha=2026-11-06/);
});
