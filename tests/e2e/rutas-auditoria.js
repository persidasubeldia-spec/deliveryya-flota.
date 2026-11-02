// Auditoría de los 15 controles de Central › Rutas según DOCUMENTACION_RUTAS_CENTRAL.md
const {chromium}=require('playwright');const fs=require('fs');const cp=require('child_process');
(async()=>{const b=await chromium.launch();const ctx=await b.newContext({viewport:{width:1500,height:950},geolocation:{latitude:-25.378,longitude:-57.43,accuracy:20},permissions:['geolocation']});const p=await ctx.newPage();
const errs=[],dialogs=[];p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>{if(d.type()==='alert')dialogs.push('alert: '+d.message().slice(0,90));d.accept()});
const prod=fs.readFileSync(__dirname+'/proddata.json','utf8');
await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:'window.__PROD='+prod+';'+fs.readFileSync(__dirname+'/fake-prod.js','utf8')}));
await p.route(/maps\.googleapis\.com/,r=>r.abort());
await p.route(/router\.project-osrm\.org/,r=>{const body=cp.execFileSync('curl',['-s','--max-time','40',r.request().url()]);r.fulfill({status:200,contentType:'application/json',headers:{'access-control-allow-origin':'*'},body})});
await p.goto('http://localhost:8765/central.html');await p.waitForTimeout(2000);await p.locator('#nav button',{hasText:'Rutas'}).click();await p.waitForTimeout(1500);
const R=[];const ok=(n,c,d)=>{R.push([n,c,d]);};const msg=async()=>(await p.locator('#routeMsg').innerText()).trim();const calls=async()=>(await p.evaluate(()=>window.__rpc.splice(0))).map(x=>x.n).filter(n=>!/solicitudes|comision/.test(n));const dlg=()=>dialogs.splice(0);
const sel=async()=>p.locator('#routeRows input[type=checkbox]:checked').count();
await calls();
// 1 Filtros
await p.locator('[data-shift-button="tarde"]').click();await p.waitForTimeout(400);const tarde=await p.locator('#routeRows .dispatch-stop').count();
await p.locator('[data-shift-button="manana"]').click();await p.waitForTimeout(400);const man=await p.locator('#routeRows .dispatch-stop').count();
ok('1 Filtros Mañana/Tarde filtran lista sin escribir',man===4&&tarde===2&&(await calls()).length===0,'mañana '+man+' / tarde '+tarde);
// 3 Preparar
await p.locator('#routeCreate').click();await p.waitForTimeout(1200);const c3=await calls();
ok('3 Preparar crea/reutiliza y rescata',c3.join()==='flota_crear_ruta_turno,flota_reorganizar_pendientes_heredados'&&/recuperados/.test(await msg()),await msg());
// 2 Ruta elegida
const rv=await p.locator('#routeChoice').inputValue();ok('2 Lista Ruta queda en la ruta del turno',rv==='r-manana',rv);
// 4 Organizar
await p.locator('#routeRequeue').click();await p.waitForTimeout(800);const c4=await calls();ok('4 Organizar pendientes antiguos',c4.includes('flota_reorganizar_pendientes_heredados')&&/turno Mañana/.test(await msg())&&!dlg().length,await msg());
// 5 Actualizar
await p.locator('#routeReload').click();await p.waitForTimeout(800);ok('5 Actualizar mapa relee y redibuja',/pedidos en lista/.test(await msg()),await msg());
// 7a Optimizar sin salida
await p.locator('#routeOrigin').fill('');await p.locator('#routeOptimize').click();await p.waitForTimeout(500);ok('7a Optimizar sin salida avisa qué falta',/Falta el punto de salida/.test(await msg())&&(await calls()).length===0,await msg());
// 6 Usar mi ubicación
await p.locator('#routeUseGps').click();await p.waitForTimeout(1200);ok('6 Usar mi ubicación carga el GPS',(await p.locator('#routeOrigin').inputValue()).startsWith('-25.378'),await p.locator('#routeOrigin').inputValue());
// 7 Optimizar
await p.locator('#routeOptimize').click();await p.waitForTimeout(9000);ok('7 Optimizar por calles sin guardar',/Mejor recorrido/.test(await msg())&&(await calls()).length===0&&await p.locator('#routeConfirm').isEnabled(),await msg());
// 8 Reiniciar
await p.locator('#routeResetBest').click();await p.waitForTimeout(400);ok('8 Reiniciar propuestas descarta sin guardar',/Ninguna ruta real fue modificada/.test(await msg())&&!(await p.locator('#routeConfirm').isEnabled())&&(await calls()).length===0,await msg());
// 9 Confirmar
await p.locator('#routeOptimize').click();await p.waitForTimeout(9000);await p.locator('#routeConfirm').click();await p.waitForTimeout(800);ok('9 Confirmar numera 1..N',(await calls()).includes('admin_confirmar_ruta_optimizada')&&/confirmado/i.test(await msg()),await msg());
// 10 Sumar al final (pedido nuevo de Mañana)
await p.evaluate(()=>{});const added=await p.evaluate(()=>{window.__PROD;return true});
await p.locator('#routeAppend').click();await p.waitForTimeout(800);await calls();ok('10a Sumar al final sin nuevos: avisa',/No hay pedidos nuevos/.test(await msg()),await msg());
await p.evaluate(()=>{const b=window.__PROD.pedidos[0];window.__PROD.pedidos.push({...b,id:'tardio-0000-4000-8000-000000000000',turno:'manana',ruta_general_id:null,numero_general:null,motorista_id:null,estado:'pendiente',lat:-25.40,lng:-57.42,requiere_revisar_ruta:true})});
await p.locator('#routeReload').click();await p.waitForTimeout(800);await p.locator('#routeAppend').click();await p.waitForTimeout(1200);const c10=await calls();
const nro=await p.evaluate(()=>window.__PROD.pedidos.find(x=>x.id.startsWith('tardio')).numero_general);
ok('10b Pedido tardío se suma como N.º 5 sin renumerar',c10.includes('flota_anexar_pedidos_a_ruta')&&nro===5&&/sumados/.test(await msg()),await msg()+' | N.º '+nro);
// 11 Tarjeta moto
await p.locator('[data-mode="repartir"]').click();await p.waitForTimeout(300);await p.locator('[data-quick-driver]').first().click();await p.waitForTimeout(300);ok('11 Tarjeta de moto la selecciona',/SELECCIONADO/.test(await p.locator('#driverQuickCards').innerText()),'');
// 12 Selección
await p.locator('#routeFrom').fill('1');await p.locator('#routeTo').fill('2');await p.locator('#routeRange').click();await p.waitForTimeout(300);const s1=await sel();
await p.locator('#routeClear').click();await p.waitForTimeout(300);const s0=await sel();
await p.locator('#routeVisible').click();await p.waitForTimeout(300);const sv=await sel();
await p.locator('#routeFrom').fill('5');await p.locator('#routeTo').fill('1');await p.locator('#routeRange').click();await p.waitForTimeout(300);const d12=dlg();
ok('12 Intervalo / Limpiar / Visibles / intervalo inválido',s1===2&&s0===0&&sv===5&&!d12.length&&/Intervalo incorrecto/.test(await msg()),'intervalo '+s1+', limpiar '+s0+', visibles '+sv+(d12.length?' | DIÁLOGO NATIVO: '+d12.join(' ; '):''));
// 13 Asignar
await p.locator('#routeAssign').click();await p.waitForTimeout(800);const c13=await calls();ok('13 Asignar lote',c13.includes('flota_asignar_lote')&&/asignados/.test(await msg()),await msg()+' | '+dlg().join(' ; '));
// 14 Avance
await p.locator('[data-mode="avance"]').click();await p.waitForTimeout(400);ok('14 Avance muestra asignados',(await p.locator('#routeRows .dispatch-stop').count())>=4,String(await p.locator('#routeRows .dispatch-stop').count()));
// 15 Cerrar ruta con pendientes
await p.locator('#routeClose').click();await p.waitForTimeout(800);const c15=await calls();ok('15 Cerrar ruta con pendientes se bloquea con motivo',c15.includes('flota_cerrar_ruta')&&/Quedan/.test(await msg()),await msg()+' | '+dlg().join(' ; '));
for(const [n,c,d] of R)console.log((c?'OK    ':'FALLA ')+n+(d?'  → '+String(d).slice(0,140):''));
console.log(errs.length?'ERRORES JS: '+errs.join(' | '):'Sin errores JS');await p.screenshot({path:'/tmp/auditoria-final.png'});await b.close()})();
