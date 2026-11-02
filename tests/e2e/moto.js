const {chromium,devices}=require('playwright');const fs=require('fs');
(async()=>{const b=await chromium.launch();const ctx=await b.newContext({...devices['iPhone 13']});const p=await ctx.newPage();const errs=[];p.on('pageerror',e=>errs.push(e.message));p.on('dialog',d=>{errs.push('DIALOGO NATIVO: '+d.message());d.dismiss()});
await p.route(/supabase-js|supabase\.min\.js/,r=>r.fulfill({contentType:'application/javascript',body:fs.readFileSync(__dirname+'/fake-supabase.js','utf8')}));
await p.route(/maps\.googleapis\.com/,r=>r.fulfill({contentType:'application/javascript',body:''}));
await p.goto('http://localhost:8765/motorista.html');await p.waitForTimeout(2500);
const res=[];const ok=(n,c,d)=>res.push((c?'OK    ':'FALLA ')+n+(d?' → '+d:''));
ok('M1 tarjetas visibles',await p.locator('[data-complete]').count()===3,String(await p.locator('[data-complete]').count()));
ok('M2 WhatsApp con prefijo 595',await p.locator('a[href*="wa.me/595971000001"]').count()===1);
// Entregado pedido a cobrar
await p.locator('[data-complete="p1"]').click();await p.screenshot({path:'/tmp/moto-entregado.png'});
ok('M3 panel Entregado ofrece efectivo y transferencia',await p.getByText('Cobré en efectivo ₲ 125.000').count()===1&&await p.getByText('Pagó por transferencia').count()===1);
await p.getByText('Cobré en efectivo').click();await p.waitForTimeout(400);
let last=await p.evaluate(()=>window.__rpc.at(-1));ok('M4 efectivo llama motorista_cerrar_entrega',last?.name==='motorista_cerrar_entrega'&&last.args.p_medio==='efectivo',JSON.stringify(last));
// Todo pagado
await p.locator('[data-complete="p2"]').click();ok('M5 todo pagado: solo opción ya pagado',await p.getByText('ya estaba pagado').count()===1&&await p.getByText('Cobré en efectivo').count()===0);
await p.getByText('ya estaba pagado').click();await p.waitForTimeout(300);last=await p.evaluate(()=>window.__rpc.at(-1));ok('M6 envía pagado_previo',last?.args?.p_medio==='pagado_previo');
// Rechazo con 15.000 en efectivo
await p.locator('[data-reject="p3"]').click();await p.getByText('Rechazó el producto').click();await p.getByText('El cliente pagó el envío').click();await p.locator('.dy-sh input[type=number]').fill('15000');await p.getByText('💵 Efectivo').click();await p.screenshot({path:'/tmp/moto-rechazo.png'});await p.getByText('Confirmar rechazo').click();await p.waitForTimeout(300);
last=await p.evaluate(()=>window.__rpc.at(-1));ok('M7 rechazo 15.000 efectivo responsable cliente',last?.name==='motorista_registrar_rechazo_detallado'&&last.args.p_importe===15000&&last.args.p_medio==='efectivo'&&last.args.p_responsable==='cliente',JSON.stringify(last?.args));
// Validación: rechazo sin motivo
await p.locator('[data-reject="p1"]').click();await p.getByText('Confirmar rechazo').click();ok('M8 rechazo exige motivo',await p.getByText('Elegí o escribí el motivo.').count()===1);await p.getByText('Cancelar').click();
// Incidencia
await p.locator('[data-incident="p1"]').click();await p.getByText('📵 No responde').click();await p.getByText('No atiende el teléfono').click();await p.screenshot({path:'/tmp/moto-incidencia.png'});await p.getByText('Guardar incidencia').click();await p.waitForTimeout(300);
last=await p.evaluate(()=>window.__rpc.at(-1));ok('M9 incidencia no_responde con motivo',last?.name==='motorista_actualizar_estado_pedido'&&last.args.p_nuevo_estado==='no_responde'&&last.args.p_motivo_incidencia==='No atiende el teléfono',JSON.stringify(last?.args));
ok('M10 pedido "No recibió" sigue con botones',await p.locator('[data-complete="p3"]').count()===1);
ok('M11 sin diálogos nativos ni errores JS',errs.length===0,errs.join(' | '));
console.log(res.join('\n'));await b.close()})();
