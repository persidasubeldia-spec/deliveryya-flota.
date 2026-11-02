-- F3: eliminar funciones obsoletas o peligrosas que ninguna pantalla usa
--   * admin_asignar_pedido_motorista: asignaba moto y número a mano, sin ruta confirmada ni comisión de la moto.
--   * cerrar_caja_motorista: esqueleto que solo devolvía error (reemplazado por motorista_presentar_cierre).
--   * flota_crear_ruta(date): creaba rutas SIN turno (origen de las rutas heredadas mezcladas).
--   * tienda_agregar_pedido_a_ruta(uuid): versión vieja sin turno (ya sin permiso de ejecución).
--   * flota_confirmar_cierre(uuid,int): envoltorio sin uso; Central usa flota_confirmar_cierre_completo.
-- F4: defensa adicional: el rol anon (sin sesión) no necesita acceso directo a ninguna tabla.
--     Las funciones de trigger no deben ser invocables por API.
-- Reversión: supabase/rollback/20261102110000_f3_f4_limpieza_y_endurecimiento.sql
drop function if exists public.admin_asignar_pedido_motorista(uuid, uuid, integer);
drop function if exists public.cerrar_caja_motorista(uuid, uuid, integer, integer, integer, integer);
drop function if exists public.flota_crear_ruta(date);
drop function if exists public.tienda_agregar_pedido_a_ruta(uuid);
drop function if exists public.flota_confirmar_cierre(uuid, integer);

revoke all on all tables in schema public from anon;

revoke all on function public.deliveryya_asignar_codigo_tienda() from public, anon, authenticated;
revoke all on function public.deliveryya_fijar_autor_pedido() from public, anon, authenticated;
