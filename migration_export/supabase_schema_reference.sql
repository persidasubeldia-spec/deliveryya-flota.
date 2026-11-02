-- DELIVERY YA FLOTA SUPABASE PUBLIC SCHEMA SNAPSHOT

-- Includes catalog-derived DDL only; no production row data or auth secrets.

-- This is a reference snapshot, not an official pg_dump. Test on staging before restore.

CREATE SCHEMA IF NOT EXISTS public;

CREATE TABLE IF NOT EXISTS public."clientes" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "tienda_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "telefono" text NOT NULL,
  "direccion" text NOT NULL,
  "lat" double precision,
  "lng" double precision,
  "referencias" text,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public."empresas" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "nombre" text NOT NULL,
  "ruc" text,
  "telefono" text,
  "direccion" text,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "porcentaje_empresa_general" integer DEFAULT 25 NOT NULL
);

CREATE TABLE IF NOT EXISTS public."flota_cierres_motoristas" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "motorista_id" uuid NOT NULL,
  "fecha" date NOT NULL,
  "efectivo_esperado" integer DEFAULT 0 NOT NULL,
  "transferencia_registrada" integer DEFAULT 0 NOT NULL,
  "comision_motorista" integer DEFAULT 0 NOT NULL,
  "comision_empresa" integer DEFAULT 0 NOT NULL,
  "a_rendir_esperado" integer DEFAULT 0 NOT NULL,
  "efectivo_declarado" integer DEFAULT 0 NOT NULL,
  "transferencia_declarada" integer DEFAULT 0 NOT NULL,
  "efectivo_recibido" integer,
  "diferencia" integer,
  "estado" text DEFAULT 'presentada'::text NOT NULL,
  "presentado_por" uuid NOT NULL,
  "confirmado_por" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "confirmed_at" timestamp with time zone,
  "transferencia_confirmada" integer,
  "diferencia_transferencia" integer
);

