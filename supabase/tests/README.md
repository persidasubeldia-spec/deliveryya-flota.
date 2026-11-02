# Pruebas SQL locales (datos sintéticos)

Banco de pruebas que replica el esquema de producción en un PostgreSQL local y ejecuta el ciclo
Tienda → turno → ruta → Central → moto → caja con datos inventados. No toca Supabase.

1. `bootstrap.sql`: simula `auth.uid()`, roles `anon`/`authenticated` y extensiones de Supabase.
2. `../../migration_export/supabase_schema_reference.sql` + `grants.sql`: esquema y permisos (cotejados por hash contra producción 2026-11-02).
3. `seed.sql`: 1 empresa, tiendas T1/T3, empleada, 2 motos (25 % y 30 %), 30 pedidos en 3 modalidades.
4. `tests.sql`: aislamiento entre tiendas, rutas por turno, rescate de pedidos, reparto, cobros, rechazos, caja y rendición.

`run.sh [migraciones...]` restaura la base limpia, aplica las migraciones indicadas y corre todo.
