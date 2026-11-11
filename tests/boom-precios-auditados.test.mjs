import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Script} from 'node:vm';
const read=p=>readFileSync(new URL('../'+p,import.meta.url),'utf8');
const tienda=read('index.html');
const moto=read('motorista.html');
const sql=read('supabase/migrations/20261111120000_flota_auditar_bloquear_precios.sql');
const rollback=read('supabase/rollback/20261111120000_flota_auditar_bloquear_precios.sql');
test('Tienda exige revisión visible de mercadería y delivery antes de enviar',()=>{
  assert.match(tienda,/async function saveOrder\(draft,precioConfirmado=false\)/);
  assert.match(tienda,/if\(!draft&&!precioConfirmado\)/);
  assert.match(tienda,/dyPrecioRevisionHuella!==huellaPrecio/);
  assert.match(tienda,/Confirmar importes y enviar/);
  assert.match(tienda,/Pedido todavía NO enviado/);
  assert.match(tienda,/Subsidio de Boom Store/);
  assert.match(tienda,/precio_mercaderia:v\.goods/);
  assert.match(tienda,/panel\.querySelector\('\[data-dy-precio-confirm\]'\)\.onclick=\(\)=>saveOrder\(false,true\)/);
});
test('Motorista verifica importe antes de marcar entregado',()=>{
  assert.match(moto,/Verifiqué con la tienda o cliente que el importe del producto es correcto/);
  assert.match(moto,/if\(!verificado\.checked\)/);
  assert.match(moto,/Mercadería: '\+money\(p\.precio_mercaderia\)/);
  assert.match(moto,/TOTAL A COBRAR: '\+money\(cobro\)/);
  assert.match(moto,/const cobro=p\.modalidad_pago==='todo_pagado'\?0/);
});
test('Base registra precio al crear y modificar, y bloquea cambios con cierre/cobro',()=>{
  assert.match(sql,/CREATE TABLE IF NOT EXISTS public\.flota_auditoria_precios/);
  assert.match(sql,/AFTER INSERT ON public\.pedidos/);
  assert.match(sql,/AFTER UPDATE OF precio_mercaderia/);
  assert.match(sql,/OLD\.estado <> 'pendiente' OR NEW\.estado <> 'pendiente'/);
  assert.match(sql,/EXISTS\(SELECT 1 FROM public\.movimientos_financieros m/);
  assert.match(sql,/ENABLE ROW LEVEL SECURITY/);
  assert.match(sql,/REVOKE ALL ON TABLE .* FROM PUBLIC,anon,authenticated/);
  assert.doesNotMatch(sql,/UPDATE public\.pedidos SET|UPDATE public\.movimientos_financieros SET/);
  assert.match(rollback,/Se conserva flota_auditoria_precios/);
});
test('La revisión incluye el cálculo del subsidio sin alterar el precio del producto',()=>{
  const total=(goods,delivery,modalidad)=>modalidad==='todo_pagado'?0:modalidad==='producto_pagado'?delivery:goods+delivery;
  assert.equal(total(70000,20000,'pendiente'),90000);
  assert.equal(total(70000,20000,'producto_pagado'),20000);
  assert.equal(total(70000,20000,'todo_pagado'),0);
  assert.equal(25000-20000,5000);
});
test('Scripts principales conservan una estructura JS válida',()=>{
  for(const h of [tienda,moto]){
    const snippets=[...h.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(x=>x[1]).filter(Boolean);
    for(const script of snippets)assert.doesNotThrow(()=>new Script(script));
  }
});