CREATE TABLE IF NOT EXISTS public."flota_invitaciones" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "correo" text NOT NULL,
  "rol" text NOT NULL,
  "nombre" text NOT NULL,
  "telefono" text,
  "token_hash" text NOT NULL,
  "creado_por" uuid NOT NULL,
  "vence_en" timestamp with time zone NOT NULL,
  "usada_por" uuid,
  "revocada" boolean DEFAULT false NOT NULL,
  "puede_finanzas" boolean DEFAULT false NOT NULL,
  "puede_comisiones" boolean DEFAULT false NOT NULL,
  "puede_motoristas" boolean DEFAULT false NOT NULL,
  "puede_tiendas" boolean DEFAULT false NOT NULL,
  "puede_confirmar_rendiciones" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."flota_propietarios_pendientes" (
  "empresa_id" uuid NOT NULL,
  "correo" text NOT NULL,
  "creado_en" timestamp with time zone DEFAULT now() NOT NULL,
  "reclamado_en" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."flota_rechazos_detalle" (
  "pedido_id" uuid NOT NULL,
  "empresa_id" uuid NOT NULL,
  "tienda_id" uuid NOT NULL,
  "motorista_id" uuid NOT NULL,
  "responsable_pago" text NOT NULL,
  "importe_cobrado" integer DEFAULT 0 NOT NULL,
  "medio_cobro" text,
  "importe_pendiente" integer NOT NULL,
  "comision_motorista" integer NOT NULL,
  "comision_empresa" integer NOT NULL,
  "motivo" text NOT NULL,
  "registrado_por" uuid NOT NULL,
  "registrado_en" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."flota_solicitudes_tienda" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "usuario_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "responsable" text NOT NULL,
  "telefono" text NOT NULL,
  "correo" text NOT NULL,
  "direccion" text,
  "estado" text DEFAULT 'pendiente'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "revisada_en" timestamp with time zone,
  "revisada_por" uuid,
  "tienda_id" uuid
);

CREATE TABLE IF NOT EXISTS public."flota_tienda_propietarias" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "tienda_id" uuid NOT NULL,
  "correo" text NOT NULL,
  "token_hash" text NOT NULL,
  "vence_en" timestamp with time zone DEFAULT (now() + '72:00:00'::interval) NOT NULL,
  "usada_por" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."flota_usuarios" (
  "empresa_id" uuid NOT NULL,
  "usuario_id" uuid NOT NULL,
  "rol" text NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "puede_finanzas" boolean DEFAULT false NOT NULL,
  "puede_comisiones" boolean DEFAULT false NOT NULL,
  "puede_motoristas" boolean DEFAULT false NOT NULL,
  "puede_tiendas" boolean DEFAULT false NOT NULL,
  "puede_confirmar_rendiciones" boolean DEFAULT false NOT NULL,
  "nombre" text,
  "telefono" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."motivos_incidencia_catalogo" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "descripcion" text NOT NULL,
  "es_facturable_tienda" boolean DEFAULT true,
  "activo" boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS public."motorista_invitaciones" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "motorista_id" uuid NOT NULL,
  "token_hash" text NOT NULL,
  "vence_en" timestamp with time zone DEFAULT (now() + '48:00:00'::interval) NOT NULL,
  "usada_por" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."motorista_ordenes_pedidos" (
  "motorista_id" uuid NOT NULL,
  "fecha" date NOT NULL,
  "pedido_id" uuid NOT NULL,
  "posicion" integer NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."motoristas" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "usuario_id" uuid,
  "nombre" text NOT NULL,
  "telefono" text NOT NULL,
  "email" text,
  "color_identificador" text DEFAULT '#3B82F6'::text,
  "activo" boolean DEFAULT true,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "porcentaje_empresa_pct" integer DEFAULT 25 NOT NULL,
  "modalidad_liquidacion" text DEFAULT 'rendir_todo'::text NOT NULL,
  "gps_lat" double precision,
  "gps_lng" double precision,
  "gps_precision_m" numeric,
  "gps_actualizado_en" timestamp with time zone,
  "porcentaje_personalizado" boolean DEFAULT false NOT NULL
);

CREATE TABLE IF NOT EXISTS public."movimientos_financieros" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "pedido_id" uuid NOT NULL,
  "motorista_id" uuid,
  "tienda_id" uuid,
  "monto_mercaderia" integer DEFAULT 0,
  "monto_delivery" integer DEFAULT 0,
  "comision_empresa" integer DEFAULT 0,
  "comision_motorista" integer DEFAULT 0,
  "es_rechazo_facturable" boolean DEFAULT false,
  "liquidado" boolean DEFAULT false,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "efectivo_cobrado" integer DEFAULT 0 NOT NULL,
  "transferencia_cobrada" integer DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS public."pedidos" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "tienda_id" uuid NOT NULL,
  "cliente_id" uuid,
  "ruta_general_id" uuid,
  "motorista_id" uuid,
  "nombre_cliente" text NOT NULL,
  "telefono_cliente" text NOT NULL,
  "direccion_cliente" text NOT NULL,
  "lat" double precision,
  "lng" double precision,
  "referencias" text,
  "observaciones" text,
  "precio_mercaderia" integer DEFAULT 0 NOT NULL,
  "precio_delivery" integer DEFAULT 25000 NOT NULL,
  "modalidad_pago" text NOT NULL,
  "porcentaje_empresa_pct" integer DEFAULT 25,
  "porcentaje_motorista_pct" integer DEFAULT 75,
  "numero_general" integer,
  "estado" text DEFAULT 'pendiente'::text NOT NULL,
  "motivo_incidencia" text,
  "medio_cobro" text,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "updated_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "creado_por" uuid,
  "version_edicion" integer DEFAULT 1 NOT NULL,
  "requiere_revisar_ruta" boolean DEFAULT false NOT NULL,
  "turno" text DEFAULT 'sin_definir'::text NOT NULL
);

CREATE TABLE IF NOT EXISTS public."pedidos_ediciones" (
  "id" bigint NOT NULL,
  "pedido_id" uuid NOT NULL,
  "empresa_id" uuid NOT NULL,
  "tienda_id" uuid,
  "usuario_id" uuid NOT NULL,
  "momento" timestamp with time zone DEFAULT now() NOT NULL,
  "version_anterior" integer NOT NULL,
  "version_nueva" integer NOT NULL,
  "cambios" jsonb NOT NULL
);

CREATE TABLE IF NOT EXISTS public."perfiles" (
  "id" uuid NOT NULL,
  "empresa_id" uuid,
  "rol" text NOT NULL,
  "nombre" text NOT NULL,
  "telefono" text,
  "activo" boolean DEFAULT true,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public."rendiciones" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "tipo" text NOT NULL,
  "referencia_id" uuid NOT NULL,
  "fecha" date DEFAULT CURRENT_DATE NOT NULL,
  "total_efectivo" integer DEFAULT 0,
  "total_transferencia" integer DEFAULT 0,
  "total_comision" integer DEFAULT 0,
  "total_a_rendir" integer DEFAULT 0,
  "estado" text DEFAULT 'abierta'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public."rutas_generales" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "fecha" date DEFAULT CURRENT_DATE NOT NULL,
  "estado" text DEFAULT 'abierta'::text NOT NULL,
  "version_optimizacion" integer DEFAULT 1,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "turno" text
);

CREATE TABLE IF NOT EXISTS public."tarifas_zona" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "localidad" text NOT NULL,
  "costo_envio" integer DEFAULT 25000 NOT NULL,
  "activo" boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS public."tienda_cuentas_v2" (
  "id" uuid NOT NULL,
  "empresa_id" uuid NOT NULL,
  "nombre" text NOT NULL,
  "telefono" text NOT NULL,
  "direccion" text NOT NULL,
  "creado_en" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."tienda_invitaciones" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "tienda_id" uuid NOT NULL,
  "token_hash" text NOT NULL,
  "creada_por" uuid NOT NULL,
  "vence_en" timestamp with time zone NOT NULL,
  "usos_maximos" integer DEFAULT 1 NOT NULL,
  "usos" integer DEFAULT 0 NOT NULL,
  "revocada" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."tienda_miembros" (
  "tienda_id" uuid NOT NULL,
  "usuario_id" uuid NOT NULL,
  "rol" text NOT NULL,
  "activo" boolean DEFAULT true NOT NULL,
  "creado_en" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public."tiendas" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "empresa_id" uuid NOT NULL,
  "usuario_id" uuid,
  "nombre_comercial" text NOT NULL,
  "responsable" text,
  "telefono" text NOT NULL,
  "email" text,
  "direccion" text NOT NULL,
  "lat" double precision,
  "lng" double precision,
  "activo" boolean DEFAULT true,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "codigo" text
);

CREATE TABLE IF NOT EXISTS public."versiones_optimizacion" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "ruta_general_id" uuid NOT NULL,
  "version_numero" integer DEFAULT 1 NOT NULL,
  "orden_pedidos_ids" uuid[] NOT NULL,
  "confirmado_por" text,
  "created_at" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public."empresas" ADD CONSTRAINT "empresas_porcentaje_empresa_general_check" CHECK (porcentaje_empresa_general >= 0 AND porcentaje_empresa_general <= 100);

ALTER TABLE public."flota_cierres_motoristas" ADD CONSTRAINT "flota_cierres_motoristas_estado_check" CHECK (estado = ANY (ARRAY['presentada'::text, 'confirmada'::text, 'diferencia'::text]));

ALTER TABLE public."flota_invitaciones" ADD CONSTRAINT "flota_invitaciones_rol_check" CHECK (rol = ANY (ARRAY['socio'::text, 'operador'::text]));

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_comision_empresa_check" CHECK (comision_empresa >= 0);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_comision_motorista_check" CHECK (comision_motorista >= 0);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_importe_cobrado_check" CHECK (importe_cobrado >= 0);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_importe_pendiente_check" CHECK (importe_pendiente >= 0);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_medio_cobro_check" CHECK (medio_cobro = ANY (ARRAY['efectivo'::text, 'transferencia'::text]));

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_responsable_pago_check" CHECK (responsable_pago = ANY (ARRAY['cliente'::text, 'tienda'::text, 'pendiente'::text]));

ALTER TABLE public."flota_solicitudes_tienda" ADD CONSTRAINT "flota_solicitudes_tienda_estado_check" CHECK (estado = ANY (ARRAY['pendiente'::text, 'aprobada'::text, 'rechazada'::text]));

ALTER TABLE public."flota_usuarios" ADD CONSTRAINT "flota_usuarios_rol_check" CHECK (rol = ANY (ARRAY['propietario'::text, 'socio'::text, 'operador'::text]));

ALTER TABLE public."motorista_ordenes_pedidos" ADD CONSTRAINT "motorista_ordenes_pedidos_posicion_check" CHECK (posicion >= 1);

ALTER TABLE public."motoristas" ADD CONSTRAINT "motoristas_modalidad_liquidacion_check" CHECK (modalidad_liquidacion = ANY (ARRAY['rendir_todo'::text, 'retener_comision'::text]));

ALTER TABLE public."motoristas" ADD CONSTRAINT "motoristas_porcentaje_empresa_pct_check" CHECK (porcentaje_empresa_pct >= 0 AND porcentaje_empresa_pct <= 100);

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_estado_check" CHECK (estado = ANY (ARRAY['pendiente'::text, 'entregado'::text, 'rechazado'::text, 'no_recibio'::text, 'no_responde'::text, 'pasa_manana'::text, 'cancelado'::text]));

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_medio_cobro_check" CHECK (medio_cobro = ANY (ARRAY['efectivo'::text, 'transferencia'::text, 'pagado_previo'::text, NULL::text]));

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_modalidad_pago_check" CHECK (modalidad_pago = ANY (ARRAY['pendiente'::text, 'producto_pagado'::text, 'todo_pagado'::text]));

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_turno_check" CHECK (turno = ANY (ARRAY['manana'::text, 'tarde'::text, 'sin_definir'::text]));

ALTER TABLE public."perfiles" ADD CONSTRAINT "perfiles_rol_check" CHECK (rol = ANY (ARRAY['superadmin'::text, 'admin'::text, 'tienda'::text, 'motorista'::text]));

ALTER TABLE public."rendiciones" ADD CONSTRAINT "rendiciones_estado_check" CHECK (estado = ANY (ARRAY['abierta'::text, 'cerrada'::text, 'auditada'::text]));

ALTER TABLE public."rendiciones" ADD CONSTRAINT "rendiciones_tipo_check" CHECK (tipo = ANY (ARRAY['motorista'::text, 'tienda'::text]));

ALTER TABLE public."rutas_generales" ADD CONSTRAINT "rutas_generales_estado_check" CHECK (estado = ANY (ARRAY['abierta'::text, 'optimizada'::text, 'en_reparto'::text, 'cerrada'::text]));

ALTER TABLE public."rutas_generales" ADD CONSTRAINT "rutas_generales_turno_check" CHECK ((turno = ANY (ARRAY['manana'::text, 'tarde'::text, 'sin_definir'::text])) OR turno IS NULL);

ALTER TABLE public."tienda_invitaciones" ADD CONSTRAINT "tienda_invitaciones_usos_check" CHECK (usos >= 0);

ALTER TABLE public."tienda_invitaciones" ADD CONSTRAINT "tienda_invitaciones_usos_maximos_check" CHECK (usos_maximos >= 1 AND usos_maximos <= 20);

ALTER TABLE public."tienda_miembros" ADD CONSTRAINT "tienda_miembros_rol_check" CHECK (rol = ANY (ARRAY['propietario'::text, 'empleado'::text]));

ALTER TABLE public."clientes" ADD CONSTRAINT "clientes_pkey" PRIMARY KEY (id);

ALTER TABLE public."empresas" ADD CONSTRAINT "empresas_pkey" PRIMARY KEY (id);

ALTER TABLE public."flota_cierres_motoristas" ADD CONSTRAINT "flota_cierres_motoristas_pkey" PRIMARY KEY (id);

ALTER TABLE public."flota_invitaciones" ADD CONSTRAINT "flota_invitaciones_pkey" PRIMARY KEY (id);

ALTER TABLE public."flota_propietarios_pendientes" ADD CONSTRAINT "flota_propietarios_pendientes_pkey" PRIMARY KEY (empresa_id);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_pkey" PRIMARY KEY (pedido_id);

ALTER TABLE public."flota_solicitudes_tienda" ADD CONSTRAINT "flota_solicitudes_tienda_pkey" PRIMARY KEY (id);

ALTER TABLE public."flota_tienda_propietarias" ADD CONSTRAINT "flota_tienda_propietarias_pkey" PRIMARY KEY (id);

ALTER TABLE public."flota_usuarios" ADD CONSTRAINT "flota_usuarios_pkey" PRIMARY KEY (empresa_id, usuario_id);

ALTER TABLE public."motivos_incidencia_catalogo" ADD CONSTRAINT "motivos_incidencia_catalogo_pkey" PRIMARY KEY (id);

ALTER TABLE public."motorista_invitaciones" ADD CONSTRAINT "motorista_invitaciones_pkey" PRIMARY KEY (id);

ALTER TABLE public."motorista_ordenes_pedidos" ADD CONSTRAINT "motorista_ordenes_pedidos_pkey" PRIMARY KEY (motorista_id, fecha, pedido_id);

ALTER TABLE public."motoristas" ADD CONSTRAINT "motoristas_pkey" PRIMARY KEY (id);

ALTER TABLE public."movimientos_financieros" ADD CONSTRAINT "movimientos_financieros_pkey" PRIMARY KEY (id);

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_pkey" PRIMARY KEY (id);

ALTER TABLE public."pedidos_ediciones" ADD CONSTRAINT "pedidos_ediciones_pkey" PRIMARY KEY (id);

ALTER TABLE public."perfiles" ADD CONSTRAINT "perfiles_pkey" PRIMARY KEY (id);

ALTER TABLE public."rendiciones" ADD CONSTRAINT "rendiciones_pkey" PRIMARY KEY (id);

ALTER TABLE public."rutas_generales" ADD CONSTRAINT "rutas_generales_pkey" PRIMARY KEY (id);

ALTER TABLE public."tarifas_zona" ADD CONSTRAINT "tarifas_zona_pkey" PRIMARY KEY (id);

ALTER TABLE public."tienda_cuentas_v2" ADD CONSTRAINT "tienda_cuentas_v2_pkey" PRIMARY KEY (id);

ALTER TABLE public."tienda_invitaciones" ADD CONSTRAINT "tienda_invitaciones_pkey" PRIMARY KEY (id);

ALTER TABLE public."tienda_miembros" ADD CONSTRAINT "tienda_miembros_pkey" PRIMARY KEY (tienda_id, usuario_id);

ALTER TABLE public."tiendas" ADD CONSTRAINT "tiendas_pkey" PRIMARY KEY (id);

ALTER TABLE public."versiones_optimizacion" ADD CONSTRAINT "versiones_optimizacion_pkey" PRIMARY KEY (id);

ALTER TABLE public."flota_cierres_motoristas" ADD CONSTRAINT "flota_cierres_motoristas_motorista_id_fecha_key" UNIQUE (motorista_id, fecha);

ALTER TABLE public."flota_invitaciones" ADD CONSTRAINT "flota_invitaciones_token_hash_key" UNIQUE (token_hash);

ALTER TABLE public."flota_propietarios_pendientes" ADD CONSTRAINT "flota_propietarios_pendientes_correo_key" UNIQUE (correo);

ALTER TABLE public."flota_solicitudes_tienda" ADD CONSTRAINT "flota_solicitudes_tienda_empresa_id_usuario_id_key" UNIQUE (empresa_id, usuario_id);

ALTER TABLE public."flota_tienda_propietarias" ADD CONSTRAINT "flota_tienda_propietarias_token_hash_key" UNIQUE (token_hash);

ALTER TABLE public."motorista_invitaciones" ADD CONSTRAINT "motorista_invitaciones_token_hash_key" UNIQUE (token_hash);

ALTER TABLE public."motorista_ordenes_pedidos" ADD CONSTRAINT "motorista_ordenes_pedidos_motorista_id_fecha_posicion_key" UNIQUE (motorista_id, fecha, posicion);

ALTER TABLE public."tienda_invitaciones" ADD CONSTRAINT "tienda_invitaciones_token_hash_key" UNIQUE (token_hash);

ALTER TABLE public."clientes" ADD CONSTRAINT "clientes_tienda_id_fkey" FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE;

ALTER TABLE public."flota_cierres_motoristas" ADD CONSTRAINT "flota_cierres_motoristas_confirmado_por_fkey" FOREIGN KEY (confirmado_por) REFERENCES auth.users(id);

ALTER TABLE public."flota_cierres_motoristas" ADD CONSTRAINT "flota_cierres_motoristas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public."flota_cierres_motoristas" ADD CONSTRAINT "flota_cierres_motoristas_motorista_id_fkey" FOREIGN KEY (motorista_id) REFERENCES motoristas(id);

ALTER TABLE public."flota_cierres_motoristas" ADD CONSTRAINT "flota_cierres_motoristas_presentado_por_fkey" FOREIGN KEY (presentado_por) REFERENCES auth.users(id);

ALTER TABLE public."flota_invitaciones" ADD CONSTRAINT "flota_invitaciones_creado_por_fkey" FOREIGN KEY (creado_por) REFERENCES auth.users(id);

ALTER TABLE public."flota_invitaciones" ADD CONSTRAINT "flota_invitaciones_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public."flota_invitaciones" ADD CONSTRAINT "flota_invitaciones_usada_por_fkey" FOREIGN KEY (usada_por) REFERENCES auth.users(id);

ALTER TABLE public."flota_propietarios_pendientes" ADD CONSTRAINT "flota_propietarios_pendientes_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_motorista_id_fkey" FOREIGN KEY (motorista_id) REFERENCES motoristas(id);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_pedido_id_fkey" FOREIGN KEY (pedido_id) REFERENCES pedidos(id);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_registrado_por_fkey" FOREIGN KEY (registrado_por) REFERENCES auth.users(id);

ALTER TABLE public."flota_rechazos_detalle" ADD CONSTRAINT "flota_rechazos_detalle_tienda_id_fkey" FOREIGN KEY (tienda_id) REFERENCES tiendas(id);

ALTER TABLE public."flota_solicitudes_tienda" ADD CONSTRAINT "flota_solicitudes_tienda_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public."flota_solicitudes_tienda" ADD CONSTRAINT "flota_solicitudes_tienda_tienda_id_fkey" FOREIGN KEY (tienda_id) REFERENCES tiendas(id);

ALTER TABLE public."flota_solicitudes_tienda" ADD CONSTRAINT "flota_solicitudes_tienda_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES auth.users(id);

ALTER TABLE public."flota_tienda_propietarias" ADD CONSTRAINT "flota_tienda_propietarias_tienda_id_fkey" FOREIGN KEY (tienda_id) REFERENCES tiendas(id);

ALTER TABLE public."flota_tienda_propietarias" ADD CONSTRAINT "flota_tienda_propietarias_usada_por_fkey" FOREIGN KEY (usada_por) REFERENCES auth.users(id);

ALTER TABLE public."flota_usuarios" ADD CONSTRAINT "flota_usuarios_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public."flota_usuarios" ADD CONSTRAINT "flota_usuarios_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES auth.users(id);

ALTER TABLE public."motivos_incidencia_catalogo" ADD CONSTRAINT "motivos_incidencia_catalogo_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public."motorista_invitaciones" ADD CONSTRAINT "motorista_invitaciones_motorista_id_fkey" FOREIGN KEY (motorista_id) REFERENCES motoristas(id);

ALTER TABLE public."motorista_invitaciones" ADD CONSTRAINT "motorista_invitaciones_usada_por_fkey" FOREIGN KEY (usada_por) REFERENCES auth.users(id);

ALTER TABLE public."motorista_ordenes_pedidos" ADD CONSTRAINT "motorista_ordenes_pedidos_motorista_id_fkey" FOREIGN KEY (motorista_id) REFERENCES motoristas(id);

ALTER TABLE public."motorista_ordenes_pedidos" ADD CONSTRAINT "motorista_ordenes_pedidos_pedido_id_fkey" FOREIGN KEY (pedido_id) REFERENCES pedidos(id);

ALTER TABLE public."motoristas" ADD CONSTRAINT "motoristas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public."motoristas" ADD CONSTRAINT "motoristas_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES perfiles(id) ON DELETE SET NULL;

ALTER TABLE public."movimientos_financieros" ADD CONSTRAINT "movimientos_financieros_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public."movimientos_financieros" ADD CONSTRAINT "movimientos_financieros_motorista_id_fkey" FOREIGN KEY (motorista_id) REFERENCES motoristas(id) ON DELETE SET NULL;

ALTER TABLE public."movimientos_financieros" ADD CONSTRAINT "movimientos_financieros_pedido_id_fkey" FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE;

ALTER TABLE public."movimientos_financieros" ADD CONSTRAINT "movimientos_financieros_tienda_id_fkey" FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE SET NULL;

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL;

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_creado_por_fkey" FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_motorista_id_fkey" FOREIGN KEY (motorista_id) REFERENCES motoristas(id) ON DELETE SET NULL;

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_ruta_general_id_fkey" FOREIGN KEY (ruta_general_id) REFERENCES rutas_generales(id) ON DELETE SET NULL;

ALTER TABLE public."pedidos" ADD CONSTRAINT "pedidos_tienda_id_fkey" FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE;

ALTER TABLE public."pedidos_ediciones" ADD CONSTRAINT "pedidos_ediciones_pedido_id_fkey" FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE;

ALTER TABLE public."perfiles" ADD CONSTRAINT "perfiles_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public."perfiles" ADD CONSTRAINT "perfiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public."rendiciones" ADD CONSTRAINT "rendiciones_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public."rutas_generales" ADD CONSTRAINT "rutas_generales_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public."tarifas_zona" ADD CONSTRAINT "tarifas_zona_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public."tienda_cuentas_v2" ADD CONSTRAINT "tienda_cuentas_v2_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public."tienda_cuentas_v2" ADD CONSTRAINT "tienda_cuentas_v2_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public."tienda_invitaciones" ADD CONSTRAINT "tienda_invitaciones_creada_por_fkey" FOREIGN KEY (creada_por) REFERENCES auth.users(id);

ALTER TABLE public."tienda_invitaciones" ADD CONSTRAINT "tienda_invitaciones_tienda_id_fkey" FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE;

ALTER TABLE public."tienda_miembros" ADD CONSTRAINT "tienda_miembros_tienda_id_fkey" FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE;

ALTER TABLE public."tienda_miembros" ADD CONSTRAINT "tienda_miembros_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public."tiendas" ADD CONSTRAINT "tiendas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public."tiendas" ADD CONSTRAINT "tiendas_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES perfiles(id) ON DELETE SET NULL;

ALTER TABLE public."versiones_optimizacion" ADD CONSTRAINT "versiones_optimizacion_ruta_general_id_fkey" FOREIGN KEY (ruta_general_id) REFERENCES rutas_generales(id) ON DELETE CASCADE;

CREATE INDEX idx_clientes_tienda_telefono ON public.clientes USING btree (tienda_id, telefono);

CREATE UNIQUE INDEX flota_propietario_unico ON public.flota_usuarios USING btree (empresa_id) WHERE (rol = 'propietario'::text);

CREATE INDEX flota_usuarios_por_usuario ON public.flota_usuarios USING btree (usuario_id);

CREATE UNIQUE INDEX motoristas_email_empresa_unique ON public.motoristas USING btree (empresa_id, lower(email)) WHERE (email IS NOT NULL);

CREATE UNIQUE INDEX movimientos_financieros_pedido_unico ON public.movimientos_financieros USING btree (pedido_id);

CREATE INDEX idx_pedidos_creado_por ON public.pedidos USING btree (creado_por);

CREATE INDEX idx_pedidos_empresa_tienda_fecha ON public.pedidos USING btree (empresa_id, tienda_id, created_at DESC);

CREATE INDEX idx_pedidos_empresa_turno_fecha ON public.pedidos USING btree (empresa_id, turno, created_at DESC);

CREATE INDEX idx_perfiles_empresa_id ON public.perfiles USING btree (empresa_id);

CREATE UNIQUE INDEX rutas_por_empresa_fecha_turno_unica ON public.rutas_generales USING btree (empresa_id, fecha, turno) WHERE ((turno IS NOT NULL) AND (estado = ANY (ARRAY['abierta'::text, 'optimizada'::text, 'en_reparto'::text])));

CREATE UNIQUE INDEX tienda_cuentas_v2_email_idx ON public.tienda_cuentas_v2 USING btree (id);

CREATE INDEX idx_invitaciones_tienda ON public.tienda_invitaciones USING btree (tienda_id, vence_en);

CREATE INDEX idx_tienda_miembros_usuario ON public.tienda_miembros USING btree (usuario_id, activo);

CREATE UNIQUE INDEX deliveryya_tienda_codigo_empresa_unico ON public.tiendas USING btree (empresa_id, codigo);

CREATE INDEX idx_tiendas_usuario_id ON public.tiendas USING btree (usuario_id);

CREATE UNIQUE INDEX tiendas_usuario_unico ON public.tiendas USING btree (usuario_id) WHERE (usuario_id IS NOT NULL);

CREATE OR REPLACE FUNCTION public.aceptar_invitacion_tienda(p_token text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_inv public.tienda_invitaciones%rowtype; v_user uuid; v_code text;
begin
 v_user=auth.uid();
 if v_user is null or length(p_token)<>48 or p_token !~ '^[a-f0-9]+$' then raise exception 'Invitacion invalida';end if;
 select * into v_inv from public.tienda_invitaciones where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
 if not found or v_inv.revocada or v_inv.vence_en<now() or v_inv.usos>=v_inv.usos_maximos then raise exception 'Invitacion vencida o revocada';end if;
 if not exists(select 1 from public.tiendas where id=v_inv.tienda_id and activo) then raise exception 'Tienda inactiva';end if;
 if exists(select 1 from public.tienda_miembros where usuario_id=v_user and activo and tienda_id<>v_inv.tienda_id) then raise exception 'Usuario ya vinculado a otra tienda';end if;
 insert into public.tienda_miembros(tienda_id,usuario_id,rol,activo) values(v_inv.tienda_id,v_user,'empleado',true)
 on conflict(tienda_id,usuario_id) do update set activo=true;
 update public.tienda_invitaciones set usos=usos+1 where id=v_inv.id;
 select codigo into v_code from public.tiendas where id=v_inv.tienda_id;
 return v_code;
end $function$;

CREATE OR REPLACE FUNCTION public.admin_asignar_pedido_motorista(p_pedido_id uuid, p_motorista_id uuid, p_numero_general integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_estado text;v_asignado uuid;
begin
 select empresa_id,estado,motorista_id into v_empresa,v_estado,v_asignado from public.pedidos where id=p_pedido_id for update;
 if v_empresa is null or not exists(select 1 from public.flota_usuarios where empresa_id=v_empresa and usuario_id=auth.uid() and activo and rol in('propietario','socio','operador')) then raise exception 'No autorizado';end if;
 if v_estado not in('pendiente','no_responde','pasa_manana') or v_asignado is not null then raise exception 'Pedido no disponible para asignar';end if;
 if p_numero_general is null or p_numero_general<1 then raise exception 'Numero invalido';end if;
 if not exists(select 1 from public.motoristas where id=p_motorista_id and empresa_id=v_empresa and activo) then raise exception 'Motorista no autorizado';end if;
 update public.pedidos set motorista_id=p_motorista_id,numero_general=p_numero_general,updated_at=now() where id=p_pedido_id;
end $function$;

CREATE OR REPLACE FUNCTION public.admin_confirmar_ruta_optimizada(p_ruta_general_id uuid, p_orden_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_estado text;v_turno text;v_count integer;v_selected integer;
begin
 select empresa_id,estado,turno into v_empresa,v_estado,v_turno from public.rutas_generales where id=p_ruta_general_id for update;
 if v_empresa is null or v_estado not in('abierta','optimizada') or v_turno not in('manana','tarde','sin_definir') then raise exception 'La ruta debe estar abierta, autorizada y tener turno definido';end if;
 if not exists(select 1 from public.flota_usuarios where empresa_id=v_empresa and usuario_id=auth.uid() and activo and rol in('propietario','socio','operador')) then raise exception 'No autorizado';end if;
 v_count=coalesce(array_length(p_orden_ids,1),0);
 if v_count<2 or v_count>2000 then raise exception 'Seleccioná entre 2 y 2000 paradas';end if;
 if (select count(distinct x) from unnest(p_orden_ids) x)<>v_count then raise exception 'IDs duplicados';end if;
 perform 1 from public.pedidos where id=any(p_orden_ids) or ruta_general_id=p_ruta_general_id order by id for update;
 if exists(select 1 from public.pedidos where ruta_general_id=p_ruta_general_id and (estado<>'pendiente' or motorista_id is not null)) then raise exception 'Ruta con repartos o entregas: no puede renumerarse';end if;
 if exists(select 1 from public.pedidos p where p.ruta_general_id=p_ruta_general_id and not(p.id=any(p_orden_ids))) then raise exception 'Hay pedidos preparados que no están en el cálculo: incluilos antes de confirmar para evitar que desaparezcan de la ruta';end if;
 select count(*) into v_selected from public.pedidos p where p.id=any(p_orden_ids) and p.empresa_id=v_empresa and p.estado='pendiente' and p.motorista_id is null and p.lat is not null and p.lng is not null
 and coalesce(p.turno,'sin_definir')=v_turno and (p.ruta_general_id is null or p.ruta_general_id=p_ruta_general_id);
 if v_selected<>v_count then raise exception 'Todos los pedidos deben pertenecer a una misma empresa, turno y ruta';end if;
 update public.pedidos p set numero_general=u.numero,ruta_general_id=p_ruta_general_id,updated_at=now()
 from unnest(p_orden_ids) with ordinality u(id,numero) where p.id=u.id;
 update public.rutas_generales set estado='optimizada',version_optimizacion=coalesce(version_optimizacion,0)+1 where id=p_ruta_general_id;
end $function$;

CREATE OR REPLACE FUNCTION public.cerrar_caja_motorista(p_empresa_id uuid, p_motorista_id uuid, p_efectivo integer, p_transferencia integer, p_comision integer, p_a_rendir integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 raise exception 'Cierre no habilitado: requiere conciliacion financiera verificable';
end $function$;

CREATE OR REPLACE FUNCTION public.crear_invitacion_tienda(p_tienda uuid, p_horas integer DEFAULT 48)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_token text;v_user uuid;
begin
 v_user=auth.uid();
 if v_user is null or p_horas not between 1 and 168 then raise exception 'Solicitud invalida'; end if;
 if not exists(select 1 from public.tienda_miembros m join public.tiendas t on t.id=m.tienda_id where m.tienda_id=p_tienda and m.usuario_id=v_user and m.activo and m.rol='propietario' and t.activo) then raise exception 'No autorizado'; end if;
 v_token=encode(extensions.gen_random_bytes(24),'hex');
 insert into public.tienda_invitaciones(tienda_id,token_hash,creada_por,vence_en)
 values(p_tienda,encode(sha256(convert_to(v_token,'UTF8')),'hex'),v_user,now()+make_interval(hours=>p_horas));
 return v_token;
end $function$;

CREATE OR REPLACE FUNCTION public.deliveryya_asignar_codigo_tienda()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
if tg_op='UPDATE' then
 if new.codigo is distinct from old.codigo or new.empresa_id is distinct from old.empresa_id then raise exception 'No se puede cambiar el codigo ni la flota de origen';end if;
else
 new.codigo='T'||nextval('public.deliveryya_codigo_tienda_seq'::regclass)::text;
end if;
return new;
end $function$;

CREATE OR REPLACE FUNCTION public.deliveryya_fijar_autor_pedido()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
if auth.uid() is not null then new.creado_por=auth.uid(); end if;
return new;
end $function$;

CREATE OR REPLACE FUNCTION public.deliveryya_propietario_membresia()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if new.usuario_id is not null then
 insert into public.tienda_miembros(tienda_id,usuario_id,rol,activo) values(new.id,new.usuario_id,'propietario',true)
 on conflict(tienda_id,usuario_id) do nothing;
 end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.editar_pedido_seguro(p_pedido_id uuid, p_version integer, p_cambios jsonb)
 RETURNS pedidos
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE o public.pedidos%ROWTYPE; v public.pedidos%ROWTYPE; f text; antes jsonb; despues jsonb; permitido text[]; admin boolean; tienda boolean; moto boolean; sensible boolean; ubica boolean;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Iniciá sesión'; END IF;
 SELECT * INTO o FROM public.pedidos WHERE id=p_pedido_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
 IF p_version IS DISTINCT FROM o.version_edicion THEN RAISE EXCEPTION 'El pedido cambió. Actualizá los datos antes de guardar'; END IF;
 IF p_cambios IS NULL OR jsonb_typeof(p_cambios)<>'object' OR p_cambios='{}'::jsonb THEN RAISE EXCEPTION 'No hay cambios'; END IF;
 SELECT EXISTS(SELECT 1 FROM public.flota_usuarios x WHERE x.empresa_id=o.empresa_id AND x.usuario_id=auth.uid() AND x.activo AND x.rol IN ('propietario','socio','operador')) INTO admin;
 SELECT EXISTS(SELECT 1 FROM public.tienda_miembros x WHERE x.tienda_id=o.tienda_id AND x.usuario_id=auth.uid() AND x.activo) INTO tienda;
 SELECT EXISTS(SELECT 1 FROM public.motoristas x WHERE x.id=o.motorista_id AND x.usuario_id=auth.uid() AND x.activo) INTO moto;
 IF NOT (admin OR tienda OR moto) THEN RAISE EXCEPTION 'No autorizado para este pedido'; END IF;
 IF o.estado <> 'pendiente' THEN RAISE EXCEPTION 'Pedido concluido o en incidencia: requiere corrección administrativa auditada'; END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros x WHERE x.pedido_id=o.id) THEN RAISE EXCEPTION 'Pedido con cobros: no se puede editar'; END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas x WHERE x.motorista_id=o.motorista_id AND x.estado IN ('presentada','confirmada','diferencia') AND x.fecha=(now() AT TIME ZONE 'America/Asuncion')::date) THEN RAISE EXCEPTION 'Rendición presentada: edición bloqueada'; END IF;
 permitido:=CASE WHEN moto THEN ARRAY['referencias','observaciones','telefono_cliente'] WHEN o.motorista_id IS NOT NULL THEN ARRAY['nombre_cliente','telefono_cliente','referencias','observaciones'] ELSE ARRAY['nombre_cliente','telefono_cliente','direccion_cliente','lat','lng','referencias','observaciones','precio_mercaderia','precio_delivery','modalidad_pago'] END;
 FOR f IN SELECT jsonb_object_keys(p_cambios) LOOP
  IF NOT f=ANY(permitido) THEN RAISE EXCEPTION 'Campo no editable en este estado: %',f; END IF;
 END LOOP;
 IF p_cambios ? 'modalidad_pago' AND NOT (p_cambios->>'modalidad_pago'=ANY(ARRAY['pendiente','producto_pagado','todo_pagado'])) THEN RAISE EXCEPTION 'Modalidad inválida'; END IF;
 IF p_cambios ? 'precio_mercaderia' AND ((p_cambios->>'precio_mercaderia')::integer<0) THEN RAISE EXCEPTION 'Precio inválido'; END IF;
 IF p_cambios ? 'precio_delivery' AND ((p_cambios->>'precio_delivery')::integer<0) THEN RAISE EXCEPTION 'Envío inválido'; END IF;
 IF p_cambios ? 'lat' OR p_cambios ? 'lng' THEN
  IF (p_cambios ? 'lat') <> (p_cambios ? 'lng') THEN RAISE EXCEPTION 'Actualizá latitud y longitud juntas'; END IF;
  IF p_cambios->>'lat' IS NULL OR p_cambios->>'lng' IS NULL THEN
    IF (p_cambios->>'lat') IS DISTINCT FROM (p_cambios->>'lng') THEN RAISE EXCEPTION 'Coordenadas incompletas'; END IF;
  ELSIF (p_cambios->>'lat')::double precision NOT BETWEEN -90 AND 90 OR (p_cambios->>'lng')::double precision NOT BETWEEN -180 AND 180 THEN RAISE EXCEPTION 'Coordenadas inválidas'; END IF;
 END IF;
 antes=to_jsonb(o);
 despues=antes || p_cambios;
 SELECT * INTO v FROM jsonb_populate_record(NULL::public.pedidos,despues);
 ubica=(p_cambios ? 'lat' OR p_cambios ? 'lng' OR p_cambios ? 'direccion_cliente') AND (o.ruta_general_id IS NOT NULL);
 UPDATE public.pedidos SET
 nombre_cliente=v.nombre_cliente,telefono_cliente=v.telefono_cliente,direccion_cliente=v.direccion_cliente,lat=v.lat,lng=v.lng,
 referencias=v.referencias,observaciones=v.observaciones,precio_mercaderia=v.precio_mercaderia,precio_delivery=v.precio_delivery,modalidad_pago=v.modalidad_pago,
 version_edicion=o.version_edicion+1, requiere_revisar_ruta=o.requiere_revisar_ruta OR ubica,updated_at=now()
 WHERE id=o.id RETURNING * INTO v;
 INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 VALUES(o.id,o.empresa_id,o.tienda_id,auth.uid(),o.version_edicion,v.version_edicion,
 (SELECT jsonb_object_agg(k,jsonb_build_object('antes',antes->k,'despues',to_jsonb(v)->k)) FROM jsonb_object_keys(p_cambios) k));
 RETURN v;
END $function$;

CREATE OR REPLACE FUNCTION public.flota_aceptar_invitacion(p_token text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.flota_invitaciones%rowtype;v_email text;
begin
if auth.uid() is null or p_token !~ '^[a-f0-9]{48}$' then raise exception 'Invitacion invalida';end if;
select * into v from public.flota_invitaciones where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
if not found or v.revocada or v.vence_en<now() or v.usada_por is not null then raise exception 'Invitacion vencida o utilizada';end if;
select lower(email) into v_email from auth.users where id=auth.uid();
if v_email is distinct from v.correo then raise exception 'La invitacion corresponde a otro correo';end if;
if exists(select 1 from public.flota_usuarios where empresa_id=v.empresa_id and usuario_id=auth.uid()) then raise exception 'Usuario ya registrado en esta flota';end if;
insert into public.flota_usuarios(empresa_id,usuario_id,rol,nombre,telefono,puede_finanzas,puede_comisiones,puede_motoristas,puede_tiendas,puede_confirmar_rendiciones)
values(v.empresa_id,auth.uid(),v.rol,v.nombre,v.telefono,v.puede_finanzas,v.puede_comisiones,v.puede_motoristas,v.puede_tiendas,v.puede_confirmar_rendiciones);
update public.flota_invitaciones set usada_por=auth.uid() where id=v.id;
return v.rol;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_aceptar_tienda_propietaria(p_token text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_inv public.flota_tienda_propietarias%rowtype;v_tienda public.tiendas%rowtype;v_email text;v_perfil public.perfiles%rowtype;
begin
if auth.uid() is null or p_token !~ '^[a-f0-9]{48}$' then raise exception 'Invitación inválida';end if;
select * into v_inv from public.flota_tienda_propietarias where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
if not found or v_inv.vence_en<now() or v_inv.usada_por is not null then raise exception 'Invitación vencida o utilizada';end if;
select * into v_tienda from public.tiendas where id=v_inv.tienda_id and activo and usuario_id is null for update;
if not found then raise exception 'La tienda no está disponible';end if;
select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
if v_email is null or v_email is distinct from v_inv.correo then raise exception 'El correo no coincide o no está verificado';end if;
select * into v_perfil from public.perfiles where id=auth.uid();
if found and (v_perfil.rol<>'tienda' or v_perfil.empresa_id is distinct from v_tienda.empresa_id) then raise exception 'Esta cuenta tiene un rol incompatible';end if;
insert into public.perfiles(id,empresa_id,rol,nombre,telefono,activo) values(auth.uid(),v_tienda.empresa_id,'tienda',coalesce(v_tienda.responsable,v_tienda.nombre_comercial),v_tienda.telefono,true) on conflict(id) do nothing;
insert into public.tienda_miembros(tienda_id,usuario_id,rol,activo) values(v_tienda.id,auth.uid(),'propietario',true) on conflict(tienda_id,usuario_id) do nothing;
update public.tiendas set usuario_id=auth.uid() where id=v_tienda.id;
update public.flota_tienda_propietarias set usada_por=auth.uid() where id=v_inv.id;
return v_tienda.codigo;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_asignar_lote(p_pedidos uuid[], p_motorista uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_pct integer;v_total integer;v_valid integer;v_rutas integer;
begin
 v_total=coalesce(array_length(p_pedidos,1),0);
 if v_total<1 or v_total>200 or (select count(distinct x.id) from unnest(p_pedidos) as x(id))<>v_total then raise exception 'Selección inválida o duplicada';end if;
 select empresa_id,porcentaje_empresa_pct into v_empresa,v_pct from public.motoristas where id=p_motorista and activo for update;
 if v_empresa is null or v_pct not between 0 and 100 then raise exception 'Motorista o comisión inválidos';end if;
 if not exists(select 1 from public.flota_usuarios f where f.empresa_id=v_empresa and f.usuario_id=auth.uid() and f.activo and f.rol in('propietario','socio','operador')) then raise exception 'Sin permiso para repartir';end if;
 perform 1 from public.pedidos where id=any(p_pedidos) order by id for update;
 select count(*),count(distinct p.ruta_general_id) into v_valid,v_rutas
 from public.pedidos p join public.rutas_generales r on r.id=p.ruta_general_id
 where p.id=any(p_pedidos) and p.empresa_id=v_empresa and p.motorista_id is null
 and p.estado='pendiente' and p.numero_general>0
 and r.estado in('optimizada','en_reparto') and r.empresa_id=v_empresa;
 if v_valid<>v_total or v_rutas<>1 then raise exception 'Solo se pueden repartir pedidos pendientes, confirmados y de una misma ruta';end if;
 update public.pedidos set motorista_id=p_motorista,porcentaje_empresa_pct=v_pct,porcentaje_motorista_pct=100-v_pct,updated_at=now()
 where id=any(p_pedidos);
 update public.rutas_generales set estado='en_reparto'
 where id=(select p.ruta_general_id from public.pedidos p where p.id=any(p_pedidos) limit 1) and estado='optimizada';
 return v_total;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_cambiar_turno_pedido(p_pedido uuid, p_turno text, p_version integer)
 RETURNS pedidos
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.pedidos%rowtype;v_old text;
begin
 if p_turno not in ('manana','tarde') then raise exception 'Seleccioná Mañana o Tarde';end if;
 select * into v from public.pedidos where id=p_pedido for update;
 if not found then raise exception 'Pedido inexistente';end if;
 if not exists(select 1 from public.flota_usuarios u where u.usuario_id=auth.uid() and u.empresa_id=v.empresa_id and u.activo and u.rol in ('propietario','socio','operador')) then raise exception 'Sin autorización para modificar turnos';end if;
 if v.version_edicion is distinct from p_version then raise exception 'El pedido fue modificado. Actualizá antes de editar';end if;
 if v.estado<>'pendiente' or v.motorista_id is not null then raise exception 'No se puede cambiar el turno de un pedido ya asignado o procesado';end if;
 if exists(select 1 from public.movimientos_financieros x where x.pedido_id=v.id) then raise exception 'Pedido con movimientos financieros';end if;
 if v.ruta_general_id is not null and exists(select 1 from public.rutas_generales r where r.id=v.ruta_general_id and r.estado in ('optimizada','en_reparto','cerrada')) then raise exception 'Ruta confirmada: no se puede cambiar el turno sin reorganizar la ruta';end if;
 if v.turno=p_turno then return v;end if;
 v_old=v.turno;
 update public.pedidos set turno=p_turno,version_edicion=coalesce(version_edicion,0)+1,updated_at=now() where id=v.id returning * into v;
 insert into public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 values(v.id,v.empresa_id,v.tienda_id,auth.uid(),p_version,v.version_edicion,jsonb_build_object('turno',jsonb_build_object('antes',v_old,'despues',p_turno)));
 return v;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_cerrar_ruta(p_ruta uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_estado text;v_total integer;v_abiertos integer;
begin
select empresa_id,estado into v_empresa,v_estado from public.rutas_generales where id=p_ruta for update;
if v_empresa is null or v_estado not in('optimizada','en_reparto') then raise exception 'Ruta no disponible para cierre';end if;
if not exists(select 1 from public.flota_usuarios where empresa_id=v_empresa and usuario_id=auth.uid() and activo and rol in('propietario','socio','operador')) then raise exception 'No autorizado';end if;
select count(*),count(*) filter(where estado not in('entregado','rechazado','cancelado')) into v_total,v_abiertos from public.pedidos where ruta_general_id=p_ruta;
if v_total=0 then raise exception 'La ruta no contiene pedidos';end if;
if v_abiertos>0 then raise exception 'Quedan % pedidos pendientes o con incidencias; resolvelos antes de cerrar',v_abiertos;end if;
update public.rutas_generales set estado='cerrada' where id=p_ruta;
return true;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_configurar_comision_general(p_empresa uuid, p_porcentaje integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
if p_porcentaje is null or p_porcentaje not between 0 and 100 then raise exception 'Porcentaje inválido';end if;
if not exists(select 1 from public.flota_usuarios f where f.empresa_id=p_empresa and f.usuario_id=auth.uid() and f.activo and (f.rol='propietario' or f.puede_comisiones)) then raise exception 'Sin permiso para modificar comisiones';end if;
update public.empresas set porcentaje_empresa_general=p_porcentaje where id=p_empresa;
update public.motoristas set porcentaje_empresa_pct=p_porcentaje where empresa_id=p_empresa and not porcentaje_personalizado;
return true;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_configurar_comision_motorista(p_motorista uuid, p_porcentaje integer, p_personalizado boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_general integer;
begin
select empresa_id into v_empresa from public.motoristas where id=p_motorista for update;
if v_empresa is null then raise exception 'Motorista inexistente';end if;
if not exists(select 1 from public.flota_usuarios f where f.empresa_id=v_empresa and f.usuario_id=auth.uid() and f.activo and (f.rol='propietario' or f.puede_comisiones)) then raise exception 'Sin permiso para comisiones';end if;
if p_porcentaje not between 0 and 100 then raise exception 'Porcentaje inválido';end if;
select porcentaje_empresa_general into v_general from public.empresas where id=v_empresa;
update public.motoristas set porcentaje_personalizado=coalesce(p_personalizado,false),porcentaje_empresa_pct=case when p_personalizado then p_porcentaje else v_general end where id=p_motorista;
return true;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_confirmar_cierre(p_cierre uuid, p_efectivo_recibido integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_transfer integer;
begin
select transferencia_registrada into v_transfer from public.flota_cierres_motoristas where id=p_cierre;
if v_transfer is null then raise exception 'Rendición inexistente';end if;
if v_transfer<>0 then raise exception 'Rendición con transferencias: verificar con la confirmación completa';end if;
return public.flota_confirmar_cierre_completo(p_cierre,p_efectivo_recibido,0);
end $function$;

CREATE OR REPLACE FUNCTION public.flota_confirmar_cierre_completo(p_cierre uuid, p_efectivo_recibido integer, p_transferencia_confirmada integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.flota_cierres_motoristas%rowtype;
begin
select * into v from public.flota_cierres_motoristas where id=p_cierre for update;
if not found or v.estado<>'presentada' then raise exception 'Rendición no disponible para confirmar';end if;
if not exists(select 1 from public.flota_usuarios f where f.empresa_id=v.empresa_id and f.usuario_id=auth.uid() and f.activo and (f.rol='propietario' or f.puede_confirmar_rendiciones)) then raise exception 'Sin permiso financiero';end if;
if p_efectivo_recibido is null or p_transferencia_confirmada is null or p_efectivo_recibido<0 or p_transferencia_confirmada<0 then raise exception 'Importes inválidos';end if;
update public.flota_cierres_motoristas
set efectivo_recibido=p_efectivo_recibido,
transferencia_confirmada=p_transferencia_confirmada,
diferencia=p_efectivo_recibido-a_rendir_esperado,
diferencia_transferencia=p_transferencia_confirmada-transferencia_registrada,
estado=case when p_efectivo_recibido=a_rendir_esperado and p_transferencia_confirmada=transferencia_registrada then 'confirmada' else 'diferencia' end,
confirmado_por=auth.uid(),confirmed_at=now()
where id=p_cierre;
return true;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_crear_invitacion(p_empresa uuid, p_correo text, p_nombre text, p_rol text, p_telefono text DEFAULT NULL::text, p_finanzas boolean DEFAULT false, p_comisiones boolean DEFAULT false, p_motoristas boolean DEFAULT false, p_tiendas boolean DEFAULT false, p_rendiciones boolean DEFAULT false)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_token text;
begin
if auth.uid() is null or p_rol not in('socio','operador') or p_correo !~* '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' or length(trim(p_nombre))<2 then raise exception 'Datos invalidos';end if;
if not exists(select 1 from public.flota_usuarios where empresa_id=p_empresa and usuario_id=auth.uid() and rol='propietario' and activo) then raise exception 'Solo el propietario puede invitar usuarios';end if;
v_token=encode(extensions.gen_random_bytes(24),'hex');
insert into public.flota_invitaciones(empresa_id,correo,nombre,rol,telefono,token_hash,creado_por,vence_en,puede_finanzas,puede_comisiones,puede_motoristas,puede_tiendas,puede_confirmar_rendiciones)
values(p_empresa,lower(trim(p_correo)),trim(p_nombre),p_rol,p_telefono,encode(sha256(convert_to(v_token,'UTF8')),'hex'),auth.uid(),now()+interval '48 hours',p_finanzas,p_comisiones,p_motoristas,p_tiendas,p_rendiciones);
return v_token;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_crear_ruta(p_fecha date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_id uuid;
begin
select empresa_id into v_empresa from public.flota_usuarios where usuario_id=auth.uid() and activo and rol in ('propietario','socio','operador') order by created_at limit 1;
if v_empresa is null then raise exception 'No autorizado';end if;
if p_fecha is null then raise exception 'Fecha requerida';end if;
select id into v_id from public.rutas_generales where empresa_id=v_empresa and fecha=p_fecha and estado in ('abierta','optimizada') order by created_at limit 1 for update;
if v_id is null then
insert into public.rutas_generales(empresa_id,fecha,estado,version_optimizacion) values(v_empresa,p_fecha,'abierta',0) returning id into v_id;
end if;
return v_id;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_crear_ruta_turno(p_fecha date, p_turno text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_id uuid;
begin
 if p_fecha is null or p_turno not in ('manana','tarde','sin_definir') then raise exception 'Fecha y turno válidos requeridos';end if;
 select empresa_id into v_empresa from public.flota_usuarios where usuario_id=auth.uid() and activo and rol in('propietario','socio','operador') order by created_at limit 1;
 if v_empresa is null then raise exception 'No autorizado';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(p_fecha::text||p_turno));
 select id into v_id from public.rutas_generales where empresa_id=v_empresa and fecha=p_fecha and turno=p_turno and estado in('abierta','optimizada','en_reparto') order by created_at limit 1;
 if v_id is null then
  insert into public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion) values(v_empresa,p_fecha,p_turno,'abierta',0) returning id into v_id;
 end if;
 return v_id;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_impedir_cobros_con_caja_presentada()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
if new.motorista_id is not null and exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=new.motorista_id and c.fecha=(now() at time zone 'America/Asuncion')::date) then
raise exception 'Caja del motorista ya presentada para hoy: no se pueden añadir cobros';
end if;
return new;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_invitar_motorista(p_motorista uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto public.motoristas%rowtype;v_token text;
begin
select * into v_moto from public.motoristas where id=p_motorista;
if not found or not v_moto.activo or v_moto.usuario_id is not null then raise exception 'Motorista no disponible para invitación';end if;
if not exists(select 1 from public.flota_usuarios where empresa_id=v_moto.empresa_id and usuario_id=auth.uid() and activo and (rol='propietario' or puede_motoristas)) then raise exception 'No autorizado';end if;
if v_moto.email is null then raise exception 'Motorista sin correo';end if;
v_token=encode(extensions.gen_random_bytes(24),'hex');
insert into public.motorista_invitaciones(motorista_id,token_hash) values(p_motorista,encode(sha256(convert_to(v_token,'UTF8')),'hex'));
return v_token;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_leer_comision_general(p_empresa uuid)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_pct integer;
begin
if not exists(select 1 from public.flota_usuarios f where f.empresa_id=p_empresa and f.usuario_id=auth.uid() and f.activo) then raise exception 'No autorizado';end if;
select porcentaje_empresa_general into v_pct from public.empresas where id=p_empresa;
return v_pct;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_mis_solicitudes_tienda()
 RETURNS TABLE(estado text, nombre text, created_at timestamp with time zone)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select s.estado,s.nombre,s.created_at from public.flota_solicitudes_tienda s where s.usuario_id=auth.uid() order by s.created_at desc limit 1;
$function$;

CREATE OR REPLACE FUNCTION public.flota_puede_leer(p_empresa uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
select exists(select 1 from public.flota_usuarios x where x.empresa_id=p_empresa and x.usuario_id=auth.uid() and x.activo)
$function$;

CREATE OR REPLACE FUNCTION public.flota_reclamar_propiedad()
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_email text;v_empresa uuid;
begin
 if auth.uid() is null then raise exception 'Inicia sesión';end if;
 select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
 if v_email is null then raise exception 'Verifica tu correo electrónico';end if;
 select empresa_id into v_empresa from public.flota_propietarios_pendientes where correo=v_email and reclamado_en is null for update;
 if v_empresa is null then raise exception 'Correo no autorizado como propietario';end if;
 if exists(select 1 from public.flota_usuarios where empresa_id=v_empresa and rol='propietario') then raise exception 'Ya existe propietario';end if;
 insert into public.flota_usuarios(empresa_id,usuario_id,rol,activo,puede_finanzas,puede_comisiones,puede_motoristas,puede_tiendas,puede_confirmar_rendiciones)
 values(v_empresa,auth.uid(),'propietario',true,true,true,true,true,true);
 update public.flota_propietarios_pendientes set reclamado_en=now() where empresa_id=v_empresa;
 return true;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_registrar_motorista(p_empresa uuid, p_nombre text, p_telefono text, p_correo text, p_color text, p_pct integer DEFAULT 25)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_id uuid;v_general integer;
begin
if not exists(select 1 from public.flota_usuarios f where f.empresa_id=p_empresa and f.usuario_id=auth.uid() and f.activo and (f.rol='propietario' or f.puede_motoristas)) then raise exception 'No autorizado para registrar motoristas';end if;
if length(trim(coalesce(p_nombre,'')))<3 or length(trim(coalesce(p_telefono,'')))<6 or p_correo !~* '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' then raise exception 'Datos incompletos';end if;
if p_color !~ '^#[0-9a-fA-F]{6}$' or p_pct not between 0 and 100 then raise exception 'Color o porcentaje inválido';end if;
select porcentaje_empresa_general into v_general from public.empresas where id=p_empresa;
if v_general is null then raise exception 'Flota no encontrada';end if;
insert into public.motoristas(empresa_id,nombre,telefono,email,color_identificador,activo,porcentaje_empresa_pct,porcentaje_personalizado)
values(p_empresa,trim(p_nombre),trim(p_telefono),lower(trim(p_correo)),p_color,true,p_pct,p_pct<>v_general) returning id into v_id;
return v_id;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_registrar_tienda(p_empresa uuid, p_nombre text, p_responsable text, p_telefono text, p_email text, p_direccion text)
 RETURNS TABLE(tienda_id uuid, codigo text, invitacion text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_tienda public.tiendas%rowtype; v_token text; v_next int; v_codigo text;
begin
 if auth.uid() is null or not exists(
  select 1 from public.flota_usuarios f where f.empresa_id=p_empresa and f.usuario_id=auth.uid() and f.activo and (f.rol='propietario' or f.puede_tiendas)
 ) then raise exception 'Sin permiso para registrar tiendas'; end if;
 if length(trim(coalesce(p_nombre,'')))<3 or length(trim(coalesce(p_telefono,'')))<6 or coalesce(p_email,'') !~* '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' then
   raise exception 'Verificá nombre, teléfono y correo de la tienda'; end if;
 -- Exclusión por empresa: evitar códigos T repetidos durante altas simultáneas.
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(p_empresa::text), 17291);
 select coalesce(max(substring(t.codigo from 2)::int),0)+1 into v_next
 from public.tiendas t where t.empresa_id=p_empresa and t.codigo ~ '^T[0-9]{1,7}$';
 v_codigo='T'||v_next;
 insert into public.tiendas(empresa_id,codigo,nombre_comercial,responsable,telefono,email,direccion,activo)
 values(p_empresa,v_codigo,trim(p_nombre),nullif(trim(p_responsable),''),trim(p_telefono),lower(trim(p_email)),
 coalesce(nullif(trim(p_direccion),''),'Pendiente de completar'),true)
 returning * into v_tienda;
 v_token=encode(extensions.gen_random_bytes(24),'hex');
 insert into public.flota_tienda_propietarias(tienda_id,correo,token_hash)
 values(v_tienda.id,lower(trim(p_email)),encode(sha256(convert_to(v_token,'UTF8')),'hex'));
 return query select v_tienda.id,v_tienda.codigo,v_token;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_renovar_invitacion_tienda(p_tienda uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.tiendas%rowtype;v_token text;
begin
select * into v from public.tiendas where id=p_tienda and activo and usuario_id is null for update;
if not found then raise exception 'Tienda no disponible o ya activada';end if;
if not exists(select 1 from public.flota_usuarios f where f.empresa_id=v.empresa_id and f.usuario_id=auth.uid() and f.activo and (f.rol='propietario' or f.puede_tiendas)) then raise exception 'Sin permiso para invitar tiendas';end if;
if v.email is null then raise exception 'La tienda necesita correo de propietaria';end if;
update public.flota_tienda_propietarias set vence_en=now() where tienda_id=v.id and usada_por is null;
v_token=encode(extensions.gen_random_bytes(24),'hex');
insert into public.flota_tienda_propietarias(tienda_id,correo,token_hash) values(v.id,lower(v.email),encode(sha256(convert_to(v_token,'UTF8')),'hex'));
return v_token;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_reorganizar_pendientes_heredados(p_fecha date, p_turno text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_destino uuid;v_total integer;v_legacy uuid;
begin
 if p_turno not in('manana','tarde','sin_definir') or p_fecha is null then raise exception 'Fecha y turno inválidos';end if;
 select empresa_id into v_empresa from public.flota_usuarios where usuario_id=auth.uid() and activo and rol in('propietario','socio','operador') order by created_at limit 1;
 if v_empresa is null then raise exception 'No autorizado';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(p_fecha::text||p_turno));
 select id into v_destino from public.rutas_generales where empresa_id=v_empresa and fecha=p_fecha and turno=p_turno and estado='abierta' order by created_at limit 1 for update;
 if v_destino is null then raise exception 'Primero creá una ruta abierta para el turno';end if;
 -- Only move unassigned/unprocessed/unnumbered orders from legacy untyped OPEN routes.
 perform 1 from public.pedidos p join public.rutas_generales r on r.id=p.ruta_general_id
 where r.empresa_id=v_empresa and r.fecha=p_fecha and r.turno is null and r.estado='abierta'
 and p.empresa_id=v_empresa and p.estado='pendiente' and p.motorista_id is null and p.numero_general is null
 and coalesce(p.turno,'sin_definir')=p_turno order by p.id for update of p;
 update public.pedidos p set ruta_general_id=v_destino,updated_at=now()
 from public.rutas_generales r
 where r.id=p.ruta_general_id and r.empresa_id=v_empresa and r.fecha=p_fecha and r.turno is null and r.estado='abierta'
 and p.empresa_id=v_empresa and p.estado='pendiente' and p.motorista_id is null and p.numero_general is null
 and coalesce(p.turno,'sin_definir')=p_turno
 and not exists(select 1 from public.movimientos_financieros mf where mf.pedido_id=p.id);
 get diagnostics v_total=row_count;
 return v_total;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_revisar_solicitud_tienda(p_solicitud uuid, p_aprobar boolean)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.flota_solicitudes_tienda%rowtype;v_codigo text;v_num int;v_id uuid;v_profile public.perfiles%rowtype;
begin
 if not exists(select 1 from public.flota_usuarios u where u.usuario_id=auth.uid() and u.empresa_id='a0000000-0000-0000-0000-000000000001' and u.activo and (u.rol='propietario' or u.puede_tiendas)) then raise exception 'Sin autorización';end if;
 select * into s from public.flota_solicitudes_tienda where id=p_solicitud and estado='pendiente' for update;
 if not found then raise exception 'Solicitud inexistente o ya revisada';end if;
 if not p_aprobar then
  update public.flota_solicitudes_tienda set estado='rechazada',revisada_en=now(),revisada_por=auth.uid() where id=s.id;
  return 'rechazada';
 end if;
 if not exists(select 1 from auth.users where id=s.usuario_id and email_confirmed_at is not null and lower(email)=s.correo) then raise exception 'Correo de la solicitante sin verificar';end if;
 select * into v_profile from public.perfiles where id=s.usuario_id;
 if found and (v_profile.rol<>'tienda' or v_profile.empresa_id<>s.empresa_id) then raise exception 'Cuenta con rol incompatible';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(s.empresa_id::text),17291);
 select coalesce(max(substring(t.codigo from 2)::int),0)+1 into v_num from public.tiendas t where t.empresa_id=s.empresa_id and t.codigo ~ '^T[0-9]{1,7}$';
 v_codigo='T'||v_num;
 insert into public.tiendas(empresa_id,codigo,nombre_comercial,responsable,telefono,email,direccion,activo,usuario_id)
 values(s.empresa_id,v_codigo,s.nombre,s.responsable,s.telefono,s.correo,coalesce(nullif(s.direccion,''),'Pendiente de completar'),true,s.usuario_id) returning id into v_id;
 insert into public.perfiles(id,empresa_id,rol,nombre,telefono,activo) values(s.usuario_id,s.empresa_id,'tienda',s.responsable,s.telefono,true) on conflict(id) do update set nombre=excluded.nombre,telefono=excluded.telefono;
 insert into public.tienda_miembros(tienda_id,usuario_id,rol,activo) values(v_id,s.usuario_id,'propietario',true) on conflict(tienda_id,usuario_id) do update set activo=true;
 update public.flota_solicitudes_tienda set estado='aprobada',revisada_en=now(),revisada_por=auth.uid(),tienda_id=v_id where id=s.id;
 return v_codigo;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_revocar_usuario(p_empresa uuid, p_usuario uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if not exists(select 1 from public.flota_usuarios f where f.empresa_id=p_empresa and f.usuario_id=auth.uid() and f.activo and f.rol='propietario') then raise exception 'Solo propietario';end if;
 if not exists(select 1 from public.flota_usuarios where empresa_id=p_empresa and usuario_id=p_usuario and rol in('socio','operador')) then raise exception 'Usuario no revocable';end if;
 update public.flota_usuarios set activo=false where empresa_id=p_empresa and usuario_id=p_usuario and rol in('socio','operador');
 return found;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_solicitar_alta_tienda(p_nombre text, p_responsable text, p_telefono text, p_direccion text DEFAULT ''::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_email text;v_req public.flota_solicitudes_tienda%rowtype;
begin
 if auth.uid() is null then raise exception 'Iniciá sesión para solicitar el registro';end if;
 select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
 if v_email is null then raise exception 'Debés verificar tu correo electrónico antes de enviar la solicitud';end if;
 if length(trim(coalesce(p_nombre,'')))<3 or length(trim(coalesce(p_responsable,'')))<3 or length(trim(coalesce(p_telefono,'')))<6 then raise exception 'Completá nombre, responsable y teléfono';end if;
 insert into public.flota_solicitudes_tienda(empresa_id,usuario_id,nombre,responsable,telefono,correo,direccion)
 values('a0000000-0000-0000-0000-000000000001',auth.uid(),trim(p_nombre),trim(p_responsable),trim(p_telefono),v_email,trim(coalesce(p_direccion,'')))
 on conflict(empresa_id,usuario_id) do update
 set nombre=excluded.nombre,responsable=excluded.responsable,telefono=excluded.telefono,direccion=excluded.direccion,correo=excluded.correo,created_at=now()
 where flota_solicitudes_tienda.estado='pendiente'
 returning * into v_req;
 if v_req.id is null then raise exception 'Tu solicitud ya fue revisada. Contactá a la administración para otra evaluación.';end if;
 return 'pendiente';
end $function$;

CREATE OR REPLACE FUNCTION public.flota_solicitar_alta_tienda_simple()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_email text;v_empresa uuid:='a0000000-0000-0000-0000-000000000001';v_codigo text;v_next integer;v_tienda uuid;v_perfil public.perfiles%rowtype;
begin
 if auth.uid() is null then raise exception 'Iniciá sesión con tu correo y contraseña';end if;
 select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
 if v_email is null then raise exception 'Confirmá tu correo electrónico para activar tu tienda';end if;
 select t.id,t.codigo into v_tienda,v_codigo from public.tiendas t
 where t.usuario_id=auth.uid() and t.empresa_id=v_empresa and t.activo limit 1;
 if found then return v_codigo;end if;
 select * into v_perfil from public.perfiles where id=auth.uid();
 if found and (v_perfil.rol<>'tienda' or v_perfil.empresa_id is distinct from v_empresa)
 then raise exception 'Esta cuenta pertenece a otro rol. Ingresá por el acceso correspondiente';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),17291);
 insert into public.perfiles(id,empresa_id,rol,nombre,telefono,activo)
 values(auth.uid(),v_empresa,'tienda',split_part(v_email,'@',1),'',true)
 on conflict(id) do update set activo=true;
 select coalesce(max(substring(t.codigo from 2)::integer),0)+1 into v_next
 from public.tiendas t where t.empresa_id=v_empresa and t.codigo ~ '^T[0-9]{1,7}$';
 v_codigo='T'||v_next;
 insert into public.tiendas(empresa_id,codigo,usuario_id,nombre_comercial,responsable,telefono,email,direccion,activo)
 values(v_empresa,v_codigo,auth.uid(),'Tienda '||v_codigo,split_part(v_email,'@',1),'Pendiente de completar',v_email,'Pendiente de completar',true)
 returning id into v_tienda;
 insert into public.tienda_miembros(tienda_id,usuario_id,rol,activo)
 values(v_tienda,auth.uid(),'propietario',true)
 on conflict(tienda_id,usuario_id) do update set activo=true;
 update public.flota_solicitudes_tienda set estado='aprobada',tienda_id=v_tienda,revisada_en=now()
 where empresa_id=v_empresa and usuario_id=auth.uid() and estado='pendiente';
 return v_codigo;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_solicitudes_tienda_pendientes()
 RETURNS TABLE(id uuid, nombre text, responsable text, telefono text, correo text, direccion text, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if not exists(select 1 from public.flota_usuarios u where u.usuario_id=auth.uid() and u.empresa_id='a0000000-0000-0000-0000-000000000001' and u.activo and (u.rol='propietario' or u.puede_tiendas)) then raise exception 'Sin permiso';end if;
 return query select s.id,s.nombre,s.responsable,s.telefono,s.correo,s.direccion,s.created_at from public.flota_solicitudes_tienda s where s.estado='pendiente' and s.empresa_id='a0000000-0000-0000-0000-000000000001' order by s.created_at;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_usuarios_listar(p_empresa uuid)
 RETURNS TABLE(usuario_id uuid, rol text, activo boolean, nombre text, telefono text, correo text, puede_finanzas boolean, puede_comisiones boolean, puede_motoristas boolean, puede_tiendas boolean, puede_confirmar_rendiciones boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
if not exists(select 1 from public.flota_usuarios x where x.empresa_id=p_empresa and x.usuario_id=auth.uid() and x.activo and x.rol in('propietario','socio')) then raise exception 'No autorizado'; end if;
return query select x.usuario_id,x.rol,x.activo,x.nombre,x.telefono,u.email::text,x.puede_finanzas,x.puede_comisiones,x.puede_motoristas,x.puede_tiendas,x.puede_confirmar_rendiciones from public.flota_usuarios x join auth.users u on u.id=x.usuario_id where x.empresa_id=p_empresa order by x.created_at;
end $function$;

CREATE OR REPLACE FUNCTION public.listar_empleadas_tienda(p_tienda uuid)
 RETURNS TABLE(usuario_id uuid, correo text, activo boolean, creado_en timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or not exists(select 1 from public.tienda_miembros m where m.tienda_id=p_tienda and m.usuario_id=auth.uid() and m.rol='propietario' and m.activo) then raise exception 'Acceso no autorizado';end if;
 return query select m.usuario_id,u.email::text,m.activo,m.creado_en from public.tienda_miembros m join auth.users u on u.id=m.usuario_id where m.tienda_id=p_tienda and m.rol='empleado' order by m.creado_en;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_aceptar_invitacion(p_token text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_inv public.motorista_invitaciones%rowtype;v_moto public.motoristas%rowtype;v_email text;v_perfil public.perfiles%rowtype;
begin
if auth.uid() is null or p_token !~ '^[a-f0-9]{48}$' then raise exception 'Invitación inválida';end if;
select * into v_inv from public.motorista_invitaciones where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
if not found or v_inv.vence_en<now() or v_inv.usada_por is not null then raise exception 'Invitación vencida o utilizada';end if;
select * into v_moto from public.motoristas where id=v_inv.motorista_id and activo and usuario_id is null for update;
if not found then raise exception 'Motorista no disponible';end if;
select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
if v_email is null or v_email is distinct from lower(v_moto.email) then raise exception 'Correo no verificado o incorrecto';end if;
if exists(select 1 from public.motoristas where usuario_id=auth.uid()) then raise exception 'Cuenta ya vinculada a otro motorista';end if;
select * into v_perfil from public.perfiles where id=auth.uid();
if found and (v_perfil.rol<>'motorista' or v_perfil.empresa_id is distinct from v_moto.empresa_id) then raise exception 'Esta cuenta ya tiene un rol incompatible';end if;
insert into public.perfiles(id,empresa_id,rol,nombre,telefono,activo)
values(auth.uid(),v_moto.empresa_id,'motorista',v_moto.nombre,v_moto.telefono,true)
on conflict(id) do nothing;
update public.motoristas set usuario_id=auth.uid() where id=v_moto.id;
update public.motorista_invitaciones set usada_por=auth.uid() where id=v_inv.id;
return v_moto.id;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_actualizar_estado_pedido(p_pedido_id uuid, p_motorista_id uuid, p_nuevo_estado text, p_medio_cobro text, p_motivo_incidencia text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_estado text;v_moto uuid;
begin
select empresa_id,estado,motorista_id into v_empresa,v_estado,v_moto from public.pedidos where id=p_pedido_id for update;
if v_empresa is null or v_moto is distinct from p_motorista_id then raise exception 'Pedido no asignado';end if;
if not exists(select 1 from public.motoristas m where m.id=p_motorista_id and m.usuario_id=auth.uid() and m.empresa_id=v_empresa and m.activo)
and not exists(select 1 from public.flota_usuarios f where f.empresa_id=v_empresa and f.usuario_id=auth.uid() and f.activo and f.rol in('propietario','socio')) then raise exception 'No autorizado';end if;
if v_estado in('entregado','rechazado','cancelado') then raise exception 'Pedido cerrado';end if;
if p_nuevo_estado not in('entregado','rechazado','no_recibio','no_responde','pasa_manana') then raise exception 'Estado invalido';end if;
if p_nuevo_estado='entregado' and p_medio_cobro not in('efectivo','transferencia','pagado_previo') then raise exception 'Medio de cobro obligatorio';end if;
if p_nuevo_estado<>'entregado' and (p_motivo_incidencia is null or length(trim(p_motivo_incidencia))<3) then raise exception 'Motivo obligatorio';end if;
update public.pedidos set estado=p_nuevo_estado,medio_cobro=case when p_nuevo_estado='entregado' then p_medio_cobro else null end,motivo_incidencia=p_motivo_incidencia,updated_at=now() where id=p_pedido_id;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_cerrar_entrega(p_pedido uuid, p_medio text, p_estado text DEFAULT 'entregado'::text, p_motivo text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.pedidos%rowtype;v_pct integer;v_com integer;v_cobro integer;
begin
select * into v from public.pedidos where id=p_pedido for update;
if not found or v.motorista_id is null or v.estado not in('pendiente','no_responde','no_recibio','pasa_manana') then raise exception 'Pedido no disponible';end if;
if not exists(select 1 from public.motoristas m where m.id=v.motorista_id and m.usuario_id=auth.uid() and m.activo) and not exists(select 1 from public.flota_usuarios f where f.empresa_id=v.empresa_id and f.usuario_id=auth.uid() and f.activo and f.rol in('propietario','socio')) then raise exception 'No autorizado';end if;
if p_estado not in('entregado','rechazado') or (p_estado='entregado' and p_medio not in('efectivo','transferencia','pagado_previo')) then raise exception 'Estado o cobro inválido';end if;
if p_estado='rechazado' and length(trim(coalesce(p_motivo,'')))<3 then raise exception 'Motivo obligatorio';end if;
if p_estado='entregado' and ((v.modalidad_pago='todo_pagado' and p_medio<>'pagado_previo') or (v.modalidad_pago<>'todo_pagado' and p_medio='pagado_previo')) then raise exception 'Cobro incompatible con modalidad del pedido';end if;
v_pct=coalesce(v.porcentaje_empresa_pct,25);if v_pct<0 or v_pct>100 then raise exception 'Porcentaje inválido';end if;
v_com=round(v.precio_delivery::numeric*v_pct/100)::integer;
v_cobro=case when p_estado<>'entregado' or v.modalidad_pago='todo_pagado' then 0 when v.modalidad_pago='producto_pagado' then v.precio_delivery else v.precio_mercaderia+v.precio_delivery end;
insert into public.movimientos_financieros(empresa_id,pedido_id,motorista_id,tienda_id,monto_mercaderia,monto_delivery,comision_empresa,comision_motorista,es_rechazo_facturable,liquidado,efectivo_cobrado,transferencia_cobrada)
values(v.empresa_id,v.id,v.motorista_id,v.tienda_id,case when p_estado='entregado' then v.precio_mercaderia else 0 end,v.precio_delivery,v_com,v.precio_delivery-v_com,p_estado='rechazado',false,case when p_medio='efectivo' then v_cobro else 0 end,case when p_medio='transferencia' then v_cobro else 0 end);
update public.pedidos set estado=p_estado,medio_cobro=case when p_estado='entregado' then p_medio else null end,motivo_incidencia=p_motivo,updated_at=now() where id=v.id;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_compartir_gps(p_lat double precision, p_lng double precision, p_precision_m numeric)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
if p_lat is null or p_lng is null or p_lat not between -28 and -19 or p_lng not between -63 and -54 or p_precision_m is null or p_precision_m not between 0 and 5000 then raise exception 'Ubicación o precisión inválidas';end if;
update public.motoristas set gps_lat=p_lat,gps_lng=p_lng,gps_precision_m=p_precision_m,gps_actualizado_en=now() where usuario_id=auth.uid() and activo;
if not found then raise exception 'Motorista no autorizado';end if;
return true;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_guardar_orden(p_pedidos uuid[])
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto uuid;v_total integer;v_fecha date;
begin
select id into v_moto from public.motoristas where usuario_id=auth.uid() and activo limit 1;
if v_moto is null then raise exception 'Motorista no autorizado';end if;
v_total=coalesce(array_length(p_pedidos,1),0);
if v_total<2 or v_total>26 or (select count(distinct x) from unnest(p_pedidos) as x)<>v_total then raise exception 'Orden incompleto o duplicado';end if;
if (select count(*) from public.pedidos where id=any(p_pedidos) and motorista_id=v_moto and estado in('pendiente','no_responde','pasa_manana','no_recibio') and lat is not null and lng is not null)<>v_total then raise exception 'La ruta incluye pedidos no disponibles';end if;
v_fecha=(now() at time zone 'America/Asuncion')::date;
perform pg_advisory_xact_lock(hashtext(v_moto::text||v_fecha::text));
delete from public.motorista_ordenes_pedidos where motorista_id=v_moto and fecha=v_fecha;
insert into public.motorista_ordenes_pedidos(motorista_id,fecha,pedido_id,posicion)
select v_moto,v_fecha,x.id,x.posicion::integer from unnest(p_pedidos) with ordinality as x(id,posicion);
return true;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_presentar_cierre(p_fecha date, p_efectivo integer, p_transferencia integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto public.motoristas%rowtype;v_cash integer;v_transfer integer;v_comm integer;v_emp integer;v_del_comm integer;v_render integer;v_id uuid;
begin
select * into v_moto from public.motoristas where usuario_id=auth.uid() and activo limit 1;
if not found then raise exception 'Motorista no autorizado';end if;
if p_fecha is null or p_fecha> (now() at time zone 'America/Asuncion')::date or p_efectivo<0 or p_transferencia<0 then raise exception 'Importes o fecha inválidos';end if;
perform pg_advisory_xact_lock(hashtext(v_moto.id::text||p_fecha::text));
if exists(select 1 from public.flota_cierres_motoristas where motorista_id=v_moto.id and fecha=p_fecha) then raise exception 'Ya existe cierre del día';end if;
select coalesce(sum(m.efectivo_cobrado),0),coalesce(sum(m.transferencia_cobrada),0),coalesce(sum(m.comision_motorista),0),coalesce(sum(m.comision_empresa),0),coalesce(sum(case when p.estado='entregado' then m.comision_motorista else 0 end))
into v_cash,v_transfer,v_comm,v_emp,v_del_comm
from public.movimientos_financieros m join public.pedidos p on p.id=m.pedido_id
where m.motorista_id=v_moto.id and (m.created_at at time zone 'America/Asuncion')::date=p_fecha;
if v_moto.modalidad_liquidacion='retener_comision' then v_render=greatest(0,v_cash-least(v_cash,v_del_comm));else v_render=v_cash;end if;
insert into public.flota_cierres_motoristas(empresa_id,motorista_id,fecha,efectivo_esperado,transferencia_registrada,comision_motorista,comision_empresa,a_rendir_esperado,efectivo_declarado,transferencia_declarada,presentado_por)
values(v_moto.empresa_id,v_moto.id,p_fecha,v_cash,v_transfer,v_comm,v_emp,v_render,p_efectivo,p_transferencia,auth.uid()) returning id into v_id;
return v_id;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_registrar_rechazo_detallado(p_pedido uuid, p_motivo text, p_responsable text, p_importe integer DEFAULT 0, p_medio text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.pedidos%rowtype;v_mov public.movimientos_financieros%rowtype;v_motorista_pct integer;
begin
select * into v from public.pedidos where id=p_pedido for update;
if not found or v.motorista_id is null or v.estado not in ('pendiente','no_responde','no_recibio','pasa_manana') then raise exception 'Pedido no disponible para rechazo';end if;
if not exists(select 1 from public.motoristas m where m.id=v.motorista_id and m.usuario_id=auth.uid() and m.activo) and not exists(select 1 from public.flota_usuarios f where f.empresa_id=v.empresa_id and f.usuario_id=auth.uid() and f.activo and f.rol in('propietario','socio')) then raise exception 'No autorizado';end if;
if length(trim(coalesce(p_motivo,'')))<3 then raise exception 'Especificá motivo de rechazo';end if;
if p_responsable not in ('cliente','tienda','pendiente') then raise exception 'Responsable del pago inválido';end if;
if p_importe is null or p_importe<0 or p_importe>v.precio_delivery then raise exception 'Importe no válido para costo de envío';end if;
if (p_importe>0 and (p_medio not in('efectivo','transferencia') or p_responsable='pendiente')) or (p_importe=0 and p_medio is not null) then raise exception 'Indicá quién pagó, importe y medio de cobro coherentes';end if;
if exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=v.motorista_id and c.fecha=(now() at time zone 'America/Asuncion')::date) then raise exception 'Caja presentada; solicitar ajuste administrativo';end if;
perform public.motorista_cerrar_entrega(p_pedido,null,'rechazado',p_motivo);
select * into v_mov from public.movimientos_financieros where pedido_id=v.id for update;
if not found then raise exception 'No se registró movimiento de rechazo';end if;
if exists(select 1 from public.flota_rechazos_detalle where pedido_id=v.id) then raise exception 'Rechazo ya registrado';end if;
update public.movimientos_financieros set efectivo_cobrado=case when p_medio='efectivo' then p_importe else 0 end,transferencia_cobrada=case when p_medio='transferencia' then p_importe else 0 end where id=v_mov.id;
insert into public.flota_rechazos_detalle(pedido_id,empresa_id,tienda_id,motorista_id,responsable_pago,importe_cobrado,medio_cobro,importe_pendiente,comision_motorista,comision_empresa,motivo,registrado_por)
values(v.id,v.empresa_id,v.tienda_id,v.motorista_id,p_responsable,p_importe,p_medio,v.precio_delivery-p_importe,v_mov.comision_motorista,v_mov.comision_empresa,trim(p_motivo),auth.uid());
return true;
end $function$;

CREATE OR REPLACE FUNCTION public.provisionar_tienda_v2()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if new.empresa_id <> 'a0000000-0000-0000-0000-000000000001'::uuid then raise exception 'Empresa no autorizada'; end if;
 insert into public.perfiles(id,empresa_id,rol,nombre,telefono,activo) values (new.id,new.empresa_id,'tienda',new.nombre,new.telefono,true) on conflict(id) do nothing;
 insert into public.tiendas(empresa_id,usuario_id,nombre_comercial,responsable,telefono,email,direccion,activo)
 select new.empresa_id,new.id,new.nombre,new.nombre,new.telefono,u.email,new.direccion,true from auth.users u where u.id=new.id
 on conflict do nothing;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.registrar_movimiento_financiero()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare v_pct integer;v_com integer;v_cobro integer;
begin
if new.estado in ('entregado','rechazado') and old.estado='pendiente' then
v_pct=coalesce(new.porcentaje_empresa_pct,25);
if v_pct not between 0 and 100 then raise exception 'Comisión incorrecta';end if;
v_com=round(new.precio_delivery::numeric*v_pct/100)::integer;
v_cobro=case when new.estado<>'entregado' or new.modalidad_pago='todo_pagado' then 0 when new.modalidad_pago='producto_pagado' then new.precio_delivery else new.precio_mercaderia+new.precio_delivery end;
insert into public.movimientos_financieros(empresa_id,pedido_id,motorista_id,tienda_id,monto_mercaderia,monto_delivery,comision_empresa,comision_motorista,es_rechazo_facturable,liquidado,efectivo_cobrado,transferencia_cobrada)
values(new.empresa_id,new.id,new.motorista_id,new.tienda_id,case when new.estado='entregado' then new.precio_mercaderia else 0 end,new.precio_delivery,v_com,new.precio_delivery-v_com,new.estado='rechazado',false,case when new.medio_cobro='efectivo' then v_cobro else 0 end,case when new.medio_cobro='transferencia' then v_cobro else 0 end)
on conflict(pedido_id) do nothing;
end if;
return new;
end $function$;

CREATE OR REPLACE FUNCTION public.revocar_empleado_tienda(p_tienda uuid, p_usuario uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or not exists(select 1 from public.tienda_miembros m where m.tienda_id=p_tienda and m.usuario_id=auth.uid() and m.rol='propietario' and m.activo) then raise exception 'No autorizado';end if;
 update public.tienda_miembros set activo=false where tienda_id=p_tienda and usuario_id=p_usuario and rol='empleado';
 return found;
end $function$;

CREATE OR REPLACE FUNCTION public.tienda_actualizar_configuracion(p_nombre text, p_telefono text, p_direccion text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_tienda uuid;
begin
 select m.tienda_id into v_tienda from public.tienda_miembros m join public.tiendas t on t.id=m.tienda_id where m.usuario_id=auth.uid() and m.rol='propietario' and m.activo and t.activo limit 1;
 if v_tienda is null then raise exception 'Solo la propietaria puede editar la tienda';end if;
 if length(trim(coalesce(p_nombre,'')))<3 then raise exception 'Nombre de tienda demasiado corto';end if;
 update public.tiendas set nombre_comercial=left(trim(p_nombre),100),telefono=left(trim(coalesce(p_telefono,'')),40),direccion=left(trim(coalesce(p_direccion,'')),300) where id=v_tienda;
end $function$;

CREATE OR REPLACE FUNCTION public.tienda_actualizar_configuracion_gps(p_nombre text, p_telefono text, p_direccion text, p_lat double precision, p_lng double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_tienda uuid;
begin
 select m.tienda_id into v_tienda from public.tienda_miembros m join public.tiendas t on t.id=m.tienda_id where m.usuario_id=auth.uid() and m.rol='propietario' and m.activo and t.activo limit 1;
 if v_tienda is null then raise exception 'Solo la propietaria puede editar la tienda';end if;
 if length(trim(coalesce(p_nombre,'')))<3 then raise exception 'Ingresá el nombre comercial';end if;
 if (p_lat is null)<>(p_lng is null) then raise exception 'GPS incompleto';end if;
 if p_lat is not null and (p_lat < -28 or p_lat > -19 or p_lng < -63 or p_lng > -54) then raise exception 'La ubicación GPS está fuera de Paraguay';end if;
 update public.tiendas set nombre_comercial=left(trim(p_nombre),100),telefono=left(trim(coalesce(p_telefono,'')),40),direccion=left(trim(coalesce(p_direccion,'')),300),lat=p_lat,lng=p_lng where id=v_tienda;
end $function$;

CREATE OR REPLACE FUNCTION public.tienda_agregar_pedido_a_ruta(p_pedido uuid, p_turno text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.pedidos%rowtype;r uuid;day date:=(now() at time zone 'America/Asuncion')::date;
begin
 if p_turno is null or p_turno not in('manana','tarde') then raise exception 'Seleccioná Mañana o Tarde';end if;
 if auth.uid() is null then raise exception 'Iniciá sesión';end if;
 select * into v from public.pedidos where id=p_pedido for update;
 if not found then raise exception 'Pedido inexistente';end if;
 if not exists(select 1 from public.tienda_miembros m join public.tiendas t on t.id=m.tienda_id where m.tienda_id=v.tienda_id and m.usuario_id=auth.uid() and m.activo and t.activo and t.empresa_id=v.empresa_id) then raise exception 'No autorizado';end if;
 if v.estado<>'pendiente' or v.motorista_id is not null then raise exception 'Pedido ya asignado o procesado';end if;
 if v.lat is null or v.lng is null or v.lat not between -28 and -19 or v.lng not between -63 and -54 then raise exception 'GPS inválido';end if;
 if exists(select 1 from public.movimientos_financieros m where m.pedido_id=v.id) then raise exception 'Pedido con cobros: no puede cambiarse';end if;
 if v.ruta_general_id is not null then
  select id into r from public.rutas_generales where id=v.ruta_general_id and empresa_id=v.empresa_id and estado='abierta' and turno=p_turno;
  if r is not null and v.turno=p_turno then return r;end if;
  if exists(select 1 from public.rutas_generales where id=v.ruta_general_id and estado<>'abierta') then raise exception 'Ruta confirmada: solicitá reorganización a Central';end if;
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v.empresa_id::text),pg_catalog.hashtext(day::text||p_turno));
 select id into r from public.rutas_generales where empresa_id=v.empresa_id and fecha=day and turno=p_turno and estado='abierta' limit 1;
 if r is null then insert into public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion) values(v.empresa_id,day,p_turno,'abierta',0) returning id into r;end if;
 update public.pedidos set ruta_general_id=r,turno=p_turno,numero_general=null,version_edicion=coalesce(version_edicion,0)+1,updated_at=now() where id=v.id;
 return r;
end $function$;

CREATE OR REPLACE FUNCTION public.tienda_agregar_pedido_a_ruta(p_pedido uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.pedidos%rowtype; r uuid; day date:=(now() at time zone 'America/Asuncion')::date;
begin
 if auth.uid() is null then raise exception 'Iniciá sesión';end if;
 select * into v from public.pedidos where id=p_pedido for update;
 if not found then raise exception 'Pedido inexistente';end if;
 if not exists(select 1 from public.tienda_miembros m join public.tiendas t on t.id=m.tienda_id where m.tienda_id=v.tienda_id and m.usuario_id=auth.uid() and m.activo and t.activo and t.empresa_id=v.empresa_id) then raise exception 'No autorizado para esta tienda';end if;
 if v.estado<>'pendiente' or v.motorista_id is not null then raise exception 'Pedido asignado o procesado: no puede agregarse';end if;
 if v.lat is null or v.lng is null or v.lat not between -28 and -19 or v.lng not between -63 and -54 then raise exception 'Primero corregí la ubicación GPS del pedido';end if;
 if exists(select 1 from public.movimientos_financieros m where m.pedido_id=v.id) then raise exception 'Pedido con cobros bloqueado';end if;
 if v.ruta_general_id is not null then
  select id into r from public.rutas_generales where id=v.ruta_general_id;
  if r is not null then return r;end if;
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v.empresa_id::text),17524);
 select id into r from public.rutas_generales where empresa_id=v.empresa_id and fecha=day and estado='abierta' order by created_at limit 1;
 if r is null then
  insert into public.rutas_generales(empresa_id,fecha,estado,version_optimizacion) values(v.empresa_id,day,'abierta',0) returning id into r;
 end if;
 update public.pedidos set ruta_general_id=r,numero_general=null,updated_at=now() where id=v.id;
 return r;
end $function$;

CREATE TRIGGER impedir_cobros_tras_cierre BEFORE INSERT ON movimientos_financieros FOR EACH ROW EXECUTE FUNCTION flota_impedir_cobros_con_caja_presentada();

CREATE TRIGGER deliveryya_fijar_autor_pedido_trg BEFORE INSERT ON pedidos FOR EACH ROW EXECUTE FUNCTION deliveryya_fijar_autor_pedido();

CREATE TRIGGER trigger_pedido_finanzas AFTER UPDATE ON pedidos FOR EACH ROW EXECUTE FUNCTION registrar_movimiento_financiero();

CREATE TRIGGER provisionar_tienda_v2_trigger AFTER INSERT ON tienda_cuentas_v2 FOR EACH ROW EXECUTE FUNCTION provisionar_tienda_v2();

CREATE TRIGGER deliveryya_propietario_membresia_trg AFTER INSERT ON tiendas FOR EACH ROW EXECUTE FUNCTION deliveryya_propietario_membresia();

CREATE TRIGGER deliveryya_tienda_codigo BEFORE INSERT OR UPDATE ON tiendas FOR EACH ROW EXECUTE FUNCTION deliveryya_asignar_codigo_tienda();

CREATE OR REPLACE VIEW public."vista_auditoria_incidencias" AS  SELECT p.id AS pedido_id,
    p.numero_general,
    p.estado,
    p.motivo_incidencia,
    p.nombre_cliente,
    p.telefono_cliente,
    t.nombre_comercial AS tienda_nombre,
    m.nombre AS motorista_nombre,
    p.updated_at AS fecha_incidencia
   FROM pedidos p
     JOIN tiendas t ON p.tienda_id = t.id
     LEFT JOIN motoristas m ON p.motorista_id = m.id
  WHERE p.estado = ANY (ARRAY['rechazado'::text, 'no_recibio'::text, 'no_responde'::text, 'pasa_manana'::text]);;

CREATE OR REPLACE VIEW public."vista_cierre_financiero_admin" AS  SELECT e.id AS empresa_id,
    COALESCE(sum(mf.monto_delivery), 0::bigint) AS total_delivery_facturado,
    COALESCE(sum(mf.comision_empresa), 0::bigint) AS total_ingreso_empresa,
    COALESCE(sum(mf.comision_motorista), 0::bigint) AS total_ganancia_motoristas,
    COALESCE(sum(mf.monto_mercaderia), 0::bigint) AS total_mercaderia_movilizada,
    count(mf.id) AS total_envios_liquidados
   FROM empresas e
     LEFT JOIN movimientos_financieros mf ON e.id = mf.empresa_id
  GROUP BY e.id;;

CREATE OR REPLACE VIEW public."vista_pedidos_admin" AS  SELECT p.id AS pedido_id,
    p.numero_general,
    p.estado,
    p.nombre_cliente,
    p.telefono_cliente,
    p.direccion_cliente,
    p.precio_mercaderia,
    p.precio_delivery,
    p.modalidad_pago,
    p.medio_cobro,
    p.created_at,
    t.nombre_comercial AS tienda_nombre,
    t.telefono AS tienda_telefono,
    m.nombre AS motorista_nombre,
    m.color_identificador AS motorista_color,
    rg.fecha AS fecha_ruta
   FROM pedidos p
     JOIN tiendas t ON p.tienda_id = t.id
     LEFT JOIN motoristas m ON p.motorista_id = m.id
     LEFT JOIN rutas_generales rg ON p.ruta_general_id = rg.id;;

CREATE OR REPLACE VIEW public."vista_pedidos_motorista" AS  SELECT p.id AS pedido_id,
    p.motorista_id,
    p.numero_general,
    p.estado,
    p.nombre_cliente,
    p.telefono_cliente,
    p.direccion_cliente,
    p.referencias,
    p.observaciones,
    p.precio_mercaderia,
    p.precio_delivery,
    p.modalidad_pago,
        CASE
            WHEN p.modalidad_pago = 'pendiente'::text THEN p.precio_mercaderia + p.precio_delivery
            WHEN p.modalidad_pago = 'producto_pagado'::text THEN p.precio_delivery
            ELSE 0
        END AS total_a_cobrar,
    t.nombre_comercial AS tienda_nombre,
    t.telefono AS tienda_telefono
   FROM pedidos p
     JOIN tiendas t ON p.tienda_id = t.id;;

ALTER TABLE public."flota_cierres_motoristas" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_ver_cierres_finanzas" ON public."flota_cierres_motoristas" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = flota_cierres_motoristas.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo AND ((f.rol = 'propietario'::text) OR f.puede_finanzas))))) ;

ALTER TABLE public."flota_cierres_motoristas" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "motorista_ver_cierre" ON public."flota_cierres_motoristas" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = flota_cierres_motoristas.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo)))) ;

ALTER TABLE public."flota_rechazos_detalle" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_rechazos_lectura_admin" ON public."flota_rechazos_detalle" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = flota_rechazos_detalle.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo AND ((f.rol = 'propietario'::text) OR f.puede_finanzas))))) ;

ALTER TABLE public."flota_rechazos_detalle" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_rechazos_lectura_motorista" ON public."flota_rechazos_detalle" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = flota_rechazos_detalle.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo)))) ;

ALTER TABLE public."flota_usuarios" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_usuarios_leer_propio" ON public."flota_usuarios" AS PERMISSIVE FOR SELECT TO public USING ((usuario_id = ( SELECT auth.uid() AS uid))) ;

ALTER TABLE public."motorista_ordenes_pedidos" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "motorista_leer_orden" ON public."motorista_ordenes_pedidos" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = motorista_ordenes_pedidos.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo)))) ;

ALTER TABLE public."motoristas" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_motoristas_lectura" ON public."motoristas" AS PERMISSIVE FOR SELECT TO public USING (flota_puede_leer(empresa_id)) ;

ALTER TABLE public."motoristas" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "motorista_ver_su_ficha" ON public."motoristas" AS PERMISSIVE FOR SELECT TO public USING ((usuario_id = ( SELECT auth.uid() AS uid))) ;

ALTER TABLE public."movimientos_financieros" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_movimientos_financieros_autorizados" ON public."movimientos_financieros" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = movimientos_financieros.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo AND ((f.rol = 'propietario'::text) OR f.puede_finanzas))))) ;

ALTER TABLE public."movimientos_financieros" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "motorista_movimientos_propio" ON public."movimientos_financieros" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = movimientos_financieros.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo)))) ;

ALTER TABLE public."pedidos" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_pedidos_lectura" ON public."pedidos" AS PERMISSIVE FOR SELECT TO public USING (flota_puede_leer(empresa_id)) ;

ALTER TABLE public."pedidos" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lectura_pedidos_admin" ON public."pedidos" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM perfiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND (p.empresa_id = pedidos.empresa_id) AND p.activo AND (p.rol = ANY (ARRAY['admin'::text, 'superadmin'::text])))))) ;

ALTER TABLE public."pedidos" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "motorista_ver_sus_pedidos" ON public."pedidos" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = pedidos.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo)))) ;

ALTER TABLE public."pedidos" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pedido_crear_miembro" ON public."pedidos" AS PERMISSIVE FOR INSERT TO public  WITH CHECK (((estado = 'pendiente'::text) AND (motorista_id IS NULL) AND (ruta_general_id IS NULL) AND (numero_general IS NULL) AND (medio_cobro IS NULL) AND (EXISTS ( SELECT 1
   FROM tienda_miembros m
  WHERE ((m.tienda_id = pedidos.tienda_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))) AND (EXISTS ( SELECT 1
   FROM tiendas t
  WHERE ((t.id = pedidos.tienda_id) AND (t.empresa_id = pedidos.empresa_id) AND t.activo)))));

ALTER TABLE public."pedidos" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pedido_leer_miembro" ON public."pedidos" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM tienda_miembros m
  WHERE ((m.tienda_id = pedidos.tienda_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo AND ((m.rol = 'propietario'::text) OR ((m.rol = 'empleado'::text) AND (pedidos.creado_por = ( SELECT auth.uid() AS uid)))))))) ;

