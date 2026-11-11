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
  "st.sel.clear();st.fit=false;pintar()",
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
  "const pedidosJornada=(data||[]).filter(p=>fechaPedido(p)===fechaVista)",
  "const pedidosHoy=(data||[]).filter(p=>fechaPedido(p)===hoyOperativo)",
  "else dyPintarCaja(aHoy)",
  "const fechaVista=dyFechaRutaSeleccionada||hoyOperativo",
  "dyActualizarCalendarioMoto()",
  "dy-cal-readonly",
  "_fecha_operativa:fechaPedido(p)",
  "p._fecha_operativa&&p._fecha_operativa!==dyHoyAsu()"
 ])assert.ok(motorista.includes(token),'Falta '+token);
});
test('Tienda conserva carga, ruta, ubicación y controles de empleados',()=>{
 for(const token of ["saveOrder(draft,precioConfirmado=false)","tienda_agregar_pedido_a_ruta","/api/resolve-map","revocar_empleado_tienda"]){
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
  "Rechazos descontados directamente","PROVISIONAL / NO LIQUIDADO",
  "Compensaciones de rechazo confirmadas (-)",
  "if(audit.errores.length)throw Error('Conciliación inconsistente:"
 ]) assert.ok(central.includes(token),'Falta norma de rendición: '+token);
 const tiendaPdf=central.slice(central.indexOf('async function rdPdf(t,fecha)'),central.indexOf('</script>',central.indexOf('async function rdPdf(t,fecha)')));
 for(const interno of ["Retiene motorista 75%","comision_empresa","comision_motorista","Porcentaje de ganancia","Entrega a central"]){
  assert.ok(!tiendaPdf.includes(interno),'No exponer '+interno+' en informe a tienda');
 }
});

test('Finanzas no cuenta rechazos impagos como comisiones realizadas',()=>{
 assert.ok(central.includes("const entregasCobradas=mComercial.filter(mv=>x.porPedido.get(mv.pedido_id)?.estado==='entregado'"));
 assert.ok(central.includes("const pendientesRechazo=mComercial.filter(mv=>mv.es_rechazo_facturable"));
 assert.ok(central.includes("cobrada('comision_empresa')"));
 assert.ok(central.includes("cobrada('comision_motorista')"));
 assert.ok(central.includes("detalleMovimiento(entregasCobradas,'empresa')"));
 assert.ok(central.includes("detalleMovimiento(entregasCobradas,'motos')"));
});

test('Rechazos de tienda se descuentan automáticamente sin duplicar compensaciones',()=>{
 assert.ok(central.includes("t.neto=t.merc-t.debe-t.cargosPendientes-t.compensado;"));
 assert.ok(central.includes("!d.compensaciones.some(c=>c.pedido_id===p.id)"));
 assert.ok(central.includes("Rechazos a cargo de tienda descontados (-)"));
 assert.ok(central.includes("Rechazos descontados directamente"));
});

test('Pasa mañana traslada inmediatamente y muestra procedencia en Central',()=>{
 assert.ok(motorista.includes("sb.rpc('motorista_pasar_pedido_manana'"),'Motorista debe llamar RPC de reprogramación');
 assert.ok(motorista.includes('p_version:p.version_edicion'),'Debe enviar versión para evitar dobles traslados');
 assert.ok(motorista.includes('Confirmar y pasar a mañana'),'El botón debe anunciar el traslado');
 assert.ok(motorista.includes('Ya no forma parte de tu ruta de hoy'),'El motorista debe recibir confirmación');
 assert.ok(central.includes('📅 Reprogramado desde'),'Central debe mostrar origen');
 assert.ok(central.includes('motivo_incidencia'),'Central debe conservar motivo en etiqueta');
});

test('Motorista puede deshacer No me fui individualmente sin afectar cobros',()=>{
 assert.ok(motorista.includes("data-undo-no-fui="),'Botón por pedido en sección No me fui');
 assert.ok(motorista.includes("sb.rpc('motorista_deshacer_no_me_fui'"),'RPC segura de deshacer');
 assert.ok(motorista.includes("p_version:Number(p.version_edicion)||0"),'Control de versión del pedido');
 assert.ok(motorista.includes("await load();"),'Actualizar ruta tras deshacer');
});

