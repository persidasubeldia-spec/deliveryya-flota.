import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const h=readFileSync(new URL('../central.html',import.meta.url),'utf8');
const start=h.indexOf('function dyPuenteFinanciero('),end=h.indexOf('async function mostrarDia()',start);
assert.ok(start>=0&&end>start);
const puente=new Function(h.slice(start,end)+'return dyPuenteFinanciero;')();
test('11/11 Boom: recaudación 1.860.000 y ganancia prevista 115.000',()=>{
 const p=puente(1860000,0,370000,1375000,108750,6250);
 assert.deepEqual(p,{recaudo:1860000,rendir:1490000,diferencia:115000,previsto:115000,cuadra:true});
});
test('Diferencia de 13.750 no cuadra: alertar, no dar por confirmado',()=>{
 const p=puente(1860000,0,370000,1361250,108750,6250);
 assert.equal(p.diferencia,128750);assert.equal(p.cuadra,false);
});
test('Rechazo pendiente se muestra aparte sin engordar entregas',()=>{
 assert.match(h,/const gananciaDiaBruta=entregasRegistradasDia/);
 assert.match(h,/const gananciaRechazosPorConciliar=rechazosDeTiendaPendientes/);
 assert.match(h,/const gananciaPrevistaConRechazos=gananciaDiaBruta\+gananciaRechazosPorConciliar/);
 assert.match(h,/Comisión por rechazos pendientes de conciliar/);
 assert.match(h,/Ganancia total PREVISTA del día/);
 assert.match(h,/NO es efectivo recibido en Central/);
});
test('Diferencia entre rendiciones de moto y tienda se explica y se prueba',()=>{
 assert.match(h,/const puenteCuadra=todosMotosRetienen&&puente.cuadra/);
 assert.match(h,/Conciliación aritmética/);
 assert.match(h,/Diferencia teórica a favor de Flota/);
 assert.match(h,/Existen motoristas con otra modalidad de liquidación/);
});
test('Acumulado histórico sigue separado y excluye rechazos',()=>{
 assert.match(h,/Acumulado bruto de entregas · todas las fechas \(sin rechazos\)/);
 assert.match(h,/cajaEmpresaBruta=historicasEntregadas.reduce/);
});