ALTER TABLE public."pedidos_ediciones" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pedidos_ediciones_ver_autorizados" ON public."pedidos_ediciones" AS PERMISSIVE FOR SELECT TO public USING (((EXISTS ( SELECT 1
   FROM tienda_miembros m
  WHERE ((m.tienda_id = pedidos_ediciones.tienda_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))) OR (EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = pedidos_ediciones.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo))) OR (EXISTS ( SELECT 1
   FROM (motoristas m
     JOIN pedidos p ON ((p.motorista_id = m.id)))
  WHERE ((p.id = pedidos_ediciones.pedido_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))))) ;

ALTER TABLE public."perfiles" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "perfil_autoregistro_tienda" ON public."perfiles" AS PERMISSIVE FOR INSERT TO public  WITH CHECK (((id = ( SELECT auth.uid() AS uid)) AND (empresa_id = 'a0000000-0000-0000-0000-000000000001'::uuid) AND (rol = 'tienda'::text) AND (activo = true)));

ALTER TABLE public."perfiles" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "perfil_lectura_propia" ON public."perfiles" AS PERMISSIVE FOR SELECT TO public USING ((id = ( SELECT auth.uid() AS uid))) ;

ALTER TABLE public."rendiciones" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_rendiciones_finanzas" ON public."rendiciones" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = rendiciones.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo AND ((f.rol = 'propietario'::text) OR f.puede_finanzas))))) ;