test('Central ofrece Pasar a mañana individual y múltiple sin exigir motorista',()=>{
 assert.ok(central.includes("flota_pasar_pedidos_manana_central"),'Debe usar RPC segura y transaccional');
 assert.ok(central.includes('data-pasar-manana-uno'),'Debe ofrecer un botón por pedido');
 assert.ok(central.includes('dyDPasarManana'),'Debe ofrecer botón para selección múltiple');
 assert.ok(central.includes('pasablesMarcados.length===selOs.length'),'Solo debe permitir lote elegible completo');
 assert.ok(central.includes('p_fecha_origen:st.fecha'),'Debe validar fecha original');
 assert.ok(central.includes('p_versiones:versiones'),'Debe enviar control de versiones');
 assert.ok(central.includes("o.motorista_id!==null||o.estado!=='pendiente'"),'Debe verificar resultado sin motorista');
 assert.ok(central.includes("o.precio_delivery!==lista.find"),'Debe conservar importe de entrega');
});

test('Rendiciones distinguen el día operativo de la fecha de carga y muestran Pasa mañana',()=>{
 assert.ok(central.includes("flota_historial_reprogramados_fecha"),'Consultar historial auditado');
 assert.ok(central.includes("reprogramados:reprogramados.data||[]"),'Incluir eventos por fecha');
 assert.ok(central.includes("if(fechaRuta!==d.fecha&&(p.ruta_general_id||fechaCarga!==d.fecha))continue"),'No mostrar en hoy los pedidos trasladados a mañana');
 assert.ok(central.includes("t.pasados.length+' pasados a mañana"),'Rendición de tienda debe contar traslado');
 assert.ok(central.includes("PEDIDOS PASADOS A MAÑANA"),'PDF debe incluir detalle de traslados');
});
test('Crear rutas, asignar y anexar no recupera pedidos viejos automáticamente',()=>{
 assert.ok(!central.includes("const moved=await client.rpc('flota_reorganizar_pendientes_heredados'"),'Crear turno no debe rescatar otras fechas');
 assert.ok(!central.includes("const rr=await client.rpc('flota_reorganizar_pendientes_heredados'"),'Asignación no debe rescatar otras fechas');
 assert.ok(central.includes("diaPY(o.created_at)===route.fecha"),'Anexar debe limitar pedidos sin ruta al día correcto');
 assert.ok(central.includes("['pendiente','no_responde','no_recibio'].includes(o.estado)"),'Central debe permitir mover incidencias no cobradas');
});

test('No reprogramar pedidos futuros hacia hoy; asignar futura ruta sin cambiar fechas',()=>{
 assert.ok(central.includes("const historicoElegible=o=>!!o&&st.fecha<hoy()"),'Históricos solo fechas pasadas');
 assert.ok(central.includes("const futuroElegible=o=>!!o&&st.fecha>hoy()"),'Destinos futuros separadamente');
 assert.ok(central.includes("if(st.fecha>=hoy())return msg('No se pueden devolver pedidos"),'Guardia de reprogramación');
 assert.ok(central.includes("client.rpc('flota_asignar_lote',{p_pedidos:ids,p_motorista:d.id})"),'Asignar sin mover fechas');
 assert.ok(central.includes("ver.data||[]).length!==ids.length"),'Verificar cantidad exacta');
 assert.ok(central.includes("waUrl(d,new Set(ids))"),'WhatsApp solo pedidos confirmados y seleccionados');
});

test('WhatsApp completo evita bloqueo de ventanas emergentes y permite copiar',()=>{
 assert.ok(central.includes('id="dyEnviarRutaWA"'),'Link de envío completo');
 assert.ok(central.includes('target="_self"'),'Abrir en la misma pestaña, sin popup');
 assert.ok(central.includes('id="dyCopiarRutaWA"'),'Opción de copiar texto');
 assert.ok(central.includes('navigator.clipboard.writeText(texto)'),'Copiar contenido real del mensaje');
});