ALTER TABLE public."rutas_generales" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_rutas_lectura" ON public."rutas_generales" AS PERMISSIVE FOR SELECT TO public USING (flota_puede_leer(empresa_id)) ;

ALTER TABLE public."tienda_cuentas_v2" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tienda_v2_select" ON public."tienda_cuentas_v2" AS PERMISSIVE FOR SELECT TO public USING ((id = ( SELECT auth.uid() AS uid))) ;

ALTER TABLE public."tienda_miembros" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lectura_miembros_autorizados" ON public."tienda_miembros" AS PERMISSIVE FOR SELECT TO public USING ((usuario_id = ( SELECT auth.uid() AS uid))) ;

ALTER TABLE public."tienda_miembros" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "miembros_leer_propio" ON public."tienda_miembros" AS PERMISSIVE FOR SELECT TO public USING ((usuario_id = ( SELECT auth.uid() AS uid))) ;

ALTER TABLE public."tiendas" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "flota_tiendas_lectura" ON public."tiendas" AS PERMISSIVE FOR SELECT TO public USING (flota_puede_leer(empresa_id)) ;

ALTER TABLE public."tiendas" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lectura_tiendas_admin" ON public."tiendas" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM perfiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND (p.empresa_id = tiendas.empresa_id) AND p.activo AND (p.rol = ANY (ARRAY['admin'::text, 'superadmin'::text])))))) ;

ALTER TABLE public."tiendas" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tienda_leer_miembro" ON public."tiendas" AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1
   FROM tienda_miembros m
  WHERE ((m.tienda_id = tiendas.id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo)))) ;