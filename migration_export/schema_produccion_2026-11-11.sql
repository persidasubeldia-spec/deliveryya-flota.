-- Snapshot del esquema public: 2026-11-11. Extraccion READ-ONLY de pg_catalog.
-- SOLO DEFINICIONES: sin filas. No ejecutar sobre produccion.
-- Para restaurar en una instancia nueva, revisar orden/dependencias y permisos.

CREATE SCHEMA IF NOT EXISTS public;

-- types



-- seq

CREATE SEQUENCE IF NOT EXISTS public.deliveryya_codigo_tienda_seq INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS public.pedidos_ediciones_id_seq INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1 NO CYCLE;

-- tables

CREATE TABLE IF NOT EXISTS public.clientes (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  tienda_id uuid NOT NULL,
  nombre text NOT NULL,
  telefono text NOT NULL,
  direccion text NOT NULL,
  lat double precision,
  lng double precision,
  referencias text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.empresas (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  nombre text NOT NULL,
  ruc text,
  telefono text,
  direccion text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  porcentaje_empresa_general integer DEFAULT 25 NOT NULL
);

CREATE TABLE IF NOT EXISTS public.flota_cierres_motoristas (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  empresa_id uuid NOT NULL,
  motorista_id uuid NOT NULL,
  fecha date NOT NULL,
  efectivo_esperado integer DEFAULT 0 NOT NULL,
  transferencia_registrada integer DEFAULT 0 NOT NULL,
  comision_motorista integer DEFAULT 0 NOT NULL,
  comision_empresa integer DEFAULT 0 NOT NULL,
  a_rendir_esperado integer DEFAULT 0 NOT NULL,
  efectivo_declarado integer DEFAULT 0 NOT NULL,
  transferencia_declarada integer DEFAULT 0 NOT NULL,
  efectivo_recibido integer,
  diferencia integer,
  estado text DEFAULT 'presentada'::text NOT NULL,
  presentado_por uuid NOT NULL,
  confirmado_por uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  confirmed_at timestamp with time zone,
  transferencia_confirmada integer,
  diferencia_transferencia integer
);

CREATE TABLE IF NOT EXISTS public.flota_compensaciones_tienda (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  empresa_id uuid NOT NULL,
  tienda_id uuid NOT NULL,
  pedido_id uuid NOT NULL,
  fecha_rendicion date NOT NULL,
  importe integer NOT NULL,
  referencia text NOT NULL,
  confirmado_por uuid NOT NULL,
  confirmado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.flota_cupo_optimizacion_google (
  clave text NOT NULL,
  cantidad integer DEFAULT 0 NOT NULL,
  actualizado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.flota_invitaciones (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  empresa_id uuid NOT NULL,
  correo text NOT NULL,
  rol text NOT NULL,
  nombre text NOT NULL,
  telefono text,
  token_hash text NOT NULL,
  creado_por uuid NOT NULL,
  vence_en timestamp with time zone NOT NULL,
  usada_por uuid,
  revocada boolean DEFAULT false NOT NULL,
  puede_finanzas boolean DEFAULT false NOT NULL,
  puede_comisiones boolean DEFAULT false NOT NULL,
  puede_motoristas boolean DEFAULT false NOT NULL,
  puede_tiendas boolean DEFAULT false NOT NULL,
  puede_confirmar_rendiciones boolean DEFAULT false NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.flota_pagos_tienda (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  empresa_id uuid NOT NULL,
  tienda_id uuid NOT NULL,
  fecha_rendicion date NOT NULL,
  importe integer NOT NULL,
  medio text NOT NULL,
  referencia text NOT NULL,
  confirmado_por uuid NOT NULL,
  confirmado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.flota_propietarios_pendientes (
  empresa_id uuid NOT NULL,
  correo text NOT NULL,
  creado_en timestamp with time zone DEFAULT now() NOT NULL,
  reclamado_en timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public.flota_rechazos_detalle (
  pedido_id uuid NOT NULL,
  empresa_id uuid NOT NULL,
  tienda_id uuid NOT NULL,
  motorista_id uuid NOT NULL,
  responsable_pago text NOT NULL,
  importe_cobrado integer DEFAULT 0 NOT NULL,
  medio_cobro text,
  importe_pendiente integer NOT NULL,
  comision_motorista integer NOT NULL,
  comision_empresa integer NOT NULL,
  motivo text NOT NULL,
  registrado_por uuid NOT NULL,
  registrado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.flota_solicitudes_tienda (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  empresa_id uuid NOT NULL,
  usuario_id uuid NOT NULL,
  nombre text NOT NULL,
  responsable text NOT NULL,
  telefono text NOT NULL,
  correo text NOT NULL,
  direccion text,
  estado text DEFAULT 'pendiente'::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  revisada_en timestamp with time zone,
  revisada_por uuid,
  tienda_id uuid
);

CREATE TABLE IF NOT EXISTS public.flota_tienda_propietarias (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  tienda_id uuid NOT NULL,
  correo text NOT NULL,
  token_hash text NOT NULL,
  vence_en timestamp with time zone DEFAULT (now() + '72:00:00'::interval) NOT NULL,
  usada_por uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.flota_usuarios (
  empresa_id uuid NOT NULL,
  usuario_id uuid NOT NULL,
  rol text NOT NULL,
  activo boolean DEFAULT true NOT NULL,
  puede_finanzas boolean DEFAULT false NOT NULL,
  puede_comisiones boolean DEFAULT false NOT NULL,
  puede_motoristas boolean DEFAULT false NOT NULL,
  puede_tiendas boolean DEFAULT false NOT NULL,
  puede_confirmar_rendiciones boolean DEFAULT false NOT NULL,
  nombre text,
  telefono text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.motivos_incidencia_catalogo (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  empresa_id uuid NOT NULL,
  descripcion text NOT NULL,
  es_facturable_tienda boolean DEFAULT true,
  activo boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.motorista_invitaciones (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  motorista_id uuid NOT NULL,
  token_hash text NOT NULL,
  vence_en timestamp with time zone DEFAULT (now() + '48:00:00'::interval) NOT NULL,
  usada_por uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.motorista_ordenes_pedidos (
  motorista_id uuid NOT NULL,
  fecha date NOT NULL,
  pedido_id uuid NOT NULL,
  posicion integer NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.motorista_recorridos_confirmados (
  motorista_id uuid NOT NULL,
  empresa_id uuid NOT NULL,
  fecha date NOT NULL,
  version bigint DEFAULT 1 NOT NULL,
  pedido_ids uuid[] NOT NULL,
  coordenadas jsonb NOT NULL,
  origen_lat double precision NOT NULL,
  origen_lng double precision NOT NULL,
  confirmado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.motoristas (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  empresa_id uuid NOT NULL,
  usuario_id uuid,
  nombre text NOT NULL,
  telefono text NOT NULL,
  email text,
  color_identificador text DEFAULT '#3B82F6'::text,
  activo boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  porcentaje_empresa_pct integer DEFAULT 25 NOT NULL,
  modalidad_liquidacion text DEFAULT 'retener_comision'::text NOT NULL,
  gps_lat double precision,
  gps_lng double precision,
  gps_precision_m numeric,
  gps_actualizado_en timestamp with time zone,
  porcentaje_personalizado boolean DEFAULT false NOT NULL
);

CREATE TABLE IF NOT EXISTS public.movimientos_financieros (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  empresa_id uuid NOT NULL,
  pedido_id uuid NOT NULL,
  motorista_id uuid,
  tienda_id uuid,
  monto_mercaderia integer DEFAULT 0,
  monto_delivery integer DEFAULT 0,
  comision_empresa integer DEFAULT 0,
  comision_motorista integer DEFAULT 0,
  es_rechazo_facturable boolean DEFAULT false,
  liquidado boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  efectivo_cobrado integer DEFAULT 0 NOT NULL,
  transferencia_cobrada integer DEFAULT 0 NOT NULL,
  registrado_real_en timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public.pedidos (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  empresa_id uuid NOT NULL,
  tienda_id uuid NOT NULL,
  cliente_id uuid,
  ruta_general_id uuid,
  motorista_id uuid,
  nombre_cliente text NOT NULL,
  telefono_cliente text NOT NULL,
  direccion_cliente text NOT NULL,
  lat double precision,
  lng double precision,
  referencias text,
  observaciones text,
  precio_mercaderia integer DEFAULT 0 NOT NULL,
  precio_delivery integer DEFAULT 25000 NOT NULL,
  modalidad_pago text NOT NULL,
  porcentaje_empresa_pct integer DEFAULT 25,
  porcentaje_motorista_pct integer DEFAULT 75,
  numero_general integer,
  estado text DEFAULT 'pendiente'::text NOT NULL,
  motivo_incidencia text,
  medio_cobro text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  creado_por uuid,
  version_edicion integer DEFAULT 1 NOT NULL,
  requiere_revisar_ruta boolean DEFAULT false NOT NULL,
  turno text DEFAULT 'sin_definir'::text NOT NULL,
  producto text,
  tarifa_origen text,
  tarifa_localidad text,
  delivery_cliente integer,
  delivery_subsidio_tienda integer,
  regla_comercial text,
  excluido_ruta boolean DEFAULT false NOT NULL
);

CREATE TABLE IF NOT EXISTS public.pedidos_ediciones (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  pedido_id uuid NOT NULL,
  empresa_id uuid NOT NULL,
  tienda_id uuid,
  usuario_id uuid NOT NULL,
  momento timestamp with time zone DEFAULT now() NOT NULL,
  version_anterior integer NOT NULL,
  version_nueva integer NOT NULL,
  cambios jsonb NOT NULL
);

CREATE TABLE IF NOT EXISTS public.perfiles (
  id uuid NOT NULL,
  empresa_id uuid,
  rol text NOT NULL,
  nombre text NOT NULL,
  telefono text,
  activo boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.rendiciones (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  empresa_id uuid NOT NULL,
  tipo text NOT NULL,
  referencia_id uuid NOT NULL,
  fecha date DEFAULT CURRENT_DATE NOT NULL,
  total_efectivo integer DEFAULT 0,
  total_transferencia integer DEFAULT 0,
  total_comision integer DEFAULT 0,
  total_a_rendir integer DEFAULT 0,
  estado text DEFAULT 'abierta'::text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.rutas_generales (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  empresa_id uuid NOT NULL,
  fecha date DEFAULT CURRENT_DATE NOT NULL,
  estado text DEFAULT 'abierta'::text NOT NULL,
  version_optimizacion integer DEFAULT 1,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  turno text
);

CREATE TABLE IF NOT EXISTS public.tarifas_zona (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  empresa_id uuid NOT NULL,
  localidad text NOT NULL,
  costo_envio integer DEFAULT 25000 NOT NULL,
  activo boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.tienda_cuentas_v2 (
  id uuid NOT NULL,
  empresa_id uuid NOT NULL,
  nombre text NOT NULL,
  telefono text NOT NULL,
  direccion text NOT NULL,
  creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.tienda_invitaciones (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  tienda_id uuid NOT NULL,
  token_hash text NOT NULL,
  creada_por uuid NOT NULL,
  vence_en timestamp with time zone NOT NULL,
  usos_maximos integer DEFAULT 1 NOT NULL,
  usos integer DEFAULT 0 NOT NULL,
  revocada boolean DEFAULT false NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.tienda_miembros (
  tienda_id uuid NOT NULL,
  usuario_id uuid NOT NULL,
  rol text NOT NULL,
  activo boolean DEFAULT true NOT NULL,
  creado_en timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.tiendas (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  empresa_id uuid NOT NULL,
  usuario_id uuid,
  nombre_comercial text NOT NULL,
  responsable text,
  telefono text NOT NULL,
  email text,
  direccion text NOT NULL,
  lat double precision,
  lng double precision,
  activo boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  codigo text,
  uso_interno_logistico boolean DEFAULT false NOT NULL
);

CREATE TABLE IF NOT EXISTS public.versiones_optimizacion (
  id uuid DEFAULT uuid_generate_v4() NOT NULL,
  ruta_general_id uuid NOT NULL,
  version_numero integer DEFAULT 1 NOT NULL,
  orden_pedidos_ids uuid[] NOT NULL,
  confirmado_por text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- constraints

ALTER TABLE public.clientes ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);

ALTER TABLE public.empresas ADD CONSTRAINT empresas_pkey PRIMARY KEY (id);

ALTER TABLE public.empresas ADD CONSTRAINT empresas_porcentaje_empresa_general_check CHECK (porcentaje_empresa_general >= 0 AND porcentaje_empresa_general <= 100);

ALTER TABLE public.flota_cierres_motoristas ADD CONSTRAINT flota_cierres_motoristas_estado_check CHECK (estado = ANY (ARRAY['presentada'::text, 'confirmada'::text, 'diferencia'::text]));

ALTER TABLE public.flota_cierres_motoristas ADD CONSTRAINT flota_cierres_motoristas_motorista_id_fecha_key UNIQUE (motorista_id, fecha);

ALTER TABLE public.flota_cierres_motoristas ADD CONSTRAINT flota_cierres_motoristas_pkey PRIMARY KEY (id);

ALTER TABLE public.flota_compensaciones_tienda ADD CONSTRAINT flota_compensaciones_tienda_importe_check CHECK (importe > 0);

ALTER TABLE public.flota_compensaciones_tienda ADD CONSTRAINT flota_compensaciones_tienda_pedido_id_key UNIQUE (pedido_id);

ALTER TABLE public.flota_compensaciones_tienda ADD CONSTRAINT flota_compensaciones_tienda_pkey PRIMARY KEY (id);

ALTER TABLE public.flota_compensaciones_tienda ADD CONSTRAINT flota_compensaciones_tienda_referencia_check CHECK (length(btrim(referencia)) >= 5);

ALTER TABLE public.flota_cupo_optimizacion_google ADD CONSTRAINT flota_cupo_cantidad_valida CHECK (cantidad >= 0);

ALTER TABLE public.flota_cupo_optimizacion_google ADD CONSTRAINT flota_cupo_optimizacion_google_pkey PRIMARY KEY (clave);

ALTER TABLE public.flota_invitaciones ADD CONSTRAINT flota_invitaciones_pkey PRIMARY KEY (id);

ALTER TABLE public.flota_invitaciones ADD CONSTRAINT flota_invitaciones_rol_check CHECK (rol = ANY (ARRAY['socio'::text, 'operador'::text]));

ALTER TABLE public.flota_invitaciones ADD CONSTRAINT flota_invitaciones_token_hash_key UNIQUE (token_hash);

ALTER TABLE public.flota_pagos_tienda ADD CONSTRAINT flota_pagos_tienda_empresa_id_tienda_id_fecha_rendicion_ref_key UNIQUE (empresa_id, tienda_id, fecha_rendicion, referencia);

ALTER TABLE public.flota_pagos_tienda ADD CONSTRAINT flota_pagos_tienda_importe_check CHECK (importe > 0);

ALTER TABLE public.flota_pagos_tienda ADD CONSTRAINT flota_pagos_tienda_medio_check CHECK (medio = ANY (ARRAY['efectivo'::text, 'transferencia'::text]));

ALTER TABLE public.flota_pagos_tienda ADD CONSTRAINT flota_pagos_tienda_pkey PRIMARY KEY (id);

ALTER TABLE public.flota_pagos_tienda ADD CONSTRAINT flota_pagos_tienda_referencia_check CHECK (length(btrim(referencia)) >= 5);

ALTER TABLE public.flota_propietarios_pendientes ADD CONSTRAINT flota_propietarios_pendientes_correo_key UNIQUE (correo);

ALTER TABLE public.flota_propietarios_pendientes ADD CONSTRAINT flota_propietarios_pendientes_pkey PRIMARY KEY (empresa_id);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_comision_empresa_check CHECK (comision_empresa >= 0);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_comision_motorista_check CHECK (comision_motorista >= 0);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_importe_cobrado_check CHECK (importe_cobrado >= 0);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_importe_pendiente_check CHECK (importe_pendiente >= 0);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_medio_cobro_check CHECK (medio_cobro = ANY (ARRAY['efectivo'::text, 'transferencia'::text]));

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_pkey PRIMARY KEY (pedido_id);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_responsable_pago_check CHECK (responsable_pago = ANY (ARRAY['cliente'::text, 'tienda'::text, 'pendiente'::text]));

ALTER TABLE public.flota_solicitudes_tienda ADD CONSTRAINT flota_solicitudes_tienda_empresa_id_usuario_id_key UNIQUE (empresa_id, usuario_id);

ALTER TABLE public.flota_solicitudes_tienda ADD CONSTRAINT flota_solicitudes_tienda_estado_check CHECK (estado = ANY (ARRAY['pendiente'::text, 'aprobada'::text, 'rechazada'::text]));

ALTER TABLE public.flota_solicitudes_tienda ADD CONSTRAINT flota_solicitudes_tienda_pkey PRIMARY KEY (id);

ALTER TABLE public.flota_tienda_propietarias ADD CONSTRAINT flota_tienda_propietarias_pkey PRIMARY KEY (id);

ALTER TABLE public.flota_tienda_propietarias ADD CONSTRAINT flota_tienda_propietarias_token_hash_key UNIQUE (token_hash);

ALTER TABLE public.flota_usuarios ADD CONSTRAINT flota_usuarios_pkey PRIMARY KEY (empresa_id, usuario_id);

ALTER TABLE public.flota_usuarios ADD CONSTRAINT flota_usuarios_rol_check CHECK (rol = ANY (ARRAY['propietario'::text, 'socio'::text, 'operador'::text]));

ALTER TABLE public.motivos_incidencia_catalogo ADD CONSTRAINT motivos_incidencia_catalogo_pkey PRIMARY KEY (id);

ALTER TABLE public.motorista_invitaciones ADD CONSTRAINT motorista_invitaciones_pkey PRIMARY KEY (id);

ALTER TABLE public.motorista_invitaciones ADD CONSTRAINT motorista_invitaciones_token_hash_key UNIQUE (token_hash);

ALTER TABLE public.motorista_ordenes_pedidos ADD CONSTRAINT motorista_ordenes_pedidos_motorista_id_fecha_posicion_key UNIQUE (motorista_id, fecha, posicion);

ALTER TABLE public.motorista_ordenes_pedidos ADD CONSTRAINT motorista_ordenes_pedidos_pkey PRIMARY KEY (motorista_id, fecha, pedido_id);

ALTER TABLE public.motorista_ordenes_pedidos ADD CONSTRAINT motorista_ordenes_pedidos_posicion_check CHECK (posicion >= 1);

ALTER TABLE public.motorista_recorridos_confirmados ADD CONSTRAINT motorista_recorridos_confirmados_pkey PRIMARY KEY (motorista_id, fecha);

ALTER TABLE public.motorista_recorridos_confirmados ADD CONSTRAINT mrc_coords_array CHECK (jsonb_typeof(coordenadas) = 'array'::text);

ALTER TABLE public.motorista_recorridos_confirmados ADD CONSTRAINT mrc_origen_valido CHECK (origen_lat >= '-90'::integer::double precision AND origen_lat <= 90::double precision AND origen_lng >= '-180'::integer::double precision AND origen_lng <= 180::double precision);

ALTER TABLE public.motoristas ADD CONSTRAINT motoristas_modalidad_liquidacion_check CHECK (modalidad_liquidacion = ANY (ARRAY['rendir_todo'::text, 'retener_comision'::text]));

ALTER TABLE public.motoristas ADD CONSTRAINT motoristas_pkey PRIMARY KEY (id);

ALTER TABLE public.motoristas ADD CONSTRAINT motoristas_porcentaje_empresa_pct_check CHECK (porcentaje_empresa_pct >= 0 AND porcentaje_empresa_pct <= 100);

ALTER TABLE public.movimientos_financieros ADD CONSTRAINT movimientos_financieros_pkey PRIMARY KEY (id);

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_boom_subsidio_integridad CHECK (regla_comercial IS DISTINCT FROM 'boom_25k_cliente_20k_v1'::text OR delivery_cliente IS NOT NULL AND delivery_subsidio_tienda IS NOT NULL AND precio_delivery = (delivery_cliente + delivery_subsidio_tienda) AND precio_delivery >= 25000 AND delivery_cliente >= 20000);

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_estado_check CHECK (estado = ANY (ARRAY['pendiente'::text, 'entregado'::text, 'rechazado'::text, 'no_recibio'::text, 'no_responde'::text, 'pasa_manana'::text, 'cancelado'::text]));

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_medio_cobro_check CHECK (medio_cobro = ANY (ARRAY['efectivo'::text, 'transferencia'::text, 'pagado_previo'::text, NULL::text]));

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_modalidad_pago_check CHECK (modalidad_pago = ANY (ARRAY['pendiente'::text, 'producto_pagado'::text, 'todo_pagado'::text]));

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_producto_largo CHECK (producto IS NULL OR length(producto) <= 200);

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_tarifa_origen_valida CHECK (tarifa_origen IS NULL OR (tarifa_origen = ANY (ARRAY['automatica'::text, 'manual'::text])));

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_turno_check CHECK (turno = ANY (ARRAY['manana'::text, 'tarde'::text, 'sin_definir'::text]));

ALTER TABLE public.pedidos_ediciones ADD CONSTRAINT pedidos_ediciones_pkey PRIMARY KEY (id);

ALTER TABLE public.perfiles ADD CONSTRAINT perfiles_pkey PRIMARY KEY (id);

ALTER TABLE public.perfiles ADD CONSTRAINT perfiles_rol_check CHECK (rol = ANY (ARRAY['superadmin'::text, 'admin'::text, 'tienda'::text, 'motorista'::text]));

ALTER TABLE public.rendiciones ADD CONSTRAINT rendiciones_estado_check CHECK (estado = ANY (ARRAY['abierta'::text, 'cerrada'::text, 'auditada'::text]));

ALTER TABLE public.rendiciones ADD CONSTRAINT rendiciones_pkey PRIMARY KEY (id);

ALTER TABLE public.rendiciones ADD CONSTRAINT rendiciones_tipo_check CHECK (tipo = ANY (ARRAY['motorista'::text, 'tienda'::text]));

ALTER TABLE public.rutas_generales ADD CONSTRAINT rutas_generales_estado_check CHECK (estado = ANY (ARRAY['abierta'::text, 'optimizada'::text, 'en_reparto'::text, 'cerrada'::text]));

ALTER TABLE public.rutas_generales ADD CONSTRAINT rutas_generales_pkey PRIMARY KEY (id);

ALTER TABLE public.rutas_generales ADD CONSTRAINT rutas_generales_turno_check CHECK ((turno = ANY (ARRAY['manana'::text, 'tarde'::text, 'sin_definir'::text])) OR turno IS NULL);

ALTER TABLE public.tarifas_zona ADD CONSTRAINT tarifas_zona_pkey PRIMARY KEY (id);

ALTER TABLE public.tienda_cuentas_v2 ADD CONSTRAINT tienda_cuentas_v2_pkey PRIMARY KEY (id);

ALTER TABLE public.tienda_invitaciones ADD CONSTRAINT tienda_invitaciones_pkey PRIMARY KEY (id);

ALTER TABLE public.tienda_invitaciones ADD CONSTRAINT tienda_invitaciones_token_hash_key UNIQUE (token_hash);

ALTER TABLE public.tienda_invitaciones ADD CONSTRAINT tienda_invitaciones_usos_check CHECK (usos >= 0);

ALTER TABLE public.tienda_invitaciones ADD CONSTRAINT tienda_invitaciones_usos_maximos_check CHECK (usos_maximos >= 1 AND usos_maximos <= 20);

ALTER TABLE public.tienda_miembros ADD CONSTRAINT tienda_miembros_pkey PRIMARY KEY (tienda_id, usuario_id);

ALTER TABLE public.tienda_miembros ADD CONSTRAINT tienda_miembros_rol_check CHECK (rol = ANY (ARRAY['propietario'::text, 'empleado'::text]));

ALTER TABLE public.tiendas ADD CONSTRAINT tiendas_pkey PRIMARY KEY (id);

ALTER TABLE public.versiones_optimizacion ADD CONSTRAINT versiones_optimizacion_pkey PRIMARY KEY (id);

ALTER TABLE public.clientes ADD CONSTRAINT clientes_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE;

ALTER TABLE public.flota_cierres_motoristas ADD CONSTRAINT flota_cierres_motoristas_confirmado_por_fkey FOREIGN KEY (confirmado_por) REFERENCES auth.users(id);

ALTER TABLE public.flota_cierres_motoristas ADD CONSTRAINT flota_cierres_motoristas_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public.flota_cierres_motoristas ADD CONSTRAINT flota_cierres_motoristas_motorista_id_fkey FOREIGN KEY (motorista_id) REFERENCES motoristas(id);

ALTER TABLE public.flota_cierres_motoristas ADD CONSTRAINT flota_cierres_motoristas_presentado_por_fkey FOREIGN KEY (presentado_por) REFERENCES auth.users(id);

ALTER TABLE public.flota_compensaciones_tienda ADD CONSTRAINT flota_compensaciones_tienda_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES pedidos(id);

ALTER TABLE public.flota_compensaciones_tienda ADD CONSTRAINT flota_compensaciones_tienda_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id);

ALTER TABLE public.flota_invitaciones ADD CONSTRAINT flota_invitaciones_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id);

ALTER TABLE public.flota_invitaciones ADD CONSTRAINT flota_invitaciones_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public.flota_invitaciones ADD CONSTRAINT flota_invitaciones_usada_por_fkey FOREIGN KEY (usada_por) REFERENCES auth.users(id);

ALTER TABLE public.flota_pagos_tienda ADD CONSTRAINT flota_pagos_tienda_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id);

ALTER TABLE public.flota_propietarios_pendientes ADD CONSTRAINT flota_propietarios_pendientes_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_motorista_id_fkey FOREIGN KEY (motorista_id) REFERENCES motoristas(id);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES pedidos(id);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_registrado_por_fkey FOREIGN KEY (registrado_por) REFERENCES auth.users(id);

ALTER TABLE public.flota_rechazos_detalle ADD CONSTRAINT flota_rechazos_detalle_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id);

ALTER TABLE public.flota_solicitudes_tienda ADD CONSTRAINT flota_solicitudes_tienda_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public.flota_solicitudes_tienda ADD CONSTRAINT flota_solicitudes_tienda_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id);

ALTER TABLE public.flota_solicitudes_tienda ADD CONSTRAINT flota_solicitudes_tienda_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES auth.users(id);

ALTER TABLE public.flota_tienda_propietarias ADD CONSTRAINT flota_tienda_propietarias_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id);

ALTER TABLE public.flota_tienda_propietarias ADD CONSTRAINT flota_tienda_propietarias_usada_por_fkey FOREIGN KEY (usada_por) REFERENCES auth.users(id);

ALTER TABLE public.flota_usuarios ADD CONSTRAINT flota_usuarios_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public.flota_usuarios ADD CONSTRAINT flota_usuarios_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES auth.users(id);

ALTER TABLE public.motivos_incidencia_catalogo ADD CONSTRAINT motivos_incidencia_catalogo_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public.motorista_invitaciones ADD CONSTRAINT motorista_invitaciones_motorista_id_fkey FOREIGN KEY (motorista_id) REFERENCES motoristas(id);

ALTER TABLE public.motorista_invitaciones ADD CONSTRAINT motorista_invitaciones_usada_por_fkey FOREIGN KEY (usada_por) REFERENCES auth.users(id);

ALTER TABLE public.motorista_ordenes_pedidos ADD CONSTRAINT motorista_ordenes_pedidos_motorista_id_fkey FOREIGN KEY (motorista_id) REFERENCES motoristas(id);

ALTER TABLE public.motorista_ordenes_pedidos ADD CONSTRAINT motorista_ordenes_pedidos_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES pedidos(id);

ALTER TABLE public.motorista_recorridos_confirmados ADD CONSTRAINT motorista_recorridos_confirmados_motorista_id_fkey FOREIGN KEY (motorista_id) REFERENCES motoristas(id);

ALTER TABLE public.motoristas ADD CONSTRAINT motoristas_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public.motoristas ADD CONSTRAINT motoristas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES perfiles(id) ON DELETE SET NULL;

ALTER TABLE public.movimientos_financieros ADD CONSTRAINT movimientos_financieros_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public.movimientos_financieros ADD CONSTRAINT movimientos_financieros_motorista_id_fkey FOREIGN KEY (motorista_id) REFERENCES motoristas(id) ON DELETE SET NULL;

ALTER TABLE public.movimientos_financieros ADD CONSTRAINT movimientos_financieros_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE;

ALTER TABLE public.movimientos_financieros ADD CONSTRAINT movimientos_financieros_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE SET NULL;

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL;

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_motorista_id_fkey FOREIGN KEY (motorista_id) REFERENCES motoristas(id) ON DELETE SET NULL;

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_ruta_general_id_fkey FOREIGN KEY (ruta_general_id) REFERENCES rutas_generales(id) ON DELETE SET NULL;

ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE;

ALTER TABLE public.pedidos_ediciones ADD CONSTRAINT pedidos_ediciones_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE;

ALTER TABLE public.perfiles ADD CONSTRAINT perfiles_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public.perfiles ADD CONSTRAINT perfiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.rendiciones ADD CONSTRAINT rendiciones_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public.rutas_generales ADD CONSTRAINT rutas_generales_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public.tarifas_zona ADD CONSTRAINT tarifas_zona_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public.tienda_cuentas_v2 ADD CONSTRAINT tienda_cuentas_v2_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id);

ALTER TABLE public.tienda_cuentas_v2 ADD CONSTRAINT tienda_cuentas_v2_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.tienda_invitaciones ADD CONSTRAINT tienda_invitaciones_creada_por_fkey FOREIGN KEY (creada_por) REFERENCES auth.users(id);

ALTER TABLE public.tienda_invitaciones ADD CONSTRAINT tienda_invitaciones_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE;

ALTER TABLE public.tienda_miembros ADD CONSTRAINT tienda_miembros_tienda_id_fkey FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE;

ALTER TABLE public.tienda_miembros ADD CONSTRAINT tienda_miembros_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.tiendas ADD CONSTRAINT tiendas_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;

ALTER TABLE public.tiendas ADD CONSTRAINT tiendas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES perfiles(id) ON DELETE SET NULL;

ALTER TABLE public.versiones_optimizacion ADD CONSTRAINT versiones_optimizacion_ruta_general_id_fkey FOREIGN KEY (ruta_general_id) REFERENCES rutas_generales(id) ON DELETE CASCADE;

-- indexes

CREATE INDEX idx_clientes_tienda_telefono ON public.clientes USING btree (tienda_id, telefono);

CREATE INDEX flota_usuarios_por_usuario ON public.flota_usuarios USING btree (usuario_id);

CREATE UNIQUE INDEX flota_propietario_unico ON public.flota_usuarios USING btree (empresa_id) WHERE (rol = 'propietario'::text);

CREATE UNIQUE INDEX motoristas_email_empresa_unique ON public.motoristas USING btree (empresa_id, lower(email)) WHERE (email IS NOT NULL);

CREATE UNIQUE INDEX movimientos_financieros_pedido_unico ON public.movimientos_financieros USING btree (pedido_id);

CREATE INDEX idx_pedidos_creado_por ON public.pedidos USING btree (creado_por);

CREATE INDEX idx_pedidos_empresa_turno_fecha ON public.pedidos USING btree (empresa_id, turno, created_at DESC);

CREATE INDEX idx_pedidos_empresa_tienda_fecha ON public.pedidos USING btree (empresa_id, tienda_id, created_at DESC);

CREATE INDEX idx_perfiles_empresa_id ON public.perfiles USING btree (empresa_id);

CREATE UNIQUE INDEX rutas_por_empresa_fecha_turno_unica ON public.rutas_generales USING btree (empresa_id, fecha, turno) WHERE ((turno IS NOT NULL) AND (estado = ANY (ARRAY['abierta'::text, 'optimizada'::text, 'en_reparto'::text])));

CREATE UNIQUE INDEX tarifas_zona_empresa_localidad_unica ON public.tarifas_zona USING btree (empresa_id, localidad);

CREATE UNIQUE INDEX tienda_cuentas_v2_email_idx ON public.tienda_cuentas_v2 USING btree (id);

CREATE INDEX idx_invitaciones_tienda ON public.tienda_invitaciones USING btree (tienda_id, vence_en);

CREATE INDEX idx_tienda_miembros_usuario ON public.tienda_miembros USING btree (usuario_id, activo);

CREATE INDEX idx_tiendas_usuario_id ON public.tiendas USING btree (usuario_id);

CREATE UNIQUE INDEX deliveryya_tienda_codigo_empresa_unico ON public.tiendas USING btree (empresa_id, codigo);

CREATE UNIQUE INDEX tiendas_usuario_unico ON public.tiendas USING btree (usuario_id) WHERE (usuario_id IS NOT NULL);

-- FUNCIONES

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

CREATE OR REPLACE FUNCTION public.admin_confirmar_ruta_optimizada(p_ruta_general_id uuid, p_orden_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_estado text;v_turno text;v_fecha date;v_count integer;v_selected integer;
begin
 select empresa_id,estado,turno,fecha into v_empresa,v_estado,v_turno,v_fecha from public.rutas_generales where id=p_ruta_general_id for update;
 if v_empresa is null or v_estado not in('abierta','optimizada') or v_turno not in('manana','tarde','sin_definir') then raise exception 'La ruta debe estar abierta, autorizada y tener turno definido';end if;
 if not exists(select 1 from public.flota_usuarios where empresa_id=v_empresa and usuario_id=auth.uid() and activo and rol in('propietario','socio','operador')) then raise exception 'No autorizado';end if;
 v_count=coalesce(array_length(p_orden_ids,1),0);
 if v_count<1 or v_count>2000 then raise exception 'Seleccioná entre 1 y 2000 paradas';end if;
 if (select count(distinct x) from unnest(p_orden_ids) x)<>v_count then raise exception 'IDs duplicados';end if;
 perform 1 from public.pedidos where id=any(p_orden_ids) or ruta_general_id=p_ruta_general_id order by id for update;
 if exists(select 1 from public.pedidos where ruta_general_id=p_ruta_general_id and (estado<>'pendiente' or motorista_id is not null)) then raise exception 'Ruta con repartos o entregas: no puede renumerarse';end if;
 if exists(select 1 from public.pedidos p where p.ruta_general_id=p_ruta_general_id and not(p.id=any(p_orden_ids))) then raise exception 'Hay pedidos preparados que no están en el cálculo: incluilos antes de confirmar para evitar que desaparezcan de la ruta';end if;
 select count(*) into v_selected from public.pedidos p where p.id=any(p_orden_ids) and p.empresa_id=v_empresa and p.estado='pendiente' and p.motorista_id is null and p.lat is not null and p.lng is not null
 and coalesce(p.turno,'sin_definir')=v_turno and not coalesce(p.excluido_ruta,false) and (p.ruta_general_id=p_ruta_general_id or (p.ruta_general_id is null and (p.created_at at time zone 'America/Asuncion')::date=v_fecha));
 if v_selected<>v_count then raise exception 'Todos los pedidos deben pertenecer a una misma empresa, turno y ruta';end if;
 update public.pedidos p set numero_general=u.numero,ruta_general_id=p_ruta_general_id,updated_at=now()
 from unnest(p_orden_ids) with ordinality u(id,numero) where p.id=u.id;
 update public.rutas_generales set estado='optimizada',version_optimizacion=coalesce(version_optimizacion,0)+1 where id=p_ruta_general_id;
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
 -- La Central (propietario/socio/operador) edita todo, aunque el pedido ya esté asignado.
 permitido:=CASE WHEN admin THEN ARRAY['nombre_cliente','telefono_cliente','direccion_cliente','lat','lng','referencias','observaciones','precio_mercaderia','precio_delivery','modalidad_pago','producto'] WHEN moto THEN ARRAY['referencias','observaciones','telefono_cliente'] WHEN o.motorista_id IS NOT NULL THEN ARRAY['nombre_cliente','telefono_cliente','referencias','observaciones'] ELSE ARRAY['nombre_cliente','telefono_cliente','direccion_cliente','lat','lng','referencias','observaciones','precio_mercaderia','precio_delivery','modalidad_pago','producto'] END;
 FOR f IN SELECT jsonb_object_keys(p_cambios) LOOP
  IF NOT f=ANY(permitido) THEN RAISE EXCEPTION 'Campo no editable en este estado: %',f; END IF;
 END LOOP;
 IF p_cambios ? 'modalidad_pago' AND NOT (p_cambios->>'modalidad_pago'=ANY(ARRAY['pendiente','producto_pagado','todo_pagado'])) THEN RAISE EXCEPTION 'Modalidad inválida'; END IF;
 IF p_cambios ? 'precio_mercaderia' AND ((p_cambios->>'precio_mercaderia')::integer<0) THEN RAISE EXCEPTION 'Precio inválido'; END IF;
 IF p_cambios ? 'precio_delivery' AND ((p_cambios->>'precio_delivery')::integer<0) THEN RAISE EXCEPTION 'Envío inválido'; END IF;
 IF p_cambios ? 'producto' AND length(coalesce(p_cambios->>'producto',''))>160 THEN RAISE EXCEPTION 'Producto demasiado largo'; END IF;
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
 referencias=v.referencias,observaciones=v.observaciones,precio_mercaderia=v.precio_mercaderia,precio_delivery=v.precio_delivery,modalidad_pago=v.modalidad_pago,producto=v.producto,
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

CREATE OR REPLACE FUNCTION public.flota_anexar_pedidos_a_ruta(p_ruta uuid, p_pedidos uuid[])
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid; v_estado text; v_turno text; v_total integer; v_valid integer; v_max integer;
begin
 select empresa_id, estado, turno into v_empresa, v_estado, v_turno from public.rutas_generales where id = p_ruta for update;
 if v_empresa is null or v_estado not in ('optimizada','en_reparto') or v_turno is null then
  raise exception 'Solo se puede anexar a una ruta confirmada con turno';
 end if;
 if not exists (select 1 from public.flota_usuarios where empresa_id = v_empresa and usuario_id = auth.uid() and activo and rol in ('propietario','socio','operador')) then
  raise exception 'No autorizado';
 end if;
 v_total := coalesce(array_length(p_pedidos, 1), 0);
 if v_total < 1 or v_total > 200 or (select count(distinct x) from unnest(p_pedidos) x) <> v_total then raise exception 'Selección inválida o duplicada'; end if;
 perform 1 from public.pedidos where id = any(p_pedidos) order by id for update;
 select count(*) into v_valid from public.pedidos p
  where p.id = any(p_pedidos) and p.empresa_id = v_empresa and p.estado = 'pendiente' and p.motorista_id is null
    and p.lat is not null and p.lng is not null and coalesce(p.turno, 'sin_definir') = v_turno
    and ((p.ruta_general_id is null and (p.created_at AT TIME ZONE 'America/Asuncion')::date = (SELECT fecha FROM public.rutas_generales WHERE id=p_ruta)) or (p.ruta_general_id = p_ruta and p.numero_general is null))
    and not coalesce(p.excluido_ruta,false) and not exists (select 1 from public.movimientos_financieros mf where mf.pedido_id = p.id);
 if v_valid <> v_total then raise exception 'Todos los pedidos deben ser pendientes, sin número, del mismo turno y sin ruta confirmada'; end if;
 select coalesce(max(numero_general), 0) into v_max from public.pedidos where ruta_general_id = p_ruta;
 update public.pedidos p set ruta_general_id = p_ruta, numero_general = v_max + u.n, requiere_revisar_ruta = false,
        version_edicion = coalesce(p.version_edicion, 0) + 1, updated_at = now()
  from unnest(p_pedidos) with ordinality u(id, n) where p.id = u.id;
 return v_total;
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
if exists(
 select 1 from public.pedidos p
 join public.rutas_generales r on r.id=p.ruta_general_id
 join public.flota_cierres_motoristas c on c.motorista_id=p_motorista and c.fecha=r.fecha
 where p.id=any(p_pedidos)
) then raise exception 'La caja de este motorista ya está cerrada para la fecha de esos pedidos. Elegí otro motorista o coordiná la nueva jornada.';end if;
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

CREATE OR REPLACE FUNCTION public.flota_asignar_pedidos_rapido(p_pedidos uuid[], p_motorista uuid, p_fecha date, p_turno text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_pct integer;v_total integer;v_ruta uuid;v_fila record;v_num integer;v_valid integer;
begin
 v_total=coalesce(array_length(p_pedidos,1),0);
 if v_total<1 or v_total>200 or (select count(distinct id) from unnest(p_pedidos) as id)<>v_total then raise exception 'Selección vacía o duplicada';end if;
 if p_fecha is null or p_fecha<>(now() at time zone 'America/Asuncion')::date then raise exception 'Solo se pueden asignar pedidos de hoy';end if;
 if p_turno not in ('manana','tarde','sin_definir') then raise exception 'Turno inválido';end if;
 select m.empresa_id,m.porcentaje_empresa_pct into v_empresa,v_pct from public.motoristas m where m.id=p_motorista and m.activo for update;
 if v_empresa is null or v_pct not between 0 and 100 then raise exception 'Motorista inválido';end if;
 if not exists(select 1 from public.flota_usuarios u where u.usuario_id=auth.uid() and u.empresa_id=v_empresa and u.activo and u.rol in ('propietario','socio','operador')) then raise exception 'No autorizado para asignar';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(p_fecha::text||p_turno));
 if exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=p_motorista and c.fecha=p_fecha) then raise exception 'La caja de este motorista está cerrada';end if;
 perform 1 from public.pedidos where id=any(p_pedidos) order by id for update;
 select count(*) into v_valid from public.pedidos p
 left join public.rutas_generales r on r.id=p.ruta_general_id
 where p.id=any(p_pedidos) and p.empresa_id=v_empresa and p.estado='pendiente' and p.motorista_id is null
 and p.turno=p_turno
 and coalesce(r.fecha,(p.created_at at time zone 'America/Asuncion')::date)=p_fecha
 and (r.id is null or (r.empresa_id=v_empresa and r.fecha=p_fecha and r.turno=p_turno and r.estado in('abierta','optimizada','en_reparto')));
 if v_valid<>v_total then raise exception 'Hay pedidos no disponibles, de otro turno o ya asignados. Actualizá la Central';end if;
 select r.id into v_ruta from public.rutas_generales r where r.empresa_id=v_empresa and r.fecha=p_fecha and r.turno=p_turno and r.estado in ('abierta','optimizada','en_reparto') order by r.created_at limit 1 for update;
 if v_ruta is null then insert into public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion) values(v_empresa,p_fecha,p_turno,'en_reparto',0) returning id into v_ruta;end if;
 if exists(select 1 from public.pedidos p where p.id=any(p_pedidos) and p.ruta_general_id is not null and p.ruta_general_id<>v_ruta) then
  raise exception 'Un pedido pertenece a otra ruta; revisá el turno antes de asignar';
 end if;
 select coalesce(max(p.numero_general),0) into v_num from public.pedidos p where p.ruta_general_id=v_ruta;
 for v_fila in select p.id,p.numero_general from public.pedidos p where p.id=any(p_pedidos) order by p.created_at,p.id loop
  if v_fila.numero_general is null then v_num=v_num+1;end if;
  update public.pedidos p set ruta_general_id=v_ruta,numero_general=coalesce(v_fila.numero_general,v_num),motorista_id=p_motorista,
   porcentaje_empresa_pct=v_pct,porcentaje_motorista_pct=100-v_pct,updated_at=now() where p.id=v_fila.id;
 end loop;
 update public.rutas_generales set estado='en_reparto' where id=v_ruta and estado<>'en_reparto';
 return v_total;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_boom_tarifa_minima_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_es_boom boolean;v_fecha_ingreso date;
begin
 select exists(select 1 from public.tiendas t where t.id=new.tienda_id and t.empresa_id=new.empresa_id and t.codigo='T14' and lower(trim(t.nombre_comercial))='boom store') into v_es_boom;
 if not v_es_boom then
  if tg_op='INSERT' and (new.delivery_cliente is not null or new.delivery_subsidio_tienda is not null or new.regla_comercial is not null) then raise exception 'Regla especial de Boom Store no autorizada para esta tienda'; end if;
  if tg_op='UPDATE' and (new.delivery_cliente is distinct from old.delivery_cliente or new.delivery_subsidio_tienda is distinct from old.delivery_subsidio_tienda or new.regla_comercial is distinct from old.regla_comercial) then raise exception 'No está permitido modificar los campos comerciales de otra tienda'; end if;
  return new;
 end if;
 -- Fecha de corte fija: sólo pedidos ingresados desde el 10/11/2026, hora de Paraguay.
 v_fecha_ingreso=coalesce((new.created_at at time zone 'America/Asuncion')::date,(now() at time zone 'America/Asuncion')::date);
 if v_fecha_ingreso<'2026-11-10'::date then
  if tg_op='UPDATE' and (new.delivery_cliente is distinct from old.delivery_cliente or new.delivery_subsidio_tienda is distinct from old.delivery_subsidio_tienda or new.regla_comercial is distinct from old.regla_comercial) then
   raise exception 'Pedido anterior al 10/11/2026: no modificar ni aplicar subsidio retroactivo';
  end if;
  return new;
 end if;
 if tg_op='INSERT' then
  if new.precio_delivery is null or (new.precio_delivery<20000 or (new.precio_delivery>20000 and new.precio_delivery<25000)) then raise exception 'Tarifa mínima Boom Store: Gs. 25.000 reales, cliente Gs. 20.000';end if;
  if new.precio_delivery in (20000,25000) then new.precio_delivery=25000;new.delivery_cliente=20000;new.delivery_subsidio_tienda=5000;
  else new.delivery_cliente=new.precio_delivery;new.delivery_subsidio_tienda=0;end if;
  new.regla_comercial='boom_25k_cliente_20k_v1';
 else
  if old.regla_comercial is distinct from 'boom_25k_cliente_20k_v1' then
   if new.delivery_cliente is distinct from old.delivery_cliente or new.delivery_subsidio_tienda is distinct from old.delivery_subsidio_tienda or new.regla_comercial is distinct from old.regla_comercial then raise exception 'Pedido sin regla comercial: no modificar campos de subsidio';end if;
   return new;
  end if;
  if new.regla_comercial is distinct from old.regla_comercial then raise exception 'No se puede eliminar la regla comercial del pedido';end if;
  if new.precio_delivery is distinct from old.precio_delivery then
   if old.estado<>'pendiente' or exists(select 1 from public.movimientos_financieros where pedido_id=new.id) then raise exception 'Movimiento financiero existente';end if;
   if new.precio_delivery<20000 or (new.precio_delivery>20000 and new.precio_delivery<25000) then raise exception 'Tarifa real mínima Boom Store Gs. 25.000';end if;
   if new.precio_delivery in (20000,25000) then new.precio_delivery=25000;new.delivery_cliente=20000;new.delivery_subsidio_tienda=5000;
   else new.delivery_cliente=new.precio_delivery;new.delivery_subsidio_tienda=0;end if;
  elsif new.delivery_cliente is distinct from old.delivery_cliente or new.delivery_subsidio_tienda is distinct from old.delivery_subsidio_tienda then
   raise exception 'No se puede alterar manualmente el aporte de tienda';
  end if;
 end if;
 return new;
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

CREATE OR REPLACE FUNCTION public.flota_compensar_rechazo_en_rendicion(p_pedido uuid, p_fecha_rendicion date, p_referencia text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_r public.flota_rechazos_detalle%rowtype;
 v_p public.pedidos%rowtype;
 v_merc integer;v_descuentos integer;v_pagos integer;v_disponible integer;v_id uuid;
BEGIN
 IF p_pedido IS NULL OR p_fecha_rendicion IS NULL OR p_fecha_rendicion<>(now() AT TIME ZONE 'America/Asuncion')::date
 THEN RAISE EXCEPTION 'La compensación debe registrarse en la rendición de hoy';END IF;
 IF length(btrim(coalesce(p_referencia,'')))<5 THEN RAISE EXCEPTION 'Indicá la referencia del acuerdo de descuento';END IF;
 SELECT * INTO v_r FROM public.flota_rechazos_detalle WHERE pedido_id=p_pedido FOR UPDATE;
 IF NOT FOUND OR v_r.responsable_pago<>'tienda' OR v_r.importe_pendiente<=0
 THEN RAISE EXCEPTION 'Rechazo no facturable a tienda o ya cobrado';END IF;
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido;
 IF v_p.estado<>'rechazado' OR v_p.empresa_id IS DISTINCT FROM v_r.empresa_id OR v_p.tienda_id IS DISTINCT FROM v_r.tienda_id
 THEN RAISE EXCEPTION 'Pedido o tienda no conciliable';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=v_r.empresa_id AND u.activo AND (u.rol='propietario' OR u.puede_confirmar_rendiciones))
 THEN RAISE EXCEPTION 'No autorizado para aplicar el descuento';END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_r.empresa_id::text),pg_catalog.hashtext(v_r.tienda_id::text||p_fecha_rendicion::text));
 IF EXISTS(SELECT 1 FROM public.flota_compensaciones_tienda WHERE pedido_id=p_pedido)
 THEN RAISE EXCEPTION 'El rechazo ya fue descontado en una rendición; no se duplica';END IF;
 SELECT coalesce(sum(CASE
  WHEN p.estado='entregado' AND p.modalidad_pago='pendiente' THEN m.monto_mercaderia-coalesce(p.delivery_subsidio_tienda,0)
  WHEN p.estado='entregado' AND p.modalidad_pago='todo_pagado' THEN -m.monto_delivery
  WHEN p.estado='entregado' AND p.modalidad_pago='producto_pagado' THEN -coalesce(p.delivery_subsidio_tienda,0)
  ELSE 0 END),0)::integer
 INTO v_merc
 FROM public.movimientos_financieros m
 JOIN public.pedidos p ON p.id=m.pedido_id
 WHERE m.empresa_id=v_r.empresa_id AND m.tienda_id=v_r.tienda_id
 AND (m.created_at AT TIME ZONE 'America/Asuncion')::date=p_fecha_rendicion;
 SELECT coalesce(sum(importe),0)::integer INTO v_descuentos
 FROM public.flota_compensaciones_tienda WHERE empresa_id=v_r.empresa_id AND tienda_id=v_r.tienda_id AND fecha_rendicion=p_fecha_rendicion;
 SELECT coalesce(sum(importe),0)::integer INTO v_pagos
 FROM public.flota_pagos_tienda WHERE empresa_id=v_r.empresa_id AND tienda_id=v_r.tienda_id AND fecha_rendicion=p_fecha_rendicion;
 v_disponible:=v_merc-v_descuentos-v_pagos;
 IF v_disponible<v_r.importe_pendiente THEN
  RAISE EXCEPTION 'La tienda solo tiene saldo libre de % Gs. El rechazo pendiente de % Gs sigue como deuda y no se duplicó',greatest(v_disponible,0),v_r.importe_pendiente;
 END IF;
 INSERT INTO public.flota_compensaciones_tienda(empresa_id,tienda_id,pedido_id,fecha_rendicion,importe,referencia,confirmado_por)
 VALUES(v_r.empresa_id,v_r.tienda_id,p_pedido,p_fecha_rendicion,v_r.importe_pendiente,btrim(p_referencia),auth.uid())
 RETURNING id INTO v_id;
 RETURN jsonb_build_object('descuento_id',v_id,'pedido_id',p_pedido,'tienda_id',v_r.tienda_id,
  'importe',v_r.importe_pendiente,'fecha_aplicacion',p_fecha_rendicion,'saldo_previo',v_disponible);
END;$function$;

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

CREATE OR REPLACE FUNCTION public.flota_confirmar_cierre_completo(p_cierre uuid, p_efectivo_recibido integer, p_transferencia_confirmada integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.flota_cierres_motoristas%rowtype;
begin
select * into v from public.flota_cierres_motoristas where id=p_cierre for update;
if not found or v.estado not in ('presentada','diferencia') then raise exception 'Rendición no disponible para confirmar';end if;
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

CREATE OR REPLACE FUNCTION public.flota_confirmar_compensacion_tienda(p_pedido uuid, p_fecha date, p_referencia text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_id uuid;v_tienda uuid;v_importe integer;v_fecha_ruta date;
begin
 select u.empresa_id into v_empresa from public.flota_usuarios u where u.usuario_id=auth.uid() and u.activo and
 (u.rol='propietario' or u.puede_confirmar_rendiciones) limit 1;
 if v_empresa is null then raise exception 'No autorizado para compensar';end if;
 if length(btrim(coalesce(p_referencia,'')))<5 then raise exception 'Falta referencia del acuerdo de compensación';end if;
 if p_fecha is null or p_fecha>(now() at time zone 'America/Asuncion')::date then raise exception 'Fecha inválida';end if;
 select r.tienda_id,r.importe_pendiente,g.fecha into v_tienda,v_importe,v_fecha_ruta
 from public.flota_rechazos_detalle r join public.pedidos p on p.id=r.pedido_id
 left join public.rutas_generales g on g.id=p.ruta_general_id
 where r.pedido_id=p_pedido and r.empresa_id=v_empresa and r.responsable_pago='tienda' and p.estado='rechazado' for update of r;
 if v_tienda is null or v_importe is null or v_importe<=0 or v_fecha_ruta is distinct from p_fecha then
 raise exception 'El rechazo no es elegible o no corresponde a la fecha';end if;
 insert into public.flota_compensaciones_tienda(empresa_id,tienda_id,pedido_id,fecha_rendicion,importe,referencia,confirmado_por)
 values(v_empresa,v_tienda,p_pedido,p_fecha,v_importe,btrim(p_referencia),auth.uid()) returning id into v_id;
 return v_id;
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

CREATE OR REPLACE FUNCTION public.flota_editar_motorista(p_motorista uuid, p_nombre text, p_telefono text, p_correo text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto public.motoristas%rowtype;v_correo text:=lower(trim(coalesce(p_correo,'')));
begin
 select * into v_moto from public.motoristas where id=p_motorista for update;
 if not found then raise exception 'Motorista no encontrado';end if;
 if not exists(select 1 from public.flota_usuarios f where f.empresa_id=v_moto.empresa_id and f.usuario_id=auth.uid() and f.activo and (f.rol='propietario' or f.puede_motoristas))
 then raise exception 'No autorizado para editar motoristas';end if;
 if length(trim(coalesce(p_nombre,'')))<3 then raise exception 'Escribí el nombre y apellido';end if;
 if length(regexp_replace(coalesce(p_telefono,''),'[^0-9]','','g'))<6 then raise exception 'Revisá el teléfono';end if;
 if v_correo !~* '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' then raise exception 'Revisá el correo electrónico';end if;
 if v_moto.usuario_id is not null and v_correo is distinct from lower(trim(coalesce(v_moto.email,'')))
 then raise exception 'Este motorista ya tiene su cuenta vinculada; el correo no se puede cambiar';end if;
 if exists(select 1 from public.motoristas m where m.empresa_id=v_moto.empresa_id and m.id<>v_moto.id and lower(trim(coalesce(m.email,'')))=v_correo)
 then raise exception 'Ese correo ya está cargado en otro motorista';end if;
 update public.motoristas set nombre=trim(p_nombre),telefono=trim(p_telefono),email=v_correo where id=v_moto.id;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_fijar_colaboradores_sin_comision_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if new.empresa_id='a0000000-0000-0000-0000-000000000001' and (
   new.id in ('f7a0f153-2dd8-4f8f-9e65-98be12037617'::uuid,'e7d06427-1a1b-49d4-8448-f94997c5284a'::uuid)
   or lower(btrim(new.nombre))='esteban'
 ) then
  new.porcentaje_empresa_pct=0;
  new.porcentaje_personalizado=true;
 end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_fijar_pct_pedido_colaborador_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare v_nombre text;
begin
 if new.empresa_id='a0000000-0000-0000-0000-000000000001' and new.motorista_id is not null then
   select nombre into v_nombre from public.motoristas where id=new.motorista_id and empresa_id=new.empresa_id;
   if new.motorista_id in ('f7a0f153-2dd8-4f8f-9e65-98be12037617'::uuid,'e7d06427-1a1b-49d4-8448-f94997c5284a'::uuid)
      or lower(btrim(coalesce(v_nombre,'')))='esteban' then
     new.porcentaje_empresa_pct=0;
     new.porcentaje_motorista_pct=100;
   end if;
 end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_historial_reprogramados_fecha(p_fecha date)
 RETURNS TABLE(pedido_id uuid, tienda_id uuid, tienda_nombre text, cliente text, fecha_origen date, fecha_destino date, motorista_anterior text, motivo text, momento timestamp with time zone, accion text, fecha_carga date)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT e.pedido_id,e.tienda_id,t.nombre_comercial,p.nombre_cliente,
  (e.cambios->>'fecha_anterior')::date,(e.cambios->>'fecha_nueva')::date,
  coalesce(m.nombre,'Sin asignar')::text,
  coalesce(e.cambios->>'motivo_reprogramacion',e.cambios->>'motivo_nuevo','Reprogramado')::text,
  e.momento,e.cambios->>'accion',
  (p.created_at AT TIME ZONE 'America/Asuncion')::date
 FROM public.pedidos_ediciones e
 JOIN public.pedidos p ON p.id=e.pedido_id AND p.empresa_id=e.empresa_id
 JOIN public.tiendas t ON t.id=e.tienda_id AND t.empresa_id=e.empresa_id
 LEFT JOIN public.motoristas m ON m.id=(e.cambios->>'motorista_anterior')::uuid AND m.empresa_id=e.empresa_id
 WHERE (e.cambios->>'accion') IN ('pasar_manana_automatico','pasar_manana_central')
 AND (e.cambios->>'fecha_anterior')=p_fecha::text
 AND EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.empresa_id=e.empresa_id AND u.usuario_id=auth.uid()
 AND u.activo AND u.rol IN ('propietario','socio','operador'))
 ORDER BY t.nombre_comercial,p.nombre_cliente,e.momento;
$function$;

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

CREATE OR REPLACE FUNCTION public.flota_liberar_pedido_futuro_seguro(p_pedido uuid, p_version integer, p_fecha date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE p public.pedidos%rowtype;r public.rutas_generales%rowtype;
BEGIN
 IF auth.uid() IS NULL OR p_version IS NULL OR p_fecha IS NULL THEN RAISE EXCEPTION 'Solicitud incompleta';END IF;
 SELECT * INTO p FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=p.empresa_id AND u.activo AND u.rol IN ('propietario','socio','operador'))
 THEN RAISE EXCEPTION 'Sin permiso de Central';END IF;
 SELECT * INTO r FROM public.rutas_generales WHERE id=p.ruta_general_id AND empresa_id=p.empresa_id FOR UPDATE;
 IF NOT FOUND OR r.fecha IS DISTINCT FROM p_fecha OR r.fecha<=(now() AT TIME ZONE 'America/Asuncion')::date OR r.estado NOT IN ('abierta','optimizada','en_reparto')
 THEN RAISE EXCEPTION 'Solo puede liberarse un pedido de una ruta futura activa';END IF;
 IF p.motorista_id IS NULL OR p.estado<>'pendiente' OR p.version_edicion IS DISTINCT FROM p_version
 THEN RAISE EXCEPTION 'El pedido cambió o ya no está asignado pendiente';END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=p.id)
 OR EXISTS(SELECT 1 FROM public.flota_rechazos_detalle x WHERE x.pedido_id=p.id)
 OR EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c WHERE c.empresa_id=p.empresa_id AND c.motorista_id=p.motorista_id AND c.fecha=r.fecha)
 THEN RAISE EXCEPTION 'La caja o los movimientos del pedido no permiten liberarlo';END IF;
 DELETE FROM public.motorista_ordenes_pedidos WHERE pedido_id=p.id AND motorista_id=p.motorista_id;
 UPDATE public.pedidos SET motorista_id=NULL,version_edicion=p.version_edicion+1,requiere_revisar_ruta=true,updated_at=now() WHERE id=p.id;
 INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 VALUES(p.id,p.empresa_id,p.tienda_id,auth.uid(),p.version_edicion,p.version_edicion+1,
 pg_catalog.jsonb_build_object('accion','liberar_asignacion_futura_central',
  'motivo','Retirar pedido antiguo de ruta de motorista sin borrar pedido',
  'motorista_anterior',p.motorista_id,'fecha_ruta',r.fecha,'numero_general',p.numero_general,'precio_delivery',p.precio_delivery));
 RETURN pg_catalog.jsonb_build_object('pedido_id',p.id,'liberado',true,'motorista_anterior',p.motorista_id,'fecha',r.fecha);
END $function$;

CREATE OR REPLACE FUNCTION public.flota_liberar_pedidos_seguros(p_pedidos uuid[], p_versiones jsonb, p_fecha date, p_turno text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_total integer;v_empresa uuid;v_p public.pedidos%rowtype;v_f date;v_t text;v_estado text;v_id uuid;v_vers integer;v_cambiados jsonb:='[]'::jsonb;
BEGIN
 v_total:=coalesce(array_length(p_pedidos,1),0);
 IF v_total<1 OR v_total>100 OR (SELECT count(DISTINCT x) FROM unnest(p_pedidos) x)<>v_total
 THEN RAISE EXCEPTION 'Seleccioná entre 1 y 100 pedidos sin duplicados';END IF;
 IF p_versiones IS NULL OR jsonb_typeof(p_versiones)<>'object' OR p_fecha IS NULL OR p_turno NOT IN ('manana','tarde','sin_definir')
 THEN RAISE EXCEPTION 'Faltan versiones, fecha o turno';END IF;
 IF p_fecha<>(now() AT TIME ZONE 'America/Asuncion')::date THEN RAISE EXCEPTION 'La liberación directa solo está habilitada para la fecha de hoy';END IF;
 FOR v_id IN SELECT x FROM unnest(p_pedidos) x ORDER BY x LOOP
  IF NOT (p_versiones ? v_id::text) OR (p_versiones->>v_id::text) !~ '^[0-9]+$' THEN RAISE EXCEPTION 'Versión faltante para pedido %',v_id;END IF;
  v_vers:=(p_versiones->>v_id::text)::int;
  SELECT * INTO v_p FROM public.pedidos WHERE id=v_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Pedido % inexistente',v_id;END IF;
  IF v_empresa IS NULL THEN v_empresa:=v_p.empresa_id;END IF;
  IF v_empresa IS DISTINCT FROM v_p.empresa_id THEN RAISE EXCEPTION 'No se mezclan pedidos de distintas empresas';END IF;
  IF NOT EXISTS (SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=v_empresa AND u.activo AND u.rol IN ('propietario','socio','operador'))
  THEN RAISE EXCEPTION 'No autorizado para liberar pedidos';END IF;
  IF v_p.motorista_id IS NULL OR v_p.estado<>'pendiente' THEN RAISE EXCEPTION 'Pedido % no elegible: debe estar pendiente y asignado',v_id;END IF;
  IF coalesce(v_p.version_edicion,0)<>v_vers THEN RAISE EXCEPTION 'Pedido % modificado; actualizá Central',v_id;END IF;
  SELECT r.fecha,r.turno,r.estado INTO v_f,v_t,v_estado FROM public.rutas_generales r WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_empresa;
  IF v_f IS DISTINCT FROM p_fecha OR v_t IS DISTINCT FROM p_turno OR v_p.turno IS DISTINCT FROM p_turno
   OR v_estado NOT IN ('abierta','optimizada','en_reparto')
  THEN RAISE EXCEPTION 'Pedido % no pertenece a la ruta operativa abierta',v_id;END IF;
  IF EXISTS(SELECT 1 FROM public.movimientos_financieros mf WHERE mf.pedido_id=v_id)
  OR EXISTS(SELECT 1 FROM public.flota_rechazos_detalle rd WHERE rd.pedido_id=v_id)
  THEN RAISE EXCEPTION 'Pedido % con movimiento financiero: requiere revisión',v_id;END IF;
  IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c WHERE c.empresa_id=v_empresa AND c.motorista_id=v_p.motorista_id AND c.fecha=p_fecha)
  THEN RAISE EXCEPTION 'Pedido % vinculado a una caja presentada o cerrada',v_id;END IF;
  DELETE FROM public.motorista_ordenes_pedidos WHERE pedido_id=v_id AND motorista_id=v_p.motorista_id;
  UPDATE public.pedidos SET motorista_id=NULL,version_edicion=v_vers+1,requiere_revisar_ruta=true,updated_at=now() WHERE id=v_id;
  INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  VALUES(v_id,v_empresa,v_p.tienda_id,auth.uid(),v_vers,v_vers+1,
   jsonb_build_object('accion','liberar_pedido_central','motivo','Liberado para reasignar','motorista_anterior',v_p.motorista_id,
   'motorista_nuevo',NULL,'fecha',v_f,'turno',v_t,'numero_general',v_p.numero_general,'estado_conservado',v_p.estado));
  v_cambiados:=v_cambiados||jsonb_build_array(jsonb_build_object('pedido_id',v_id,'motorista_anterior',v_p.motorista_id,'version',v_vers+1));
 END LOOP;
 RETURN jsonb_build_object('total',v_total,'liberados',v_cambiados);
END;
$function$;

CREATE OR REPLACE FUNCTION public.flota_mis_solicitudes_tienda()
 RETURNS TABLE(estado text, nombre text, created_at timestamp with time zone)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select s.estado,s.nombre,s.created_at from public.flota_solicitudes_tienda s where s.usuario_id=auth.uid() order by s.created_at desc limit 1;
$function$;

CREATE OR REPLACE FUNCTION public.flota_ordenes_motoristas_fecha(p_fecha date)
 RETURNS TABLE(motorista_id uuid, pedido_id uuid, posicion integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select x.motorista_id,x.pedido_id,x.posicion
 from public.motorista_ordenes_pedidos x
 join public.motoristas m on m.id=x.motorista_id
 where x.fecha=p_fecha and exists (
  select 1 from public.flota_usuarios u
  where u.usuario_id=auth.uid() and u.empresa_id=m.empresa_id and u.activo=true
 )
$function$;

CREATE OR REPLACE FUNCTION public.flota_pasar_pedidos_manana_central(p_pedidos uuid[], p_versiones jsonb, p_fecha_origen date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_hoy date := (now() AT TIME ZONE 'America/Asuncion')::date;
 v_manana date := (now() AT TIME ZONE 'America/Asuncion')::date+1;
 v_empresa uuid;
 v_usuario uuid:=auth.uid();
 v_total integer;
 v_id uuid;
 v_p public.pedidos%rowtype;
 v_orig public.rutas_generales%rowtype;
 v_ruta uuid;
 v_num integer;
 v_v integer;
 v_items jsonb:='[]'::jsonb;
BEGIN
 IF v_usuario IS NULL THEN RAISE EXCEPTION 'Debés iniciar sesión';END IF;
 IF p_fecha_origen IS NULL OR p_fecha_origen<>v_hoy THEN
  RAISE EXCEPTION 'Solo podés pasar a mañana pedidos de la jornada actual';END IF;
 v_total:=coalesce(cardinality(p_pedidos),0);
 IF v_total<1 OR v_total>100 OR
   (SELECT count(DISTINCT v.id) FROM unnest(p_pedidos) v(id))<>v_total OR
   EXISTS(SELECT 1 FROM unnest(p_pedidos) v(id) WHERE v.id IS NULL) THEN
  RAISE EXCEPTION 'Seleccioná de 1 a 100 pedidos sin duplicaciones';END IF;
 IF p_versiones IS NULL OR jsonb_typeof(p_versiones)<>'object' THEN
  RAISE EXCEPTION 'Faltan las versiones de edición';END IF;
 SELECT empresa_id INTO v_empresa FROM public.flota_usuarios
 WHERE usuario_id=v_usuario AND activo AND rol IN ('propietario','socio','operador')
 ORDER BY created_at LIMIT 1;
 IF v_empresa IS NULL THEN RAISE EXCEPTION 'No tenés permisos para mover pedidos';END IF;
 -- Mismo candado que usa Pasa mañana del motorista: evita rutas y números duplicados.
 PERFORM pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(v_manana::text||'manana'));
 PERFORM 1 FROM public.pedidos p WHERE p.id=ANY(p_pedidos) ORDER BY p.id FOR UPDATE;
 IF (SELECT count(*) FROM public.pedidos WHERE id=ANY(p_pedidos))<>v_total THEN
  RAISE EXCEPTION 'Uno o más pedidos ya no existen';END IF;
 -- Validación completa ANTES de cualquier actualización: lote todo o nada.
 FOR v_id IN SELECT z.id FROM unnest(p_pedidos) z(id) ORDER BY z.id LOOP
  SELECT * INTO v_p FROM public.pedidos WHERE id=v_id;
  IF v_p.empresa_id<>v_empresa OR v_p.estado NOT IN ('pendiente','no_responde','no_recibio') THEN
   RAISE EXCEPTION 'Pedido % no es pendiente de esta empresa',v_id;END IF;
  IF NOT(p_versiones ? v_id::text) OR
    (p_versiones->>v_id::text)!~'^[0-9]+$' THEN
   RAISE EXCEPTION 'Falta la versión del pedido %',v_id;END IF;
  v_v:=(p_versiones->>v_id::text)::integer;
  IF v_p.version_edicion IS DISTINCT FROM v_v THEN
   RAISE EXCEPTION 'El pedido % fue modificado; actualizá la lista',v_id;END IF;
  IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_id)
   OR EXISTS(SELECT 1 FROM public.flota_rechazos_detalle d WHERE d.pedido_id=v_id)
  THEN RAISE EXCEPTION 'El pedido % tiene movimientos financieros',v_id;END IF;
  IF v_p.ruta_general_id IS NOT NULL THEN
   SELECT * INTO v_orig FROM public.rutas_generales r
   WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_empresa;
   IF NOT FOUND OR v_orig.fecha<>v_hoy OR v_orig.estado='cerrada' THEN
    RAISE EXCEPTION 'El pedido % no está en una ruta activa de hoy',v_id;END IF;
  ELSE
   IF v_p.motorista_id IS NOT NULL OR
    (v_p.created_at AT TIME ZONE 'America/Asuncion')::date<>v_hoy THEN
    RAISE EXCEPTION 'El pedido % sin ruta no corresponde a la carga de hoy',v_id;END IF;
  END IF;
  IF v_p.motorista_id IS NOT NULL AND EXISTS(
   SELECT 1 FROM public.flota_cierres_motoristas c
   WHERE c.empresa_id=v_empresa AND c.motorista_id=v_p.motorista_id AND c.fecha=v_hoy)
  THEN RAISE EXCEPTION 'La caja de origen de % ya está cerrada',v_id;END IF;
 END LOOP;
 SELECT id INTO v_ruta FROM public.rutas_generales
 WHERE empresa_id=v_empresa AND fecha=v_manana AND turno='manana'
 AND estado IN ('abierta','optimizada','en_reparto')
 ORDER BY created_at,id LIMIT 1 FOR UPDATE;
 IF v_ruta IS NULL THEN
  INSERT INTO public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion)
  VALUES(v_empresa,v_manana,'manana','abierta',0) RETURNING id INTO v_ruta;
 END IF;
 SELECT coalesce(max(numero_general),0) INTO v_num
 FROM public.pedidos WHERE ruta_general_id=v_ruta;
 FOR v_id IN SELECT z.id FROM unnest(p_pedidos) z(id) ORDER BY z.id LOOP
  SELECT * INTO v_p FROM public.pedidos WHERE id=v_id;
  v_num:=v_num+1;
  DELETE FROM public.motorista_ordenes_pedidos WHERE pedido_id=v_id;
  UPDATE public.pedidos SET
   ruta_general_id=v_ruta,numero_general=v_num,motorista_id=NULL,
   turno='manana',estado='pendiente',medio_cobro=NULL,
   motivo_incidencia='Reprogramado desde '||to_char(v_hoy,'DD/MM/YYYY')||' · Reprogramado por Central',
   requiere_revisar_ruta=true,version_edicion=v_p.version_edicion+1,updated_at=now()
  WHERE id=v_id;
  INSERT INTO public.pedidos_ediciones(
   pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  VALUES(v_id,v_empresa,v_p.tienda_id,v_usuario,
   v_p.version_edicion,v_p.version_edicion+1,
   pg_catalog.jsonb_build_object(
    'accion','pasar_manana_central','fecha_anterior',v_hoy,'fecha_nueva',v_manana,
    'ruta_anterior',v_p.ruta_general_id,'ruta_nueva',v_ruta,
    'motorista_anterior',v_p.motorista_id,'motorista_nuevo',NULL,
    'estado_anterior',v_p.estado,'estado_nuevo','pendiente',
    'turno_anterior',v_p.turno,'turno_nuevo','manana',
    'numero_anterior',v_p.numero_general,'numero_nuevo',v_num,
    'motivo_anterior',v_p.motivo_incidencia,
    'motivo_nuevo','Reprogramado por Central',
    'precio_delivery_preservado',v_p.precio_delivery));
  v_items:=v_items||pg_catalog.jsonb_build_array(
   pg_catalog.jsonb_build_object('pedido_id',v_id,'numero_nuevo',v_num));
 END LOOP;
 RETURN pg_catalog.jsonb_build_object('total',v_total,'fecha_destino',v_manana,
  'ruta_destino',v_ruta,'pedidos',v_items);
END
$function$;

CREATE OR REPLACE FUNCTION public.flota_proteger_persa_interna_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if new.id='dba40a47-befa-464f-8b29-404030c5d169'::uuid and new.empresa_id='a0000000-0000-0000-0000-000000000001'::uuid then
 new.uso_interno_logistico=true;
 end if;
 return new;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_puede_leer(p_empresa uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
select exists(select 1 from public.flota_usuarios x where x.empresa_id=p_empresa and x.usuario_id=auth.uid() and x.activo)
$function$;

CREATE OR REPLACE FUNCTION public.flota_quitar_pedidos_ruta_seguros(p_pedidos uuid[], p_versiones jsonb, p_fecha date)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid:='a0000000-0000-0000-0000-000000000001'::uuid;
 v_total integer; v_validados integer; v_p public.pedidos%rowtype; v_version integer;
begin
 v_total=coalesce(array_length(p_pedidos,1),0);
 if v_total<1 or v_total>100 or (select count(distinct x) from unnest(p_pedidos) as x)<>v_total
 then raise exception 'Selección inválida';end if;
 if p_fecha is distinct from (now() at time zone 'America/Asuncion')::date then raise exception 'Solo se pueden quitar pedidos de la jornada de hoy';end if;
 if not exists(select 1 from public.flota_usuarios f where f.empresa_id=v_empresa and f.usuario_id=auth.uid() and f.activo and f.rol in ('propietario','socio','operador'))
 then raise exception 'Sin permisos para modificar rutas';end if;
 perform 1 from public.pedidos p where p.id=any(p_pedidos) order by p.id for update;
 select count(*) into v_validados from public.pedidos p
 left join public.rutas_generales r on r.id=p.ruta_general_id and r.empresa_id=p.empresa_id
 where p.id=any(p_pedidos) and p.empresa_id=v_empresa
 and p.estado='pendiente' and p.excluido_ruta=false
 and (coalesce(p.version_edicion,0)=nullif(p_versiones->>(p.id::text),'')::integer)
 and ((r.fecha=p_fecha and r.estado in ('abierta','optimizada','en_reparto'))
      or (p.ruta_general_id is null and p.motorista_id is null and (p.created_at at time zone 'America/Asuncion')::date=p_fecha))
 and not exists(select 1 from public.movimientos_financieros mf where mf.pedido_id=p.id)
 and not exists(select 1 from public.flota_rechazos_detalle fr where fr.pedido_id=p.id)
 and not exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=p.motorista_id and c.fecha=p_fecha);
 if v_validados<>v_total then raise exception 'Algún pedido ya se entregó, cobró, cambió o no pertenece a hoy. Actualizá Central';end if;
 for v_p in select * from public.pedidos where id=any(p_pedidos) order by id loop
  v_version=coalesce(v_p.version_edicion,0);
  update public.pedidos set motorista_id=null,ruta_general_id=null,numero_general=null,
   excluido_ruta=true,requiere_revisar_ruta=false,version_edicion=v_version+1,updated_at=now()
   where id=v_p.id;
  insert into public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  values(v_p.id,v_empresa,v_p.tienda_id,auth.uid(),v_version,v_version+1,
    pg_catalog.jsonb_build_object('accion','quitar_de_ruta_sin_borrar_pedido','fecha',p_fecha,
    'ruta_anterior',v_p.ruta_general_id,'numero_anterior',v_p.numero_general,
    'motorista_anterior',v_p.motorista_id,'estado_conservado',v_p.estado));
 end loop;
 return v_total;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_reasignar_lote_seguro(p_pedidos uuid[], p_motorista_destino uuid, p_versiones jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_id uuid;v_n integer;v_result jsonb;v_results jsonb:='[]'::jsonb;v_total integer;
BEGIN
 v_total:=coalesce(pg_catalog.array_length(p_pedidos,1),0);
 IF v_total<1 OR v_total>100 OR (SELECT count(DISTINCT z) FROM unnest(p_pedidos) AS z)<>v_total THEN
 RAISE EXCEPTION 'Seleccioná de 1 a 100 pedidos sin duplicados';
 END IF;
 IF p_motorista_destino IS NULL OR p_versiones IS NULL OR jsonb_typeof(p_versiones)<>'object' THEN
 RAISE EXCEPTION 'Falta motorista o versión de los pedidos';
 END IF;
 FOR v_id IN SELECT z FROM unnest(p_pedidos) z ORDER BY z LOOP
   IF NOT (p_versiones ? v_id::text) OR (p_versiones->>v_id::text) !~ '^[0-9]+$' THEN
      RAISE EXCEPTION 'Falta la versión del pedido %. Actualizá Central',v_id;
   END IF;
   v_n:=(p_versiones->>v_id::text)::integer;
   v_result:=public.flota_reasignar_pedido_seguro(v_id,p_motorista_destino,v_n);
   v_results:=v_results || jsonb_build_array(v_result);
 END LOOP;
 RETURN jsonb_build_object('total',v_total,'resultados',v_results);
END;
$function$;

CREATE OR REPLACE FUNCTION public.flota_reasignar_pedido_seguro(p_pedido uuid, p_motorista_destino uuid, p_version integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_p public.pedidos%rowtype;
 v_m public.motoristas%rowtype;
 v_fecha date;
 v_old uuid;
 v_pos integer;
 v_newversion integer;
BEGIN
 IF p_pedido IS NULL OR p_motorista_destino IS NULL OR p_version IS NULL THEN
   RAISE EXCEPTION 'Parámetros incompletos';
 END IF;
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
 IF NOT EXISTS (
    SELECT 1 FROM public.flota_usuarios f
    WHERE f.empresa_id=v_p.empresa_id AND f.usuario_id=auth.uid()
      AND f.activo AND f.rol IN ('propietario','socio','operador')
 ) THEN RAISE EXCEPTION 'Sin permiso para reasignar'; END IF;
 SELECT * INTO v_m FROM public.motoristas
 WHERE id=p_motorista_destino AND empresa_id=v_p.empresa_id AND activo FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Motorista destino inexistente o inactivo'; END IF;
 IF v_p.motorista_id IS NOT DISTINCT FROM p_motorista_destino THEN
   RETURN pg_catalog.jsonb_build_object('cambio',false,'pedido_id',v_p.id,'motorista_id',v_p.motorista_id,'version',v_p.version_edicion);
 END IF;
 IF v_p.motorista_id IS NULL THEN RAISE EXCEPTION 'Usar asignación normal para pedidos sin motorista'; END IF;
 IF coalesce(v_p.version_edicion,0)<>p_version THEN
   RAISE EXCEPTION 'Pedido modificado por otra persona: actualizá la pantalla';
 END IF;
 IF v_p.estado NOT IN ('pendiente','pasa_manana','no_responde','no_recibio') THEN
   RAISE EXCEPTION 'Solo se reasignan pedidos no cobrados y aún no finalizados';
 END IF;
 IF EXISTS (SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=p_pedido) THEN
   RAISE EXCEPTION 'Pedido con movimiento financiero; requiere conciliación';
 END IF;
 SELECT fecha INTO v_fecha FROM public.rutas_generales
 WHERE id=v_p.ruta_general_id AND empresa_id=v_p.empresa_id;
 IF v_fecha IS NULL THEN
   RAISE EXCEPTION 'Pedido sin fecha de ruta válida';
 END IF;
 IF EXISTS (
   SELECT 1 FROM public.flota_cierres_motoristas c
   WHERE c.empresa_id=v_p.empresa_id AND c.fecha=v_fecha
     AND c.motorista_id IN (v_p.motorista_id,p_motorista_destino)
 ) THEN RAISE EXCEPTION 'Una de las cajas está cerrada o presentada'; END IF;
 v_old:=v_p.motorista_id;
 -- Se elimina solo el orden individual anterior; no se toca el número general ni el turno.
 DELETE FROM public.motorista_ordenes_pedidos
 WHERE pedido_id=p_pedido AND motorista_id=v_old;
 SELECT coalesce(max(posicion),0)+1 INTO v_pos
 FROM public.motorista_ordenes_pedidos
 WHERE motorista_id=p_motorista_destino AND fecha=v_fecha;
 INSERT INTO public.motorista_ordenes_pedidos(motorista_id,fecha,pedido_id,posicion)
 VALUES (p_motorista_destino,v_fecha,p_pedido,v_pos)
 ON CONFLICT (motorista_id,fecha,pedido_id)
 DO UPDATE SET posicion=excluded.posicion,updated_at=now();
 v_newversion:=p_version+1;
 UPDATE public.pedidos SET
   motorista_id=p_motorista_destino,
   version_edicion=v_newversion,
   updated_at=now()
 WHERE id=p_pedido;
 INSERT INTO public.pedidos_ediciones(
  pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios
 ) VALUES(
  p_pedido,v_p.empresa_id,v_p.tienda_id,auth.uid(),p_version,v_newversion,
  pg_catalog.jsonb_build_object(
   'accion','reasignacion_central',
   'motorista_anterior',v_old,
   'motorista_nuevo',p_motorista_destino,
   'estado_conservado',v_p.estado,
   'fecha',v_fecha,
   'turno',v_p.turno,
   'numero_general',v_p.numero_general
  )
 );
 RETURN pg_catalog.jsonb_build_object('cambio',true,'pedido_id',p_pedido,'motorista_anterior',v_old,'motorista_nuevo',p_motorista_destino,'version',v_newversion);
END;
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

CREATE OR REPLACE FUNCTION public.flota_recorridos_confirmados_fecha(p_fecha date)
 RETURNS TABLE(motorista_id uuid, empresa_id uuid, fecha date, version bigint, pedido_ids uuid[], coordenadas jsonb, origen_lat double precision, origen_lng double precision, confirmado_en timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select c.motorista_id,c.empresa_id,c.fecha,c.version,c.pedido_ids,c.coordenadas,c.origen_lat,c.origen_lng,c.confirmado_en
 from public.motorista_recorridos_confirmados c
 where c.fecha=p_fecha and exists(
   select 1 from public.flota_usuarios u where u.empresa_id=c.empresa_id
    and u.usuario_id=(select auth.uid()) and u.activo and u.rol in('propietario','socio','operador')
 );
$function$;

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

CREATE OR REPLACE FUNCTION public.flota_registrar_pago_tienda(p_tienda uuid, p_fecha date, p_importe integer, p_medio text, p_referencia text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;v_id uuid;v_base bigint;v_comp bigint;v_rechazos bigint;v_pagado bigint;v_fecha date;
begin
 select u.empresa_id into v_empresa from public.flota_usuarios u where u.usuario_id=auth.uid() and u.activo and
 (u.rol='propietario' or u.puede_confirmar_rendiciones) limit 1;
 if v_empresa is null then raise exception 'No autorizado para registrar pagos';end if;
 if not exists(select 1 from public.tiendas t where t.id=p_tienda and t.empresa_id=v_empresa) then raise exception 'Tienda no autorizada';end if;
 v_fecha=(now() at time zone 'America/Asuncion')::date;
 if p_fecha is null or p_fecha>v_fecha or p_importe is null or p_importe<=0 or p_medio not in ('efectivo','transferencia')
 or length(btrim(coalesce(p_referencia,'')))<5 then raise exception 'Datos de pago inválidos';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text||p_tienda::text),pg_catalog.hashtext(p_fecha::text));
 select coalesce(sum(case when p.estado='entregado' and p.modalidad_pago='pendiente' then m.monto_mercaderia-coalesce(p.delivery_subsidio_tienda,0) else 0 end),0)
       -coalesce(sum(case when p.estado='entregado' and p.modalidad_pago='todo_pagado' then m.monto_delivery when p.estado='entregado' and p.modalidad_pago='producto_pagado' then coalesce(p.delivery_subsidio_tienda,0) else 0 end),0)
 into v_base from public.movimientos_financieros m join public.pedidos p on p.id=m.pedido_id
 where m.empresa_id=v_empresa and m.tienda_id=p_tienda
 and (m.created_at at time zone 'America/Asuncion')::date=p_fecha;
 select coalesce(sum(c.importe),0) into v_comp from public.flota_compensaciones_tienda c
 where c.empresa_id=v_empresa and c.tienda_id=p_tienda and c.fecha_rendicion=p_fecha;
 select coalesce(sum(r.importe_pendiente),0) into v_rechazos
 from public.flota_rechazos_detalle r join public.pedidos p on p.id=r.pedido_id
 join public.movimientos_financieros m on m.pedido_id=p.id
 where r.empresa_id=v_empresa and r.tienda_id=p_tienda and p.estado='rechazado' and r.responsable_pago='tienda'
 and r.importe_pendiente>0
 and (m.created_at at time zone 'America/Asuncion')::date=p_fecha
 and not exists(select 1 from public.flota_compensaciones_tienda c where c.pedido_id=r.pedido_id);
 select coalesce(sum(x.importe),0) into v_pagado from public.flota_pagos_tienda x
 where x.empresa_id=v_empresa and x.tienda_id=p_tienda and x.fecha_rendicion=p_fecha;
 if p_importe>v_base-v_comp-v_rechazos-v_pagado then
   raise exception 'El pago excede el saldo neto: los rechazos de la tienda ya están descontados';
 end if;
 insert into public.flota_pagos_tienda(empresa_id,tienda_id,fecha_rendicion,importe,medio,referencia,confirmado_por)
 values(v_empresa,p_tienda,p_fecha,p_importe,p_medio,btrim(p_referencia),auth.uid()) returning id into v_id;
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
declare v_empresa uuid; v_destino uuid; v_dest_estado text; v_total integer := 0; r record;
begin
 if p_turno is null or p_turno not in ('manana','tarde','sin_definir') or p_fecha is null then raise exception 'Fecha y turno inválidos'; end if;
 select empresa_id into v_empresa from public.flota_usuarios
  where usuario_id = auth.uid() and activo and rol in ('propietario','socio','operador') order by created_at limit 1;
 if v_empresa is null then raise exception 'No autorizado'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text), pg_catalog.hashtext(p_fecha::text || p_turno));
 select id, estado into v_destino, v_dest_estado from public.rutas_generales
  where empresa_id = v_empresa and fecha = p_fecha and turno = p_turno and estado in ('abierta','optimizada','en_reparto')
  order by created_at limit 1 for update;
 if v_destino is null then raise exception 'Primero creá la ruta del turno'; end if;
 for r in
  select p.id, p.version_edicion, p.tienda_id, p.ruta_general_id, p.numero_general
  from public.pedidos p join public.rutas_generales g on g.id = p.ruta_general_id
  where g.empresa_id = v_empresa and g.id <> v_destino
    and ((g.turno is null and g.estado = 'abierta' and g.fecha <= p_fecha)
      or (g.fecha < p_fecha and g.estado <> 'cerrada'))
    and p.empresa_id = v_empresa and p.estado = 'pendiente' and p.motorista_id is null
    and coalesce(p.turno, 'sin_definir') = p_turno
    and not exists (select 1 from public.movimientos_financieros mf where mf.pedido_id = p.id)
  order by p.id
  for update of p
 loop
  update public.pedidos
     set ruta_general_id = v_destino,
         numero_general = null, requiere_revisar_ruta = true,
         version_edicion = coalesce(version_edicion, 0) + 1, updated_at = now()
   where id = r.id;
  insert into public.pedidos_ediciones(pedido_id, empresa_id, tienda_id, usuario_id, version_anterior, version_nueva, cambios)
  values (r.id, v_empresa, r.tienda_id, auth.uid(), coalesce(r.version_edicion, 0), coalesce(r.version_edicion, 0) + 1,
          jsonb_build_object('ruta_general_id', jsonb_build_object('antes', r.ruta_general_id, 'despues', v_destino),
                             'numero_general', jsonb_build_object('antes', r.numero_general, 'despues', null),
                             'motivo', 'rescate de pedido pendiente desde ruta anterior'));
  v_total := v_total + 1;
 end loop;
 update public.rutas_generales g set estado = 'cerrada'
  where g.empresa_id = v_empresa and g.id <> v_destino and g.estado <> 'cerrada'
    and ((g.turno is null and g.fecha <= p_fecha) or g.fecha < p_fecha)
    and not exists (select 1 from public.pedidos p where p.ruta_general_id = g.id);
 return v_total;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_reprogramar_asignar_historico(p_pedidos uuid[], p_motorista uuid, p_fecha_origen date, p_turno_destino text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_empresa uuid;v_pct integer;v_hoy date;v_total integer;v_valid integer;
 v_destino uuid;v_n integer;v record;
begin
 v_hoy=(now() at time zone 'America/Asuncion')::date;
 v_total=coalesce(array_length(p_pedidos,1),0);
 if p_fecha_origen is null or p_fecha_origen>=v_hoy or p_turno_destino not in ('manana','tarde')
 or v_total<1 or v_total>100 or (select count(distinct x) from unnest(p_pedidos) as x)<>v_total then raise exception 'Fecha, turno o selección inválida';end if;
 select m.empresa_id,m.porcentaje_empresa_pct into v_empresa,v_pct
 from public.motoristas m where m.id=p_motorista and m.activo for update;
 if v_empresa is null then raise exception 'Motorista inexistente o inactivo';end if;
 if not exists(select 1 from public.flota_usuarios u where u.usuario_id=auth.uid() and u.empresa_id=v_empresa and u.activo and u.rol in ('propietario','socio','operador')) then raise exception 'No autorizado';end if;
 if exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=p_motorista and c.fecha=v_hoy) then raise exception 'Motorista con jornada cerrada';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(v_hoy::text||p_turno_destino));
 perform 1 from public.pedidos p where p.id=any(p_pedidos) order by p.id for update;
 select count(*) into v_valid from public.pedidos p
 left join public.rutas_generales g on g.id=p.ruta_general_id
 where p.id=any(p_pedidos) and p.empresa_id=v_empresa and p.estado='pendiente'
 and p.motorista_id is null and p.lat is not null and p.lng is not null
 and coalesce(g.fecha,(p.created_at at time zone 'America/Asuncion')::date)=p_fecha_origen
 and not exists(select 1 from public.movimientos_financieros mf where mf.pedido_id=p.id);
 if v_valid<>v_total then raise exception 'Hay pedidos ya entregados, asignados, sin GPS o con movimientos de caja. Actualizá el historial';end if;
 select g.id into v_destino from public.rutas_generales g
 where g.empresa_id=v_empresa and g.fecha=v_hoy and g.turno=p_turno_destino
 and g.estado in ('abierta','optimizada','en_reparto')
 order by g.created_at limit 1 for update;
 if v_destino is null then
  insert into public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion)
  values(v_empresa,v_hoy,p_turno_destino,'en_reparto',0) returning id into v_destino;
 end if;
 select coalesce(max(numero_general),0) into v_n from public.pedidos where ruta_general_id=v_destino;
 for v in
 select p.id,p.tienda_id,p.ruta_general_id,p.numero_general,p.turno,p.version_edicion
 from public.pedidos p where p.id=any(p_pedidos) order by p.created_at,p.id
 loop
  v_n=v_n+1;
  update public.pedidos p set ruta_general_id=v_destino,numero_general=v_n,
  turno=p_turno_destino,motorista_id=p_motorista,
  porcentaje_empresa_pct=v_pct,porcentaje_motorista_pct=100-v_pct,
  requiere_revisar_ruta=false,version_edicion=coalesce(p.version_edicion,0)+1,updated_at=now()
  where p.id=v.id;
  insert into public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  values (v.id,v_empresa,v.tienda_id,auth.uid(),coalesce(v.version_edicion,0),coalesce(v.version_edicion,0)+1,
   jsonb_build_object('accion','reprogramado_desde_historico',
   'fecha_origen',p_fecha_origen,'fecha_destino',v_hoy,
   'ruta_general_id',jsonb_build_object('antes',v.ruta_general_id,'despues',v_destino),
   'numero_general',jsonb_build_object('antes',v.numero_general,'despues',v_n),
   'turno',jsonb_build_object('antes',v.turno,'despues',p_turno_destino),
   'motorista_nuevo',p_motorista));
 end loop;
 update public.rutas_generales set estado='en_reparto' where id=v_destino and estado<>'en_reparto';
 return v_total;
end $function$;

CREATE OR REPLACE FUNCTION public.flota_reprogramar_pedidos_asignados(p_pedidos uuid[], p_motorista_destino uuid, p_fecha_destino date, p_turno_destino text, p_versiones jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_total integer; v_empresa uuid; v_pct integer; v_hoy date;
 v_ruta_dest uuid; v_num integer; v_pos integer;
 v_id uuid; v_p public.pedidos%rowtype; v_orig public.rutas_generales%rowtype;
 v_cambios jsonb:='[]'::jsonb; v_v integer;
BEGIN
 v_hoy:=(now() AT TIME ZONE 'America/Asuncion')::date;
 v_total:=coalesce(array_length(p_pedidos,1),0);
 IF v_total<1 OR v_total>100 OR (SELECT count(DISTINCT t.id) FROM unnest(p_pedidos) t(id))<>v_total THEN RAISE EXCEPTION 'Seleccioná de 1 a 100 pedidos sin duplicar'; END IF;
 IF p_fecha_destino IS NULL OR p_fecha_destino<v_hoy OR p_fecha_destino>v_hoy+14 THEN RAISE EXCEPTION 'La nueva fecha debe estar entre hoy y los próximos 14 días'; END IF;
 IF p_turno_destino NOT IN ('manana','tarde') THEN RAISE EXCEPTION 'Elegí mañana o tarde'; END IF;
 IF p_versiones IS NULL OR jsonb_typeof(p_versiones)<>'object' THEN RAISE EXCEPTION 'Faltan versiones de los pedidos'; END IF;
 SELECT m.empresa_id,m.porcentaje_empresa_pct INTO v_empresa,v_pct
 FROM public.motoristas m WHERE m.id=p_motorista_destino AND m.activo FOR UPDATE;
 IF NOT FOUND OR v_pct NOT BETWEEN 0 AND 100 THEN RAISE EXCEPTION 'Motorista destino no disponible'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=v_empresa AND u.activo AND u.rol IN ('propietario','socio','operador')) THEN RAISE EXCEPTION 'Sin permiso para mover pedidos'; END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_empresa::text),pg_catalog.hashtext(p_fecha_destino::text||p_turno_destino));
 PERFORM 1 FROM public.pedidos p WHERE p.id=ANY(p_pedidos) ORDER BY p.id FOR UPDATE;
 IF (SELECT count(*) FROM public.pedidos WHERE id=ANY(p_pedidos))<>v_total THEN RAISE EXCEPTION 'Hay pedidos que ya no existen'; END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas WHERE empresa_id=v_empresa AND motorista_id=p_motorista_destino AND fecha=p_fecha_destino) THEN RAISE EXCEPTION 'La caja de destino ya está cerrada'; END IF;
 SELECT r.id INTO v_ruta_dest FROM public.rutas_generales r
 WHERE r.empresa_id=v_empresa AND r.fecha=p_fecha_destino AND r.turno=p_turno_destino AND r.estado IN ('abierta','optimizada','en_reparto')
 ORDER BY r.created_at,r.id LIMIT 1 FOR UPDATE;
 IF v_ruta_dest IS NULL THEN
    INSERT INTO public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion)
    VALUES(v_empresa,p_fecha_destino,p_turno_destino,'en_reparto',0)
    RETURNING id INTO v_ruta_dest;
 END IF;
 SELECT coalesce(max(p.numero_general),0) INTO v_num FROM public.pedidos p WHERE p.ruta_general_id=v_ruta_dest;
 SELECT coalesce(max(o.posicion),0) INTO v_pos FROM public.motorista_ordenes_pedidos o WHERE o.motorista_id=p_motorista_destino AND o.fecha=p_fecha_destino;
 FOR v_id IN SELECT t.id FROM unnest(p_pedidos) t(id) ORDER BY t.id LOOP
    SELECT * INTO v_p FROM public.pedidos WHERE id=v_id;
    IF v_p.empresa_id<>v_empresa OR v_p.motorista_id IS NULL THEN RAISE EXCEPTION 'Pedido % no pertenece a una moto de esta empresa',v_id; END IF;
    IF v_p.estado NOT IN ('pendiente','no_responde','no_recibio','pasa_manana') THEN RAISE EXCEPTION 'Pedido % ya terminado',v_id; END IF;
    IF NOT (p_versiones ? v_id::text) OR (p_versiones->>v_id::text) !~ '^[0-9]+$' THEN RAISE EXCEPTION 'Falta versión del pedido %',v_id; END IF;
    v_v:=(p_versiones->>v_id::text)::integer;
    IF coalesce(v_p.version_edicion,0)<>v_v THEN RAISE EXCEPTION 'Pedido % cambiado por otra persona: actualizá la pantalla',v_id; END IF;
    IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_id) THEN RAISE EXCEPTION 'Pedido % tiene cobros y no se puede mover',v_id; END IF;
    SELECT * INTO v_orig FROM public.rutas_generales r WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_empresa;
    IF NOT FOUND OR v_orig.estado='cerrada' THEN RAISE EXCEPTION 'Pedido % tiene origen sin ruta válida o cerrada',v_id; END IF;
    IF v_orig.fecha>=p_fecha_destino THEN RAISE EXCEPTION 'La fecha destino debe ser posterior a la fecha de origen'; END IF;
    IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c WHERE c.empresa_id=v_empresa AND c.motorista_id=v_p.motorista_id AND c.fecha=v_orig.fecha) THEN RAISE EXCEPTION 'La caja original del pedido % está cerrada',v_id; END IF;
    DELETE FROM public.motorista_ordenes_pedidos WHERE pedido_id=v_id;
    v_num:=v_num+1;v_pos:=v_pos+1;
    UPDATE public.pedidos SET ruta_general_id=v_ruta_dest,numero_general=v_num,
      motorista_id=p_motorista_destino,turno=p_turno_destino,estado='pendiente',motivo_incidencia=NULL,
      porcentaje_empresa_pct=v_pct,porcentaje_motorista_pct=100-v_pct,
      requiere_revisar_ruta=true,version_edicion=v_v+1,updated_at=now()
    WHERE id=v_id;
    INSERT INTO public.motorista_ordenes_pedidos(motorista_id,fecha,pedido_id,posicion)
    VALUES(p_motorista_destino,p_fecha_destino,v_id,v_pos);
    INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
    VALUES(v_id,v_empresa,v_p.tienda_id,auth.uid(),v_v,v_v+1,
     jsonb_build_object('accion','reprogramar_pedido_asignado','motorista_anterior',v_p.motorista_id,
     'motorista_nuevo',p_motorista_destino,'fecha_anterior',v_orig.fecha,'fecha_nueva',p_fecha_destino,
     'turno_anterior',v_p.turno,'turno_nuevo',p_turno_destino,'numero_anterior',v_p.numero_general,
     'numero_nuevo',v_num,'estado_anterior',v_p.estado,'motivo_anterior',v_p.motivo_incidencia));
    v_cambios:=v_cambios||jsonb_build_array(jsonb_build_object('pedido_id',v_id,'numero_nuevo',v_num));
 END LOOP;
 UPDATE public.rutas_generales SET estado='en_reparto' WHERE id=v_ruta_dest AND estado IN ('abierta','optimizada');
 RETURN jsonb_build_object('total',v_total,'ruta_destino',v_ruta_dest,'fecha_destino',p_fecha_destino,'motorista_id',p_motorista_destino,'pedidos',v_cambios);
END;
$function$;

CREATE OR REPLACE FUNCTION public.flota_reservar_optimizacion_google()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_empresa uuid;
 v_hoy date := (now() at time zone 'America/Asuncion')::date;
 v_mes text := to_char(now() at time zone 'America/Asuncion','YYYY-MM');
 v_clave text;
 v_consumido integer;
begin
 select m.empresa_id into v_empresa
 from public.motoristas m where m.usuario_id=auth.uid() and m.activo order by m.created_at limit 1;
 if v_empresa is null then raise exception 'No autorizado';end if;
 -- Bloqueo global: evita que varias flotas simultáneas sobrepasen el cupo del proyecto.
 perform pg_catalog.pg_advisory_xact_lock(764000,764001);
 -- Margen conservador frente a 5.000 consultas gratuitas mensuales del SKU Pro,
 -- NO constituye garantía de que el proyecto Google no tenga otros consumos.
 foreach v_clave in array array[
 'proyecto:mes:'||v_mes,
 'proyecto:dia:'||v_hoy::text,
 'empresa:'||v_empresa::text||':dia:'||v_hoy::text
 ] loop
  select c.cantidad into v_consumido from public.flota_cupo_optimizacion_google c where c.clave=v_clave;
  if (v_clave like 'proyecto:mes:%' and coalesce(v_consumido,0)>=1500)
    or (v_clave like 'proyecto:dia:%' and coalesce(v_consumido,0)>=60)
    or (v_clave like 'empresa:%' and coalesce(v_consumido,0)>=20)
  then return jsonb_build_object('autorizado',false,'motivo','Límite preventivo de optimizaciones Google alcanzado. Usaremos OSRM sin bloquear entregas.');end if;
 end loop;
 foreach v_clave in array array[
 'proyecto:mes:'||v_mes,
 'proyecto:dia:'||v_hoy::text,
 'empresa:'||v_empresa::text||':dia:'||v_hoy::text
 ] loop
  insert into public.flota_cupo_optimizacion_google(clave,cantidad)
  values(v_clave,1)
  on conflict(clave) do update
  set cantidad=public.flota_cupo_optimizacion_google.cantidad+1, actualizado_en=now();
 end loop;
 return jsonb_build_object('autorizado',true,'cupo_mensual_interno',1500);
end $function$;

CREATE OR REPLACE FUNCTION public.flota_resumen_ajustes_tienda(p_fecha date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_empresa uuid;
begin
 select u.empresa_id into v_empresa from public.flota_usuarios u where u.usuario_id=auth.uid() and u.activo and
 (u.rol='propietario' or u.puede_finanzas) limit 1;
 if v_empresa is null then raise exception 'Sin permiso de finanzas';end if;
 return jsonb_build_object(
  'compensaciones',coalesce((select jsonb_agg(jsonb_build_object('tienda_id',c.tienda_id,'pedido_id',c.pedido_id,'importe',c.importe,'referencia',c.referencia,'fecha',c.confirmado_en)) from public.flota_compensaciones_tienda c where c.empresa_id=v_empresa and c.fecha_rendicion=p_fecha),'[]'::jsonb),
  'pagos',coalesce((select jsonb_agg(jsonb_build_object('tienda_id',p.tienda_id,'importe',p.importe,'medio',p.medio,'referencia',p.referencia,'fecha',p.confirmado_en)) from public.flota_pagos_tienda p where p.empresa_id=v_empresa and p.fecha_rendicion=p_fecha),'[]'::jsonb)
 );
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

CREATE OR REPLACE FUNCTION public.flota_saldos_rechazos_por_tienda()
 RETURNS TABLE(pedido_id uuid, tienda_id uuid, nombre_cliente text, fecha_ruta date, costo_rechazo integer, compensado integer, saldo_pendiente integer, estado_cobro text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT r.pedido_id,r.tienda_id,p.nombre_cliente,g.fecha,
  greatest(0,r.importe_pendiente)::integer,
  coalesce(c.importe,0)::integer,
  greatest(0,r.importe_pendiente-coalesce(c.importe,0))::integer,
  CASE WHEN c.id IS NOT NULL THEN 'compensado'
       WHEN r.importe_pendiente>0 THEN 'pendiente'
       ELSE 'sin_saldo' END::text
 FROM public.flota_rechazos_detalle r
 JOIN public.pedidos p ON p.id=r.pedido_id
 LEFT JOIN public.rutas_generales g ON g.id=p.ruta_general_id
 LEFT JOIN public.flota_compensaciones_tienda c ON c.pedido_id=r.pedido_id AND c.empresa_id=r.empresa_id
 WHERE r.responsable_pago='tienda' AND p.estado='rechazado'
 AND EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=r.empresa_id AND u.activo AND (u.rol='propietario' OR u.puede_finanzas OR u.puede_confirmar_rendiciones))
 ORDER BY g.fecha DESC,p.nombre_cliente;
$function$;

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
 if exists(select 1 from public.flota_usuarios f where f.usuario_id=auth.uid() and f.activo)
    or exists(select 1 from public.motoristas m where m.usuario_id=auth.uid() and m.activo)
 then raise exception 'Esta cuenta pertenece a otro rol (Central o Motorista). Ingresá por el acceso correspondiente';end if;
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

CREATE OR REPLACE FUNCTION public.flota_tarifas_vigentes(p_empresa uuid)
 RETURNS TABLE(localidad text, costo_envio integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT tz.localidad,tz.costo_envio
 FROM public.tarifas_zona tz
 WHERE tz.empresa_id=p_empresa AND tz.activo
 AND (
  EXISTS (SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=p_empresa AND u.activo)
  OR EXISTS (
   SELECT 1 FROM public.tiendas t
   WHERE t.empresa_id=p_empresa AND t.activo AND
   (t.usuario_id=auth.uid() OR EXISTS (SELECT 1 FROM public.tienda_miembros tm WHERE tm.tienda_id=t.id AND tm.usuario_id=auth.uid() AND tm.activo))
  )
 )
 ORDER BY tz.localidad;
$function$;

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

CREATE OR REPLACE FUNCTION public.flota_validar_origen_tarifa_pedido()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_esperado integer;v_manual boolean;v_admin boolean;
BEGIN
 IF TG_OP='INSERT' THEN
  IF NEW.tarifa_origen IS NULL THEN RETURN NEW;END IF; -- Integraciones antiguas: sin cambio retrospectivo
  IF NEW.tarifa_origen='automatica' THEN
   SELECT t.costo_envio INTO v_esperado FROM public.tarifas_zona t
    WHERE t.empresa_id=NEW.empresa_id AND t.localidad=NEW.tarifa_localidad AND t.activo;
   IF v_esperado IS NULL OR NEW.precio_delivery IS DISTINCT FROM v_esperado
   THEN RAISE EXCEPTION 'Tarifa preestablecida inválida para %. Actualizá la lista de precios.',NEW.tarifa_localidad;END IF;
  ELSIF NEW.tarifa_origen='manual' THEN
   SELECT (lower(trim(t.nombre_comercial)) IN ('boom','boom store','tienda boom','persa boutique','tienda persa boutique')) INTO v_manual
   FROM public.tiendas t WHERE t.id=NEW.tienda_id AND t.empresa_id=NEW.empresa_id;
   SELECT EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.usuario_id=auth.uid() AND u.empresa_id=NEW.empresa_id AND u.activo AND (u.rol='propietario' OR u.rol='socio' OR u.puede_finanzas)) INTO v_admin;
   IF NOT coalesce(v_manual,false) AND NOT v_admin THEN RAISE EXCEPTION 'Esta tienda no puede usar precio manual';END IF;
  END IF;
 ELSIF TG_OP='UPDATE' AND NEW.precio_delivery IS DISTINCT FROM OLD.precio_delivery THEN
  NEW.tarifa_origen:='manual';
 END IF;
 RETURN NEW;
END;$function$;

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
declare v_inv public.motorista_invitaciones%rowtype;v_moto public.motoristas%rowtype;v_email text;
begin
if auth.uid() is null or p_token !~ '^[a-f0-9]{48}$' then raise exception 'Invitación inválida';end if;
select * into v_inv from public.motorista_invitaciones where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
if not found then raise exception 'Invitación inválida';end if;
select * into v_moto from public.motoristas where id=v_inv.motorista_id and usuario_id=auth.uid() and activo;
if found then return v_moto.id;end if;
if v_inv.vence_en<now() or v_inv.usada_por is not null then raise exception 'Invitación vencida o utilizada';end if;
select * into v_moto from public.motoristas where id=v_inv.motorista_id and activo and usuario_id is null for update;
if not found then raise exception 'Motorista no disponible';end if;
select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
if v_email is null or v_email is distinct from lower(trim(v_moto.email)) then raise exception 'Correo no verificado o incorrecto';end if;
if exists(select 1 from public.motoristas where usuario_id=auth.uid()) then raise exception 'Cuenta ya vinculada a otro motorista';end if;
if exists(select 1 from public.flota_usuarios f where f.usuario_id=auth.uid() and f.activo and f.empresa_id<>v_moto.empresa_id)
 or exists(select 1 from public.tiendas t where t.usuario_id=auth.uid() and t.activo and t.empresa_id<>v_moto.empresa_id)
 or exists(select 1 from public.tienda_miembros tm join public.tiendas t on t.id=tm.tienda_id where tm.usuario_id=auth.uid() and tm.activo and t.empresa_id<>v_moto.empresa_id)
then raise exception 'Esta cuenta pertenece a otra empresa';end if;
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
declare v_empresa uuid; v_estado text; v_moto uuid;
begin
 if p_nuevo_estado = 'pasa_manana' then
       perform public.motorista_pasar_pedido_manana(p_pedido_id,p_motivo_incidencia,
         (select version_edicion from public.pedidos where id=p_pedido_id));
       return;
     end if;
     if p_nuevo_estado is null or p_nuevo_estado not in ('no_recibio','no_responde','pasa_manana') then
  raise exception 'Usá Entregado o Rechazado desde su botón; aquí solo se registran incidencias';
 end if;
 select empresa_id, estado, motorista_id into v_empresa, v_estado, v_moto from public.pedidos where id = p_pedido_id for update;
 if v_empresa is null or v_moto is distinct from p_motorista_id then raise exception 'Pedido no asignado'; end if;
 if not exists (select 1 from public.motoristas m where m.id = p_motorista_id and m.usuario_id = auth.uid() and m.empresa_id = v_empresa and m.activo)
    and not exists (select 1 from public.flota_usuarios f where f.empresa_id = v_empresa and f.usuario_id = auth.uid() and f.activo and f.rol in ('propietario','socio')) then
  raise exception 'No autorizado';
 end if;
 if v_estado not in ('pendiente','no_recibio','no_responde','pasa_manana') then raise exception 'Pedido cerrado'; end if;
 if p_motivo_incidencia is null or length(trim(p_motivo_incidencia)) < 3 then raise exception 'Motivo obligatorio'; end if;
 update public.pedidos set estado = p_nuevo_estado, medio_cobro = null, motivo_incidencia = trim(p_motivo_incidencia), updated_at = now()
  where id = p_pedido_id;
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
v_cobro=case when p_estado<>'entregado' or v.modalidad_pago='todo_pagado' then 0 when v.modalidad_pago='producto_pagado' then coalesce(v.delivery_cliente,v.precio_delivery) else v.precio_mercaderia+coalesce(v.delivery_cliente,v.precio_delivery) end;
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

CREATE OR REPLACE FUNCTION public.motorista_contacto_jefe()
 RETURNS TABLE(empresa text, telefono text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select e.nombre, coalesce(nullif(trim(f.telefono),''), nullif(trim(e.telefono),''))
 from public.motoristas m
 join public.empresas e on e.id=m.empresa_id
 left join lateral (select x.telefono from public.flota_usuarios x where x.empresa_id=e.id and x.rol='propietario' and x.activo limit 1) f on true
 where m.usuario_id=auth.uid() and m.activo
 limit 1
$function$;

CREATE OR REPLACE FUNCTION public.motorista_corregir_cierre(p_fecha date, p_efectivo integer, p_transferencia integer)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto public.motoristas%rowtype; c public.flota_cierres_motoristas%rowtype; v_estado text;
begin
 select * into v_moto from public.motoristas where usuario_id=auth.uid() and activo limit 1;
 if not found then raise exception 'Motorista no autorizado'; end if;
 if p_efectivo is null or p_transferencia is null or p_efectivo<0 or p_transferencia<0 then raise exception 'Importes inválidos'; end if;
 select * into c from public.flota_cierres_motoristas where motorista_id=v_moto.id and fecha=p_fecha for update;
 if not found then raise exception 'No hay rendición de ese día'; end if;
 if c.confirmed_at is not null or c.estado='confirmada' then raise exception 'La jornada ya fue cerrada y recibida por Central. Solo administración puede ajustar esta rendición'; end if;
 if c.confirmado_por is not null and c.confirmado_por<>auth.uid() then raise exception 'El jefe ya revisó esta rendición: pedile a él que la corrija'; end if;
 v_estado:=case when p_efectivo=c.a_rendir_esperado and p_transferencia=c.transferencia_registrada then 'confirmada' else 'diferencia' end;
 update public.flota_cierres_motoristas
    set efectivo_declarado=p_efectivo, transferencia_declarada=p_transferencia,
        efectivo_recibido=p_efectivo, transferencia_confirmada=p_transferencia,
        diferencia=p_efectivo-a_rendir_esperado, diferencia_transferencia=p_transferencia-transferencia_registrada,
        estado=v_estado, confirmado_por=auth.uid(), confirmed_at=now()
  where id=c.id;
 return v_estado;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_corregir_pedido(p_pedido uuid, p_version integer, p_cambios jsonb, p_deshacer boolean DEFAULT false)
 RETURNS pedidos
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v public.pedidos%rowtype;v_n public.pedidos%rowtype;
v_fecha date;v_hoy date:=(now() at time zone 'America/Asuncion')::date;
v_mov public.movimientos_financieros%rowtype;v_rech jsonb;v_antes jsonb;v_despues jsonb;
v_campo text;v_permitidos text[]:=array['nombre_cliente','telefono_cliente','referencias','observaciones','producto','precio_mercaderia','precio_delivery','modalidad_pago'];
v_precio int;v_envio int;v_modal text;v_ubicacion boolean;
begin
 if auth.uid() is null then raise exception 'Iniciá sesión';end if;
 select * into v from public.pedidos where id=p_pedido for update;
 if not found then raise exception 'Pedido inexistente';end if;
 if not exists(select 1 from public.motoristas m where m.id=v.motorista_id and m.usuario_id=auth.uid() and m.activo) then raise exception 'Este pedido no está asignado a tu cuenta';end if;
 if p_version is distinct from v.version_edicion then raise exception 'El pedido fue modificado. Actualizá antes de guardar';end if;
 select coalesce(r.fecha,(v.created_at at time zone 'America/Asuncion')::date) into v_fecha from (select 1) z left join public.rutas_generales r on r.id=v.ruta_general_id;
 if v_fecha<>v_hoy then raise exception 'Solo se puede corregir un pedido de la jornada actual';end if;
 if exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=v.motorista_id and c.fecha=v_fecha) then raise exception 'Jornada cerrada o presentada. Solicitá corrección administrativa';end if;
 if p_cambios is null or jsonb_typeof(p_cambios)<>'object' then raise exception 'Datos incorrectos';end if;
 for v_campo in select jsonb_object_keys(p_cambios) loop
  if not(v_campo=any(v_permitidos)) then raise exception 'Campo no autorizado: %',v_campo;end if;
 end loop;
 if p_cambios='{}'::jsonb and not p_deshacer then raise exception 'No hay cambios';end if;
 if p_deshacer then
   if v.estado not in ('entregado','rechazado') then raise exception 'Solo se puede deshacer entregado o rechazado';end if;
 else
   if v.estado not in ('pendiente','no_responde','no_recibio','pasa_manana') then
     raise exception 'Primero deshacé el estado para poder editar este pedido';
   end if;
 end if;
 select * into v_mov from public.movimientos_financieros where pedido_id=v.id for update;
 if found then
  if not p_deshacer then raise exception 'El pedido tiene un cobro; primero deshacé el estado';end if;
  if v_mov.liquidado then raise exception 'Cobro liquidado; requiere ajuste administrativo';end if;
  select to_jsonb(d) into v_rech from public.flota_rechazos_detalle d where d.pedido_id=v.id;
 elsif p_deshacer then raise exception 'El pedido no tiene movimiento financiero registrado; solicitá revisión de Central';end if;
 v_antes=to_jsonb(v);
 v_despues=v_antes||p_cambios;
 select * into v_n from jsonb_populate_record(null::public.pedidos,v_despues);
 if v_n.precio_mercaderia is null or v_n.precio_mercaderia<0 or v_n.precio_mercaderia>100000000 then raise exception 'Precio de mercadería inválido';end if;
 if v_n.precio_delivery is null or v_n.precio_delivery<0 or v_n.precio_delivery>10000000 then raise exception 'Costo de envío inválido';end if;
 if v_n.modalidad_pago not in ('pendiente','producto_pagado','todo_pagado') then raise exception 'Modalidad de pago inválida';end if;
 if length(coalesce(v_n.nombre_cliente,''))>200 or length(coalesce(v_n.producto,''))>160 or length(coalesce(v_n.telefono_cliente,''))>40
 or length(coalesce(v_n.observaciones,''))>2000 or length(coalesce(v_n.referencias,''))>2000 then raise exception 'Texto demasiado largo';end if;
 -- La auditoría guarda importes anteriores y una copia de los movimientos retirados.
 if p_deshacer then
   delete from public.flota_rechazos_detalle where pedido_id=v.id;
   delete from public.movimientos_financieros where pedido_id=v.id and liquidado=false;
 end if;
 update public.pedidos p set
 nombre_cliente=v_n.nombre_cliente,telefono_cliente=v_n.telefono_cliente,producto=v_n.producto,
 referencias=v_n.referencias,observaciones=v_n.observaciones,
 precio_mercaderia=v_n.precio_mercaderia,precio_delivery=v_n.precio_delivery,modalidad_pago=v_n.modalidad_pago,
 estado=case when p_deshacer then 'pendiente' else v.estado end,
 medio_cobro=case when p_deshacer then null else v.medio_cobro end,
 motivo_incidencia=case when p_deshacer then null else v.motivo_incidencia end,
 version_edicion=coalesce(v.version_edicion,0)+1,updated_at=now()
 where p.id=v.id returning * into v_n;
 insert into public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 values(v.id,v.empresa_id,v.tienda_id,auth.uid(),coalesce(v.version_edicion,0),v_n.version_edicion,
  jsonb_build_object('accion',case when p_deshacer then 'motorista_deshacer_estado' else 'motorista_editar_pedido' end,
   'estado_anterior',v.estado,'estado_nuevo',v_n.estado,'movimiento_anterior',case when p_deshacer then to_jsonb(v_mov) else null end,
   'detalle_rechazo_anterior',v_rech,
   'campos',(select coalesce(jsonb_object_agg(k,jsonb_build_object('antes',v_antes->k,'despues',to_jsonb(v_n)->k)),'{}'::jsonb) from jsonb_object_keys(p_cambios) k)
  ));
 return v_n;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_deshacer_no_me_fui(p_pedido uuid, p_version integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_p public.pedidos%rowtype;
 v_fecha date;
 v_previo text;
BEGIN
 IF p_pedido IS NULL OR p_version IS NULL OR p_version<0
 THEN RAISE EXCEPTION 'Pedido o versión inválidos';END IF;
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.motoristas m
  WHERE m.id=v_p.motorista_id AND m.empresa_id=v_p.empresa_id
  AND m.usuario_id=auth.uid() AND m.activo)
 THEN RAISE EXCEPTION 'Solo el motorista asignado puede deshacer su No me fui';END IF;
 IF v_p.version_edicion IS DISTINCT FROM p_version THEN
  RAISE EXCEPTION 'El pedido cambió. Actualizá la pantalla antes de deshacer';END IF;
 IF v_p.estado<>'pendiente' OR coalesce(v_p.motivo_incidencia,'') NOT ILIKE 'No me fui:%'
 THEN RAISE EXCEPTION 'El pedido ya no está en No me fui';END IF;
 SELECT fecha INTO v_fecha FROM public.rutas_generales
 WHERE id=v_p.ruta_general_id AND empresa_id=v_p.empresa_id AND estado<>'cerrada';
 IF v_fecha IS DISTINCT FROM (now() AT TIME ZONE 'America/Asuncion')::date
 THEN RAISE EXCEPTION 'Solo se puede deshacer No me fui de la ruta activa de hoy';END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c
  WHERE c.empresa_id=v_p.empresa_id AND c.motorista_id=v_p.motorista_id AND c.fecha=v_fecha)
 THEN RAISE EXCEPTION 'La caja ya se cerró: solicitá corrección a Central';END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_p.id)
 OR EXISTS(SELECT 1 FROM public.flota_rechazos_detalle r WHERE r.pedido_id=v_p.id)
 THEN RAISE EXCEPTION 'El pedido tiene registros financieros y debe revisarlo Central';END IF;
 v_previo=v_p.motivo_incidencia;
 UPDATE public.pedidos
 SET motivo_incidencia=NULL,medio_cobro=NULL,version_edicion=p_version+1,updated_at=now()
 WHERE id=p_pedido;
 INSERT INTO public.pedidos_ediciones(
  pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios
 )VALUES(v_p.id,v_p.empresa_id,v_p.tienda_id,auth.uid(),p_version,p_version+1,
  pg_catalog.jsonb_build_object('accion','deshacer_no_me_fui',
   'estado','pendiente','motivo_anterior',v_previo,'motivo_nuevo',NULL,
   'motorista_id',v_p.motorista_id,'fecha_ruta',v_fecha,
   'movimiento_financiero',false));
 RETURN pg_catalog.jsonb_build_object('pedido_id',v_p.id,'estado','pendiente',
  'no_me_fui',false,'version',p_version+1);
END;$function$;

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

CREATE OR REPLACE FUNCTION public.motorista_guardar_recorrido(p_pedidos uuid[], p_coordenadas jsonb, p_origen_lat double precision, p_origen_lng double precision)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto uuid;v_empresa uuid;v_fecha date;v_total int;v_geocodificados int;v_version bigint;v_punto jsonb;v_cantidad int;
begin
 select m.id,m.empresa_id into v_moto,v_empresa from public.motoristas m where m.usuario_id=(select auth.uid()) and m.activo order by m.created_at limit 1;
 if v_moto is null then raise exception 'Motorista no autorizado';end if;
 v_fecha=(now() at time zone 'America/Asuncion')::date;
 v_total=coalesce(array_length(p_pedidos,1),0);
 if v_total<2 or v_total>26 or (select count(distinct x.id) from unnest(p_pedidos) as x(id))<>v_total then raise exception 'Orden incompleto o duplicado';end if;
 if p_origen_lat is null or p_origen_lng is null or not(p_origen_lat between -29 and -18 and p_origen_lng between -64 and -53) then raise exception 'Origen GPS inválido';end if;
 if p_coordenadas is null or jsonb_typeof(p_coordenadas)<>'array' or pg_catalog.octet_length(p_coordenadas::text)>1800000 then raise exception 'Geometría vial ausente, inválida o demasiado extensa';end if;
 v_cantidad=jsonb_array_length(p_coordenadas);
 if v_cantidad<2 or v_cantidad>50000 then raise exception 'Geometría vial incompleta';end if;
 if exists(select 1 from jsonb_array_elements(p_coordenadas) as t(j) where jsonb_typeof(t.j)<>'array' or jsonb_array_length(t.j)<>2 or jsonb_typeof(t.j->0)<>'number' or jsonb_typeof(t.j->1)<>'number') then
  raise exception 'Las coordenadas de la geometría no son válidas';
 end if;
 if exists(select 1 from jsonb_array_elements(p_coordenadas) as t(j) where (t.j->>0)::double precision not between -64 and -53 or (t.j->>1)::double precision not between -29 and -18) then
  raise exception 'La geometría contiene puntos fuera del área permitida';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_moto::text),pg_catalog.hashtext(v_fecha::text));
 perform 1 from public.pedidos p where p.id=any(p_pedidos) order by p.id for update;
 select count(*) into v_geocodificados from public.pedidos p
  join public.rutas_generales r on r.id=p.ruta_general_id
  where p.motorista_id=v_moto and p.empresa_id=v_empresa and r.fecha=v_fecha
  and p.estado in('pendiente','no_responde','pasa_manana','no_recibio')
  and p.lat is not null and p.lng is not null;
 if v_geocodificados<>v_total then raise exception 'Hay pedidos nuevos, faltantes o estados diferentes. Actualizá tu ruta';end if;
 if (select count(*) from public.pedidos p join public.rutas_generales r on r.id=p.ruta_general_id where p.id=any(p_pedidos)
 and p.motorista_id=v_moto and p.empresa_id=v_empresa and r.fecha=v_fecha
 and p.estado in('pendiente','no_responde','pasa_manana','no_recibio') and p.lat is not null and p.lng is not null)<>v_total then
  raise exception 'Tu selección contiene pedidos que ya no están disponibles';
 end if;
 -- La transacción completa asegura que orden y geometría sean siempre la misma versión.
 delete from public.motorista_ordenes_pedidos where motorista_id=v_moto and fecha=v_fecha;
 insert into public.motorista_ordenes_pedidos(motorista_id,fecha,pedido_id,posicion)
  select v_moto,v_fecha,x.id,x.posicion::integer from unnest(p_pedidos) with ordinality as x(id,posicion);
 insert into public.motorista_recorridos_confirmados(motorista_id,empresa_id,fecha,version,pedido_ids,coordenadas,origen_lat,origen_lng,confirmado_en)
 values(v_moto,v_empresa,v_fecha,1,p_pedidos,p_coordenadas,p_origen_lat,p_origen_lng,now())
 on conflict(motorista_id,fecha) do update set
   version=public.motorista_recorridos_confirmados.version+1,
   pedido_ids=excluded.pedido_ids,coordenadas=excluded.coordenadas,
   origen_lat=excluded.origen_lat,origen_lng=excluded.origen_lng,confirmado_en=now()
 returning version into v_version;
 return v_version;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_marcar_no_me_fui(p_pedido uuid, p_version integer, p_motivo text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_p public.pedidos%rowtype;
 v_fecha date;
 v_motivo text;
BEGIN
 v_motivo=btrim(coalesce(p_motivo,''));
 IF char_length(v_motivo)<3 OR char_length(v_motivo)>180 THEN RAISE EXCEPTION 'Indicá un motivo de 3 a 180 caracteres'; END IF;
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
 IF NOT EXISTS(
  SELECT 1 FROM public.motoristas m WHERE m.id=v_p.motorista_id AND m.empresa_id=v_p.empresa_id AND m.activo AND m.usuario_id=auth.uid()
 ) AND NOT EXISTS(
  SELECT 1 FROM public.flota_usuarios u WHERE u.empresa_id=v_p.empresa_id AND u.activo AND u.usuario_id=auth.uid() AND u.rol IN ('propietario','socio')
 ) THEN RAISE EXCEPTION 'No estás autorizado para este pedido'; END IF;
 IF v_p.estado<>'pendiente' THEN RAISE EXCEPTION 'El pedido ya tiene otro estado. No se modificó'; END IF;
 IF coalesce(v_p.version_edicion,0) IS DISTINCT FROM p_version THEN RAISE EXCEPTION 'El pedido cambió: actualizá la pantalla';END IF;
 SELECT r.fecha INTO v_fecha FROM public.rutas_generales r
 WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_p.empresa_id AND r.estado<>'cerrada';
 IF v_fecha IS NULL OR v_fecha<>(now() AT TIME ZONE 'America/Asuncion')::date THEN
  RAISE EXCEPTION 'Solo se permite marcar No me fui en la jornada abierta de hoy';
 END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c WHERE c.empresa_id=v_p.empresa_id AND c.motorista_id=v_p.motorista_id AND c.fecha=v_fecha)
 THEN RAISE EXCEPTION 'La caja ya fue presentada o cerrada'; END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_p.id)
 THEN RAISE EXCEPTION 'El pedido tiene un movimiento financiero y requiere revisión en Central'; END IF;
 IF coalesce(v_p.motivo_incidencia,'') LIKE 'No me fui:%' THEN
  RAISE EXCEPTION 'Este pedido ya está marcado No me fui';
 END IF;
 UPDATE public.pedidos SET motivo_incidencia='No me fui: '||v_motivo,
  medio_cobro=NULL,version_edicion=p_version+1,updated_at=now()
 WHERE id=p_pedido;
 INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 VALUES(v_p.id,v_p.empresa_id,v_p.tienda_id,auth.uid(),p_version,p_version+1,
 jsonb_build_object('accion','no_me_fui_sin_cobro','motivo',v_motivo,
 'estado','pendiente','importe_cobrado',0,'comision_motorista',0,'comision_empresa',0,
 'fecha_ruta',v_fecha,'motorista_id',v_p.motorista_id));
 RETURN jsonb_build_object('pedido_id',p_pedido,'estado','pendiente','no_me_fui',true,'movimiento_financiero',false,'version',p_version+1);
END;
$function$;

CREATE OR REPLACE FUNCTION public.motorista_mis_ganancias_por_fecha(p_fecha date)
 RETURNS TABLE(pedido_id uuid, estado text, ganancia_prevista integer, ganancia_confirmada integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 SELECT p.id,p.estado,
 CASE WHEN p.estado IN ('pendiente','no_responde','no_recibio','pasa_manana')
       AND NOT (p.estado='pendiente' AND coalesce(p.motivo_incidencia,'') ILIKE 'No me fui:%')
       AND p.precio_delivery>=0 AND p.porcentaje_empresa_pct BETWEEN 0 AND 100
 THEN greatest(0,p.precio_delivery-round((p.precio_delivery::numeric*p.porcentaje_empresa_pct)/100)::integer)
 ELSE CASE WHEN p.estado='pendiente' AND coalesce(p.motivo_incidencia,'') ILIKE 'No me fui:%' OR p.estado='cancelado' THEN 0 ELSE null END END AS ganancia_prevista,
 CASE WHEN p.estado IN ('entregado','rechazado') THEN mf.comision_motorista
      WHEN p.estado='cancelado' OR (p.estado='pendiente' AND coalesce(p.motivo_incidencia,'') ILIKE 'No me fui:%') THEN 0
      ELSE null END AS ganancia_confirmada
 FROM public.pedidos p
 JOIN public.motoristas m ON m.id=p.motorista_id AND m.usuario_id=auth.uid() AND m.activo AND m.empresa_id=p.empresa_id
 JOIN public.rutas_generales r ON r.id=p.ruta_general_id AND r.fecha=p_fecha AND r.empresa_id=p.empresa_id
 LEFT JOIN public.movimientos_financieros mf ON mf.pedido_id=p.id AND mf.motorista_id=m.id
 WHERE p_fecha IS NOT NULL AND p_fecha BETWEEN (now() AT TIME ZONE 'America/Asuncion')::date-365 AND (now() AT TIME ZONE 'America/Asuncion')::date+30
$function$;

CREATE OR REPLACE FUNCTION public.motorista_mis_tiendas()
 RETURNS TABLE(id uuid, codigo text, nombre_comercial text, telefono text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select distinct t.id, t.codigo, t.nombre_comercial, t.telefono
 from public.motoristas m
 join public.pedidos p on p.motorista_id=m.id
 join public.tiendas t on t.id=p.tienda_id
 where m.usuario_id=auth.uid() and m.activo
$function$;

CREATE OR REPLACE FUNCTION public.motorista_pasar_pedido_manana(p_pedido_id uuid, p_motivo text, p_version integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
 v_p public.pedidos%rowtype;
 v_r public.rutas_generales%rowtype;
 v_hoy date := (now() AT TIME ZONE 'America/Asuncion')::date;
 v_manana date := (now() AT TIME ZONE 'America/Asuncion')::date + 1;
 v_ruta_nueva uuid;
 v_numero integer;
 v_usuario uuid := auth.uid();
 v_motivo text := btrim(coalesce(p_motivo,''));
BEGIN
 IF v_usuario IS NULL THEN RAISE EXCEPTION 'Sesión no autorizada'; END IF;
 IF p_pedido_id IS NULL OR p_version IS NULL OR p_version<0
 THEN RAISE EXCEPTION 'Faltan datos o versión del pedido'; END IF;
 IF length(v_motivo)<3 OR length(v_motivo)>300 THEN
   RAISE EXCEPTION 'Seleccioná un motivo de 3 a 300 caracteres'; END IF;
 -- Serializar las reprogramaciones del día sin bloquear otras empresas.
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente';END IF;
 PERFORM pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtext(v_p.empresa_id::text),
  pg_catalog.hashtext(v_manana::text||'manana')
 );
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido_id FOR UPDATE;
 IF NOT EXISTS(SELECT 1 FROM public.motoristas m
  WHERE m.id=v_p.motorista_id AND m.usuario_id=v_usuario
  AND m.empresa_id=v_p.empresa_id AND m.activo)
 THEN RAISE EXCEPTION 'Este pedido ya no está asignado a tu usuario';END IF;
 IF v_p.version_edicion IS DISTINCT FROM p_version THEN
  RAISE EXCEPTION 'El pedido cambió. Actualizá la ruta y volvé a verificarlo';END IF;
 IF v_p.estado NOT IN ('pendiente','no_responde','no_recibio','pasa_manana') THEN
  RAISE EXCEPTION 'Pedido ya finalizado; no se puede reprogramar';END IF;
 IF v_p.ruta_general_id IS NULL THEN
  RAISE EXCEPTION 'El pedido no tiene una ruta original válida';END IF;
 SELECT * INTO v_r FROM public.rutas_generales
  WHERE id=v_p.ruta_general_id AND empresa_id=v_p.empresa_id FOR UPDATE;
 IF NOT FOUND OR v_r.fecha IS DISTINCT FROM v_hoy OR v_r.estado='cerrada' THEN
  RAISE EXCEPTION 'Solo se permite pasar a mañana pedidos de una ruta activa de hoy';END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c
  WHERE c.empresa_id=v_p.empresa_id AND c.motorista_id=v_p.motorista_id AND c.fecha=v_hoy)
 THEN RAISE EXCEPTION 'La caja de hoy ya fue cerrada; no se puede mover el pedido';END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros f WHERE f.pedido_id=v_p.id)
  OR EXISTS(SELECT 1 FROM public.flota_rechazos_detalle r WHERE r.pedido_id=v_p.id)
 THEN RAISE EXCEPTION 'Este pedido tiene movimientos financieros y no se puede reprogramar';END IF;
 -- Una sola ruta general para mañana y turno mañana, reutilizando la existente.
 SELECT id INTO v_ruta_nueva FROM public.rutas_generales
 WHERE empresa_id=v_p.empresa_id AND fecha=v_manana AND turno='manana'
 AND estado IN ('abierta','optimizada','en_reparto')
 ORDER BY created_at,id LIMIT 1 FOR UPDATE;
 IF v_ruta_nueva IS NULL THEN
  INSERT INTO public.rutas_generales(empresa_id,fecha,turno,estado,version_optimizacion)
  VALUES(v_p.empresa_id,v_manana,'manana','abierta',0)
  RETURNING id INTO v_ruta_nueva;
 END IF;
 SELECT coalesce(max(numero_general),0)+1 INTO v_numero
 FROM public.pedidos WHERE ruta_general_id=v_ruta_nueva;
 DELETE FROM public.motorista_ordenes_pedidos WHERE pedido_id=v_p.id;
 UPDATE public.pedidos
 SET ruta_general_id=v_ruta_nueva,
  numero_general=v_numero,
  motorista_id=NULL,
  turno='manana',
  estado='pendiente',
  medio_cobro=NULL,
  motivo_incidencia='Reprogramado desde '||to_char(v_hoy,'DD/MM/YYYY')||' · '||v_motivo,
  requiere_revisar_ruta=true,
  version_edicion=p_version+1,
  updated_at=now()
 WHERE id=v_p.id;
 INSERT INTO public.pedidos_ediciones(
  pedido_id,empresa_id,tienda_id,usuario_id,
  version_anterior,version_nueva,cambios
 ) VALUES (
  v_p.id,v_p.empresa_id,v_p.tienda_id,v_usuario,p_version,p_version+1,
  pg_catalog.jsonb_build_object(
   'accion','pasar_manana_automatico',
   'motorista_anterior',v_p.motorista_id,
   'fecha_anterior',v_hoy,
   'fecha_nueva',v_manana,
   'ruta_anterior',v_p.ruta_general_id,
   'ruta_nueva',v_ruta_nueva,
   'turno_anterior',v_p.turno,
   'turno_nuevo','manana',
   'numero_anterior',v_p.numero_general,
   'numero_nuevo',v_numero,
   'estado_anterior',v_p.estado,
   'estado_nuevo','pendiente',
   'motivo_anterior',v_p.motivo_incidencia,
   'motivo_reprogramacion',v_motivo
  )
 );
 RETURN pg_catalog.jsonb_build_object(
  'pedido_id',v_p.id,'fecha_origen',v_hoy,'fecha_destino',v_manana,
  'ruta_destino',v_ruta_nueva,'numero_nuevo',v_numero,
  'motorista_id',NULL,'estado','pendiente','reprogramado',true
 );
END
$function$;

CREATE OR REPLACE FUNCTION public.motorista_presentar_cierre(p_fecha date, p_efectivo integer, p_transferencia integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_moto public.motoristas%rowtype;v_cash integer;v_transfer integer;v_comm integer;v_emp integer;v_del_comm integer;v_render integer;v_id uuid;
begin
select * into v_moto from public.motoristas where usuario_id=auth.uid() and activo limit 1 for update;
if not found then raise exception 'Motorista no autorizado';end if;
if p_fecha is null or p_fecha> (now() at time zone 'America/Asuncion')::date or p_efectivo is null or p_transferencia is null or p_efectivo<0 or p_transferencia<0 then raise exception 'Importes o fecha inválidos';end if;
perform pg_advisory_xact_lock(hashtext(v_moto.id::text||p_fecha::text));
if exists(select 1 from public.flota_cierres_motoristas where motorista_id=v_moto.id and fecha=p_fecha) then raise exception 'Ya existe cierre del día';end if;
-- Protección: no aceptar caja con pedidos aún abiertos de este motorista y jornada.
if exists (
 select 1 from public.pedidos p
 left join public.rutas_generales r on r.id=p.ruta_general_id
 where p.motorista_id=v_moto.id
   and coalesce(r.fecha,(p.created_at at time zone 'America/Asuncion')::date)=p_fecha
   and p.estado not in ('entregado','rechazado','cancelado')
) then
 raise exception 'Tenés pedidos sin finalizar. Entregalos, rechazalos o pedí a Central que reprograme los pendientes antes de cerrar la caja.';
end if;
select coalesce(sum(m.efectivo_cobrado),0),coalesce(sum(m.transferencia_cobrada),0),coalesce(sum(m.comision_motorista),0),coalesce(sum(m.comision_empresa),0),coalesce(sum(case when p.estado='entregado' then m.comision_motorista else 0 end))
into v_cash,v_transfer,v_comm,v_emp,v_del_comm
from public.movimientos_financieros m join public.pedidos p on p.id=m.pedido_id
where m.motorista_id=v_moto.id and (m.created_at at time zone 'America/Asuncion')::date=p_fecha;
if v_moto.modalidad_liquidacion='retener_comision' then v_render=greatest(0,v_cash-least(v_cash,v_comm));else v_render=v_cash;end if;
insert into public.flota_cierres_motoristas(empresa_id,motorista_id,fecha,efectivo_esperado,transferencia_registrada,comision_motorista,comision_empresa,a_rendir_esperado,efectivo_declarado,transferencia_declarada,presentado_por,
  efectivo_recibido,transferencia_confirmada,diferencia,diferencia_transferencia,estado,confirmado_por,confirmed_at)
values(v_moto.empresa_id,v_moto.id,p_fecha,v_cash,v_transfer,v_comm,v_emp,v_render,p_efectivo,p_transferencia,auth.uid(),
  p_efectivo,p_transferencia,p_efectivo-v_render,p_transferencia-v_transfer,
  case when p_efectivo=v_render and p_transferencia=v_transfer then 'confirmada' else 'diferencia' end,auth.uid(),now())
returning id into v_id;
return v_id;
end $function$;

CREATE OR REPLACE FUNCTION public.motorista_recorrido_actual()
 RETURNS TABLE(fecha date, version bigint, pedido_ids uuid[], coordenadas jsonb, origen_lat double precision, origen_lng double precision, confirmado_en timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select c.fecha,c.version,c.pedido_ids,c.coordenadas,c.origen_lat,c.origen_lng,c.confirmado_en
 from public.motorista_recorridos_confirmados c
 join public.motoristas m on m.id=c.motorista_id
 where m.usuario_id=(select auth.uid()) and m.activo and c.fecha=(now() at time zone 'America/Asuncion')::date;
$function$;

CREATE OR REPLACE FUNCTION public.motorista_registrar_entrega_anterior(p_pedido uuid, p_fecha date, p_medio text, p_version integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_p public.pedidos%rowtype;v_fecha date;v_ahora timestamptz;v_registro timestamptz;v_mov uuid;
BEGIN
 v_ahora=now();
 v_fecha=(v_ahora AT TIME ZONE 'America/Asuncion')::date;
 SELECT * INTO v_p FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.motoristas m WHERE m.id=v_p.motorista_id AND m.usuario_id=auth.uid() AND m.activo)
 AND NOT EXISTS(SELECT 1 FROM public.flota_usuarios u WHERE u.empresa_id=v_p.empresa_id AND u.usuario_id=auth.uid() AND u.activo AND u.rol IN ('propietario','socio'))
 THEN RAISE EXCEPTION 'Sin autorización para esta entrega'; END IF;
 IF v_p.estado<>'pendiente' THEN RAISE EXCEPTION 'Solo se puede confirmar un pedido pendiente'; END IF;
 IF coalesce(v_p.version_edicion,0)<>p_version THEN RAISE EXCEPTION 'Pedido modificado: actualizá tu pantalla';END IF;
 IF p_fecha>=v_fecha OR p_fecha<v_fecha-7 THEN RAISE EXCEPTION 'La fecha debe ser anterior y dentro de los últimos 7 días'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.rutas_generales r WHERE r.id=v_p.ruta_general_id AND r.empresa_id=v_p.empresa_id AND r.fecha=p_fecha AND r.estado<>'cerrada')
 THEN RAISE EXCEPTION 'El pedido ya no pertenece a esa ruta o la ruta está cerrada'; END IF;
 IF EXISTS(SELECT 1 FROM public.flota_cierres_motoristas c WHERE c.empresa_id=v_p.empresa_id AND c.motorista_id=v_p.motorista_id AND c.fecha=p_fecha)
 THEN RAISE EXCEPTION 'Caja histórica cerrada: requiere ajuste autorizado por Central'; END IF;
 IF EXISTS(SELECT 1 FROM public.movimientos_financieros mf WHERE mf.pedido_id=p_pedido)
 THEN RAISE EXCEPTION 'Ya existe movimiento financiero para el pedido'; END IF;
 IF p_medio NOT IN ('efectivo','transferencia','pagado_previo') THEN RAISE EXCEPTION 'Medio de cobro inválido'; END IF;
 IF (v_p.modalidad_pago='todo_pagado' AND p_medio<>'pagado_previo')
 OR (v_p.modalidad_pago<>'todo_pagado' AND p_medio='pagado_previo')
 THEN RAISE EXCEPTION 'Medio incompatible con modalidad de pago'; END IF;
 -- El movimiento se registra con fecha contable anterior y hora original en columna separada.
 PERFORM public.motorista_cerrar_entrega(p_pedido,p_medio,'entregado',NULL);
 v_registro=(p_fecha::timestamp + time '12:00') AT TIME ZONE 'America/Asuncion';
 UPDATE public.movimientos_financieros SET created_at=v_registro,registrado_real_en=v_ahora
 WHERE pedido_id=p_pedido AND motorista_id=v_p.motorista_id AND liquidado=false RETURNING id INTO v_mov;
 IF v_mov IS NULL THEN RAISE EXCEPTION 'No se registró el cobro íntegro'; END IF;
 UPDATE public.pedidos SET version_edicion=p_version+1,updated_at=v_ahora WHERE id=p_pedido;
 INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
 VALUES(p_pedido,v_p.empresa_id,v_p.tienda_id,auth.uid(),p_version,p_version+1,
 jsonb_build_object('accion','entrega_historica_confirmada','fecha_operativa',p_fecha,
 'fecha_registro_real',v_ahora,'medio_cobro',p_medio,'movimiento_id',v_mov,
 'estado_anterior',v_p.estado,'estado_nuevo','entregado'));
 RETURN jsonb_build_object('pedido_id',p_pedido,'fecha_operativa',p_fecha,'movimiento_id',v_mov);
END
$function$;

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
if p_importe is null or p_importe<0 or p_importe>coalesce(v.delivery_cliente,v.precio_delivery) then raise exception 'Importe no válido para costo de envío';end if;
if (p_importe>0 and (p_medio not in('efectivo','transferencia') or p_responsable='pendiente')) or (p_importe=0 and p_medio is not null) then raise exception 'Indicá quién pagó, importe y medio de cobro coherentes';end if;
if exists(select 1 from public.flota_cierres_motoristas c where c.motorista_id=v.motorista_id and c.fecha=(now() at time zone 'America/Asuncion')::date) then raise exception 'Caja presentada; solicitar ajuste administrativo';end if;
perform public.motorista_cerrar_entrega(p_pedido,null,'rechazado',p_motivo);
select * into v_mov from public.movimientos_financieros where pedido_id=v.id for update;
if not found then raise exception 'No se registró movimiento de rechazo';end if;
if exists(select 1 from public.flota_rechazos_detalle where pedido_id=v.id) then raise exception 'Rechazo ya registrado';end if;
update public.movimientos_financieros set efectivo_cobrado=case when p_medio='efectivo' then p_importe else 0 end,transferencia_cobrada=case when p_medio='transferencia' then p_importe else 0 end where id=v_mov.id;
insert into public.flota_rechazos_detalle(pedido_id,empresa_id,tienda_id,motorista_id,responsable_pago,importe_cobrado,medio_cobro,importe_pendiente,comision_motorista,comision_empresa,motivo,registrado_por)
values(v.id,v.empresa_id,v.tienda_id,v.motorista_id,case when v.regla_comercial='boom_25k_cliente_20k_v1' and p_importe<v.precio_delivery then 'tienda' else p_responsable end,p_importe,p_medio,v.precio_delivery-p_importe,v_mov.comision_motorista,v_mov.comision_empresa,trim(p_motivo),auth.uid());
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
v_cobro=case when new.estado<>'entregado' or new.modalidad_pago='todo_pagado' then 0 when new.modalidad_pago='producto_pagado' then coalesce(new.delivery_cliente,new.precio_delivery) else new.precio_mercaderia+coalesce(new.delivery_cliente,new.precio_delivery) end;
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
declare v public.pedidos%rowtype; r uuid; day date := (now() at time zone 'America/Asuncion')::date;
begin
 if p_turno is null or p_turno not in ('manana','tarde') then raise exception 'Seleccioná Mañana o Tarde'; end if;
 if auth.uid() is null then raise exception 'Iniciá sesión'; end if;
 select * into v from public.pedidos where id = p_pedido for update;
 if not found then raise exception 'Pedido inexistente'; end if;
 if not exists (select 1 from public.tienda_miembros m join public.tiendas t on t.id = m.tienda_id
                where m.tienda_id = v.tienda_id and m.usuario_id = auth.uid() and m.activo and t.activo and t.empresa_id = v.empresa_id) then
  raise exception 'No autorizado';
 end if;
 if v.estado <> 'pendiente' or v.motorista_id is not null then raise exception 'Pedido ya asignado o procesado'; end if;
 if v.lat is null or v.lng is null or v.lat not between -28 and -19 or v.lng not between -63 and -54 then raise exception 'GPS inválido'; end if;
 if exists (select 1 from public.movimientos_financieros m where m.pedido_id = v.id) then raise exception 'Pedido con cobros: no puede cambiarse'; end if;
 if v.ruta_general_id is not null then
  select id into r from public.rutas_generales where id = v.ruta_general_id and empresa_id = v.empresa_id and estado = 'abierta' and turno = p_turno;
  if r is not null and v.turno = p_turno then return r; end if;
  if exists (select 1 from public.rutas_generales where id = v.ruta_general_id and estado <> 'abierta') then
   raise exception 'Ruta confirmada: solicitá reorganización a Central';
  end if;
 elsif v.requiere_revisar_ruta and v.turno = p_turno then
  return null;
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v.empresa_id::text), pg_catalog.hashtext(day::text || p_turno));
 select id into r from public.rutas_generales
  where empresa_id = v.empresa_id and fecha = day and turno = p_turno and estado in ('abierta','optimizada','en_reparto')
  order by created_at limit 1;
 if r is not null and exists (select 1 from public.rutas_generales where id = r and estado <> 'abierta') then
  update public.pedidos set ruta_general_id = null, turno = p_turno, numero_general = null, requiere_revisar_ruta = true,
         version_edicion = coalesce(version_edicion, 0) + 1, updated_at = now()
   where id = v.id;
  return null;
 end if;
 if r is null then
  insert into public.rutas_generales(empresa_id, fecha, turno, estado, version_optimizacion)
  values (v.empresa_id, day, p_turno, 'abierta', 0) returning id into r;
 end if;
 update public.pedidos set ruta_general_id = r, turno = p_turno, numero_general = null, requiere_revisar_ruta = false,
        version_edicion = coalesce(version_edicion, 0) + 1, updated_at = now()
  where id = v.id;
 return r;
end $function$;

CREATE OR REPLACE FUNCTION public.tienda_cancelar_pedido_seguro(p_pedido_id uuid, p_version integer)
 RETURNS pedidos
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  o public.pedidos%ROWTYPE;
  v public.pedidos%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Iniciá sesión para cancelar'; END IF;
  SELECT * INTO o FROM public.pedidos WHERE id=p_pedido_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.tienda_miembros m
    WHERE m.tienda_id=o.tienda_id AND m.usuario_id=auth.uid() AND m.activo
  ) THEN
    RAISE EXCEPTION 'No tenés permiso sobre este pedido';
  END IF;
  IF p_version IS DISTINCT FROM o.version_edicion THEN
    RAISE EXCEPTION 'Este pedido cambió. Actualizá la lista y volvé a intentar';
  END IF;
  IF o.estado <> 'pendiente' THEN RAISE EXCEPTION 'Solo se pueden cancelar pedidos pendientes'; END IF;
  IF o.motorista_id IS NOT NULL OR o.ruta_general_id IS NOT NULL OR o.numero_general IS NOT NULL THEN
    RAISE EXCEPTION 'El pedido ya está en una ruta o asignado. Pedí a la Central que lo gestione';
  END IF;
  IF EXISTS (SELECT 1 FROM public.movimientos_financieros mf WHERE mf.pedido_id=o.id) THEN
    RAISE EXCEPTION 'El pedido tiene movimientos financieros y no se puede cancelar';
  END IF;
  UPDATE public.pedidos SET estado='cancelado',version_edicion=o.version_edicion+1,updated_at=now()
  WHERE id=o.id RETURNING * INTO v;
  INSERT INTO public.pedidos_ediciones(pedido_id,empresa_id,tienda_id,usuario_id,version_anterior,version_nueva,cambios)
  VALUES(o.id,o.empresa_id,o.tienda_id,auth.uid(),o.version_edicion,v.version_edicion,
    jsonb_build_object('estado',jsonb_build_object('antes',o.estado,'despues','cancelado')));
  RETURN v;
END;
$function$;

-- views

CREATE OR REPLACE VIEW public.vista_auditoria_incidencias AS  SELECT p.id AS pedido_id,
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

CREATE OR REPLACE VIEW public.vista_cierre_financiero_admin AS  SELECT e.id AS empresa_id,
    COALESCE(sum(mf.monto_delivery), 0::bigint) AS total_delivery_facturado,
    COALESCE(sum(mf.comision_empresa), 0::bigint) AS total_ingreso_empresa,
    COALESCE(sum(mf.comision_motorista), 0::bigint) AS total_ganancia_motoristas,
    COALESCE(sum(mf.monto_mercaderia), 0::bigint) AS total_mercaderia_movilizada,
    count(mf.id) AS total_envios_liquidados
   FROM empresas e
     LEFT JOIN movimientos_financieros mf ON e.id = mf.empresa_id
  GROUP BY e.id;;

CREATE OR REPLACE VIEW public.vista_pedidos_admin AS  SELECT p.id AS pedido_id,
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

CREATE OR REPLACE VIEW public.vista_pedidos_motorista AS  SELECT p.id AS pedido_id,
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

-- triggers

CREATE TRIGGER flota_fijar_colaboradores_sin_comision_v1 BEFORE INSERT OR UPDATE OF nombre, porcentaje_empresa_pct, porcentaje_personalizado ON motoristas FOR EACH ROW EXECUTE FUNCTION flota_fijar_colaboradores_sin_comision_v1();

CREATE TRIGGER impedir_cobros_tras_cierre BEFORE INSERT ON movimientos_financieros FOR EACH ROW EXECUTE FUNCTION flota_impedir_cobros_con_caja_presentada();

CREATE TRIGGER deliveryya_fijar_autor_pedido_trg BEFORE INSERT ON pedidos FOR EACH ROW EXECUTE FUNCTION deliveryya_fijar_autor_pedido();

CREATE TRIGGER flota_fijar_pct_pedido_colaborador_v1 BEFORE INSERT OR UPDATE OF motorista_id, porcentaje_empresa_pct, porcentaje_motorista_pct ON pedidos FOR EACH ROW EXECUTE FUNCTION flota_fijar_pct_pedido_colaborador_v1();

CREATE TRIGGER flota_validar_origen_tarifa_pedido_trg BEFORE INSERT OR UPDATE OF precio_delivery ON pedidos FOR EACH ROW EXECUTE FUNCTION flota_validar_origen_tarifa_pedido();

CREATE TRIGGER trigger_pedido_finanzas AFTER UPDATE ON pedidos FOR EACH ROW EXECUTE FUNCTION registrar_movimiento_financiero();

CREATE TRIGGER zz_flota_boom_tarifa_minima_v1 BEFORE INSERT OR UPDATE OF precio_delivery, delivery_cliente, delivery_subsidio_tienda, regla_comercial ON pedidos FOR EACH ROW EXECUTE FUNCTION flota_boom_tarifa_minima_v1();

CREATE TRIGGER provisionar_tienda_v2_trigger AFTER INSERT ON tienda_cuentas_v2 FOR EACH ROW EXECUTE FUNCTION provisionar_tienda_v2();

CREATE TRIGGER deliveryya_propietario_membresia_trg AFTER INSERT ON tiendas FOR EACH ROW EXECUTE FUNCTION deliveryya_propietario_membresia();

CREATE TRIGGER deliveryya_tienda_codigo BEFORE INSERT OR UPDATE ON tiendas FOR EACH ROW EXECUTE FUNCTION deliveryya_asignar_codigo_tienda();

CREATE TRIGGER flota_proteger_persa_interna_v1 BEFORE INSERT OR UPDATE OF uso_interno_logistico ON tiendas FOR EACH ROW EXECUTE FUNCTION flota_proteger_persa_interna_v1();

-- rls

ALTER TABLE public.motivos_incidencia_catalogo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motivos_incidencia_catalogo NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.motorista_invitaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motorista_invitaciones NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.tienda_invitaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tienda_invitaciones NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.tiendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tiendas NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empresas NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfiles NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.tarifas_zona ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tarifas_zona NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.movimientos_financieros ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movimientos_financieros NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.rutas_generales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rutas_generales NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_usuarios NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_invitaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_invitaciones NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_cierres_motoristas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_cierres_motoristas NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_solicitudes_tienda ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_solicitudes_tienda NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.versiones_optimizacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.versiones_optimizacion NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.tienda_cuentas_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tienda_cuentas_v2 NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_propietarios_pendientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_propietarios_pendientes NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.motorista_ordenes_pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motorista_ordenes_pedidos NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_tienda_propietarias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_tienda_propietarias NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.rendiciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rendiciones NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.tienda_miembros ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tienda_miembros NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.motoristas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motoristas NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.pedidos_ediciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_ediciones NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_rechazos_detalle ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_rechazos_detalle NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_cupo_optimizacion_google ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_cupo_optimizacion_google NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.motorista_recorridos_confirmados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motorista_recorridos_confirmados NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_compensaciones_tienda ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_compensaciones_tienda NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public.flota_pagos_tienda ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flota_pagos_tienda NO FORCE ROW LEVEL SECURITY;

-- policies

CREATE POLICY flota_ver_cierres_finanzas ON public.flota_cierres_motoristas AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = flota_cierres_motoristas.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo AND ((f.rol = 'propietario'::text) OR f.puede_finanzas)))));

CREATE POLICY motorista_ver_cierre ON public.flota_cierres_motoristas AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = flota_cierres_motoristas.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))));

CREATE POLICY flota_rechazos_lectura_admin ON public.flota_rechazos_detalle AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = flota_rechazos_detalle.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo AND ((f.rol = 'propietario'::text) OR f.puede_finanzas)))));

CREATE POLICY flota_rechazos_lectura_motorista ON public.flota_rechazos_detalle AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = flota_rechazos_detalle.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))));

CREATE POLICY flota_usuarios_leer_propio ON public.flota_usuarios AS PERMISSIVE FOR SELECT TO authenticated USING ((usuario_id = ( SELECT auth.uid() AS uid)));

CREATE POLICY motorista_leer_orden ON public.motorista_ordenes_pedidos AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = motorista_ordenes_pedidos.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))));

CREATE POLICY flota_motoristas_lectura ON public.motoristas AS PERMISSIVE FOR SELECT TO authenticated USING (flota_puede_leer(empresa_id));

CREATE POLICY motorista_ver_su_ficha ON public.motoristas AS PERMISSIVE FOR SELECT TO authenticated USING ((usuario_id = ( SELECT auth.uid() AS uid)));

CREATE POLICY flota_movimientos_financieros_autorizados ON public.movimientos_financieros AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = movimientos_financieros.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo AND ((f.rol = 'propietario'::text) OR f.puede_finanzas)))));

CREATE POLICY motorista_movimientos_propio ON public.movimientos_financieros AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = movimientos_financieros.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))));

CREATE POLICY flota_pedidos_lectura ON public.pedidos AS PERMISSIVE FOR SELECT TO authenticated USING (flota_puede_leer(empresa_id));

CREATE POLICY lectura_pedidos_admin ON public.pedidos AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM perfiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND (p.empresa_id = pedidos.empresa_id) AND p.activo AND (p.rol = ANY (ARRAY['admin'::text, 'superadmin'::text]))))));

CREATE POLICY motorista_ver_sus_pedidos ON public.pedidos AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM motoristas m
  WHERE ((m.id = pedidos.motorista_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))));

CREATE POLICY pedido_crear_miembro ON public.pedidos AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((estado = 'pendiente'::text) AND (motorista_id IS NULL) AND (ruta_general_id IS NULL) AND (numero_general IS NULL) AND (medio_cobro IS NULL) AND (EXISTS ( SELECT 1
   FROM tienda_miembros m
  WHERE ((m.tienda_id = pedidos.tienda_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))) AND (EXISTS ( SELECT 1
   FROM tiendas t
  WHERE ((t.id = pedidos.tienda_id) AND (t.empresa_id = pedidos.empresa_id) AND t.activo)))));

CREATE POLICY pedido_leer_miembro ON public.pedidos AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM tienda_miembros m
  WHERE ((m.tienda_id = pedidos.tienda_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo AND ((m.rol = 'propietario'::text) OR ((m.rol = 'empleado'::text) AND (pedidos.creado_por = ( SELECT auth.uid() AS uid))))))));

CREATE POLICY pedidos_ediciones_ver_autorizados ON public.pedidos_ediciones AS PERMISSIVE FOR SELECT TO authenticated USING (((EXISTS ( SELECT 1
   FROM tienda_miembros m
  WHERE ((m.tienda_id = pedidos_ediciones.tienda_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))) OR (EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = pedidos_ediciones.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo))) OR (EXISTS ( SELECT 1
   FROM (motoristas m
     JOIN pedidos p ON ((p.motorista_id = m.id)))
  WHERE ((p.id = pedidos_ediciones.pedido_id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo)))));

CREATE POLICY perfil_autoregistro_tienda ON public.perfiles AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (((id = ( SELECT auth.uid() AS uid)) AND (empresa_id = 'a0000000-0000-0000-0000-000000000001'::uuid) AND (rol = 'tienda'::text) AND (activo = true)));

CREATE POLICY perfil_lectura_propia ON public.perfiles AS PERMISSIVE FOR SELECT TO authenticated USING ((id = ( SELECT auth.uid() AS uid)));

CREATE POLICY flota_rendiciones_finanzas ON public.rendiciones AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM flota_usuarios f
  WHERE ((f.empresa_id = rendiciones.empresa_id) AND (f.usuario_id = ( SELECT auth.uid() AS uid)) AND f.activo AND ((f.rol = 'propietario'::text) OR f.puede_finanzas)))));

CREATE POLICY flota_rutas_lectura ON public.rutas_generales AS PERMISSIVE FOR SELECT TO authenticated USING (flota_puede_leer(empresa_id));

CREATE POLICY motorista_ver_fecha_sus_rutas ON public.rutas_generales AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM (pedidos p
     JOIN motoristas m ON ((m.id = p.motorista_id)))
  WHERE ((p.ruta_general_id = rutas_generales.id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))));

CREATE POLICY tienda_v2_select ON public.tienda_cuentas_v2 AS PERMISSIVE FOR SELECT TO authenticated USING ((id = ( SELECT auth.uid() AS uid)));

CREATE POLICY lectura_miembros_autorizados ON public.tienda_miembros AS PERMISSIVE FOR SELECT TO authenticated USING ((usuario_id = ( SELECT auth.uid() AS uid)));

CREATE POLICY miembros_leer_propio ON public.tienda_miembros AS PERMISSIVE FOR SELECT TO authenticated USING ((usuario_id = ( SELECT auth.uid() AS uid)));

CREATE POLICY flota_tiendas_lectura ON public.tiendas AS PERMISSIVE FOR SELECT TO authenticated USING (flota_puede_leer(empresa_id));

CREATE POLICY lectura_tiendas_admin ON public.tiendas AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM perfiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND (p.empresa_id = tiendas.empresa_id) AND p.activo AND (p.rol = ANY (ARRAY['admin'::text, 'superadmin'::text]))))));

CREATE POLICY tienda_leer_miembro ON public.tiendas AS PERMISSIVE FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM tienda_miembros m
  WHERE ((m.tienda_id = tiendas.id) AND (m.usuario_id = ( SELECT auth.uid() AS uid)) AND m.activo))));

-- schema_grants

GRANT USAGE ON SCHEMA public TO pg_database_owner;

GRANT CREATE ON SCHEMA public TO pg_database_owner;

GRANT USAGE ON SCHEMA public TO PUBLIC;

GRANT USAGE ON SCHEMA public TO postgres;

GRANT USAGE ON SCHEMA public TO anon;

GRANT USAGE ON SCHEMA public TO authenticated;

GRANT USAGE ON SCHEMA public TO service_role;

-- grants

GRANT INSERT ON TABLE public.motivos_incidencia_catalogo TO postgres;

GRANT SELECT ON TABLE public.motivos_incidencia_catalogo TO postgres;

GRANT UPDATE ON TABLE public.motivos_incidencia_catalogo TO postgres;

GRANT DELETE ON TABLE public.motivos_incidencia_catalogo TO postgres;

GRANT TRUNCATE ON TABLE public.motivos_incidencia_catalogo TO postgres;

GRANT REFERENCES ON TABLE public.motivos_incidencia_catalogo TO postgres;

GRANT TRIGGER ON TABLE public.motivos_incidencia_catalogo TO postgres;

GRANT MAINTAIN ON TABLE public.motivos_incidencia_catalogo TO postgres;

GRANT INSERT ON TABLE public.motivos_incidencia_catalogo TO authenticated;

GRANT SELECT ON TABLE public.motivos_incidencia_catalogo TO authenticated;

GRANT UPDATE ON TABLE public.motivos_incidencia_catalogo TO authenticated;

GRANT DELETE ON TABLE public.motivos_incidencia_catalogo TO authenticated;

GRANT TRUNCATE ON TABLE public.motivos_incidencia_catalogo TO authenticated;

GRANT REFERENCES ON TABLE public.motivos_incidencia_catalogo TO authenticated;

GRANT TRIGGER ON TABLE public.motivos_incidencia_catalogo TO authenticated;

GRANT MAINTAIN ON TABLE public.motivos_incidencia_catalogo TO authenticated;

GRANT INSERT ON TABLE public.motivos_incidencia_catalogo TO service_role;

GRANT SELECT ON TABLE public.motivos_incidencia_catalogo TO service_role;

GRANT UPDATE ON TABLE public.motivos_incidencia_catalogo TO service_role;

GRANT DELETE ON TABLE public.motivos_incidencia_catalogo TO service_role;

GRANT TRUNCATE ON TABLE public.motivos_incidencia_catalogo TO service_role;

GRANT REFERENCES ON TABLE public.motivos_incidencia_catalogo TO service_role;

GRANT TRIGGER ON TABLE public.motivos_incidencia_catalogo TO service_role;

GRANT MAINTAIN ON TABLE public.motivos_incidencia_catalogo TO service_role;

GRANT INSERT ON TABLE public.motorista_invitaciones TO postgres;

GRANT SELECT ON TABLE public.motorista_invitaciones TO postgres;

GRANT UPDATE ON TABLE public.motorista_invitaciones TO postgres;

GRANT DELETE ON TABLE public.motorista_invitaciones TO postgres;

GRANT TRUNCATE ON TABLE public.motorista_invitaciones TO postgres;

GRANT REFERENCES ON TABLE public.motorista_invitaciones TO postgres;

GRANT TRIGGER ON TABLE public.motorista_invitaciones TO postgres;

GRANT MAINTAIN ON TABLE public.motorista_invitaciones TO postgres;

GRANT INSERT ON TABLE public.motorista_invitaciones TO authenticated;

GRANT SELECT ON TABLE public.motorista_invitaciones TO authenticated;

GRANT UPDATE ON TABLE public.motorista_invitaciones TO authenticated;

GRANT DELETE ON TABLE public.motorista_invitaciones TO authenticated;

GRANT TRUNCATE ON TABLE public.motorista_invitaciones TO authenticated;

GRANT REFERENCES ON TABLE public.motorista_invitaciones TO authenticated;

GRANT TRIGGER ON TABLE public.motorista_invitaciones TO authenticated;

GRANT MAINTAIN ON TABLE public.motorista_invitaciones TO authenticated;

GRANT INSERT ON TABLE public.motorista_invitaciones TO service_role;

GRANT SELECT ON TABLE public.motorista_invitaciones TO service_role;

GRANT UPDATE ON TABLE public.motorista_invitaciones TO service_role;

GRANT DELETE ON TABLE public.motorista_invitaciones TO service_role;

GRANT TRUNCATE ON TABLE public.motorista_invitaciones TO service_role;

GRANT REFERENCES ON TABLE public.motorista_invitaciones TO service_role;

GRANT TRIGGER ON TABLE public.motorista_invitaciones TO service_role;

GRANT MAINTAIN ON TABLE public.motorista_invitaciones TO service_role;

GRANT INSERT ON TABLE public.tienda_invitaciones TO postgres;

GRANT SELECT ON TABLE public.tienda_invitaciones TO postgres;

GRANT UPDATE ON TABLE public.tienda_invitaciones TO postgres;

GRANT DELETE ON TABLE public.tienda_invitaciones TO postgres;

GRANT TRUNCATE ON TABLE public.tienda_invitaciones TO postgres;

GRANT REFERENCES ON TABLE public.tienda_invitaciones TO postgres;

GRANT TRIGGER ON TABLE public.tienda_invitaciones TO postgres;

GRANT MAINTAIN ON TABLE public.tienda_invitaciones TO postgres;

GRANT INSERT ON TABLE public.tienda_invitaciones TO authenticated;

GRANT SELECT ON TABLE public.tienda_invitaciones TO authenticated;

GRANT UPDATE ON TABLE public.tienda_invitaciones TO authenticated;

GRANT DELETE ON TABLE public.tienda_invitaciones TO authenticated;

GRANT TRUNCATE ON TABLE public.tienda_invitaciones TO authenticated;

GRANT REFERENCES ON TABLE public.tienda_invitaciones TO authenticated;

GRANT TRIGGER ON TABLE public.tienda_invitaciones TO authenticated;

GRANT MAINTAIN ON TABLE public.tienda_invitaciones TO authenticated;

GRANT INSERT ON TABLE public.tienda_invitaciones TO service_role;

GRANT SELECT ON TABLE public.tienda_invitaciones TO service_role;

GRANT UPDATE ON TABLE public.tienda_invitaciones TO service_role;

GRANT DELETE ON TABLE public.tienda_invitaciones TO service_role;

GRANT TRUNCATE ON TABLE public.tienda_invitaciones TO service_role;

GRANT REFERENCES ON TABLE public.tienda_invitaciones TO service_role;

GRANT TRIGGER ON TABLE public.tienda_invitaciones TO service_role;

GRANT MAINTAIN ON TABLE public.tienda_invitaciones TO service_role;

GRANT INSERT ON TABLE public.vista_auditoria_incidencias TO postgres;

GRANT SELECT ON TABLE public.vista_auditoria_incidencias TO postgres;

GRANT UPDATE ON TABLE public.vista_auditoria_incidencias TO postgres;

GRANT DELETE ON TABLE public.vista_auditoria_incidencias TO postgres;

GRANT TRUNCATE ON TABLE public.vista_auditoria_incidencias TO postgres;

GRANT REFERENCES ON TABLE public.vista_auditoria_incidencias TO postgres;

GRANT TRIGGER ON TABLE public.vista_auditoria_incidencias TO postgres;

GRANT MAINTAIN ON TABLE public.vista_auditoria_incidencias TO postgres;

GRANT INSERT ON TABLE public.vista_auditoria_incidencias TO authenticated;

GRANT SELECT ON TABLE public.vista_auditoria_incidencias TO authenticated;

GRANT UPDATE ON TABLE public.vista_auditoria_incidencias TO authenticated;

GRANT DELETE ON TABLE public.vista_auditoria_incidencias TO authenticated;

GRANT TRUNCATE ON TABLE public.vista_auditoria_incidencias TO authenticated;

GRANT REFERENCES ON TABLE public.vista_auditoria_incidencias TO authenticated;

GRANT TRIGGER ON TABLE public.vista_auditoria_incidencias TO authenticated;

GRANT MAINTAIN ON TABLE public.vista_auditoria_incidencias TO authenticated;

GRANT INSERT ON TABLE public.vista_auditoria_incidencias TO service_role;

GRANT SELECT ON TABLE public.vista_auditoria_incidencias TO service_role;

GRANT UPDATE ON TABLE public.vista_auditoria_incidencias TO service_role;

GRANT DELETE ON TABLE public.vista_auditoria_incidencias TO service_role;

GRANT TRUNCATE ON TABLE public.vista_auditoria_incidencias TO service_role;

GRANT REFERENCES ON TABLE public.vista_auditoria_incidencias TO service_role;

GRANT TRIGGER ON TABLE public.vista_auditoria_incidencias TO service_role;

GRANT MAINTAIN ON TABLE public.vista_auditoria_incidencias TO service_role;

GRANT INSERT ON TABLE public.tiendas TO postgres;

GRANT SELECT ON TABLE public.tiendas TO postgres;

GRANT UPDATE ON TABLE public.tiendas TO postgres;

GRANT DELETE ON TABLE public.tiendas TO postgres;

GRANT TRUNCATE ON TABLE public.tiendas TO postgres;

GRANT REFERENCES ON TABLE public.tiendas TO postgres;

GRANT TRIGGER ON TABLE public.tiendas TO postgres;

GRANT MAINTAIN ON TABLE public.tiendas TO postgres;

GRANT INSERT ON TABLE public.tiendas TO authenticated;

GRANT SELECT ON TABLE public.tiendas TO authenticated;

GRANT UPDATE ON TABLE public.tiendas TO authenticated;

GRANT DELETE ON TABLE public.tiendas TO authenticated;

GRANT TRUNCATE ON TABLE public.tiendas TO authenticated;

GRANT REFERENCES ON TABLE public.tiendas TO authenticated;

GRANT TRIGGER ON TABLE public.tiendas TO authenticated;

GRANT MAINTAIN ON TABLE public.tiendas TO authenticated;

GRANT INSERT ON TABLE public.tiendas TO service_role;

GRANT SELECT ON TABLE public.tiendas TO service_role;

GRANT UPDATE ON TABLE public.tiendas TO service_role;

GRANT DELETE ON TABLE public.tiendas TO service_role;

GRANT TRUNCATE ON TABLE public.tiendas TO service_role;

GRANT REFERENCES ON TABLE public.tiendas TO service_role;

GRANT TRIGGER ON TABLE public.tiendas TO service_role;

GRANT MAINTAIN ON TABLE public.tiendas TO service_role;

GRANT INSERT ON TABLE public.empresas TO postgres;

GRANT SELECT ON TABLE public.empresas TO postgres;

GRANT UPDATE ON TABLE public.empresas TO postgres;

GRANT DELETE ON TABLE public.empresas TO postgres;

GRANT TRUNCATE ON TABLE public.empresas TO postgres;

GRANT REFERENCES ON TABLE public.empresas TO postgres;

GRANT TRIGGER ON TABLE public.empresas TO postgres;

GRANT MAINTAIN ON TABLE public.empresas TO postgres;

GRANT INSERT ON TABLE public.empresas TO authenticated;

GRANT SELECT ON TABLE public.empresas TO authenticated;

GRANT UPDATE ON TABLE public.empresas TO authenticated;

GRANT DELETE ON TABLE public.empresas TO authenticated;

GRANT TRUNCATE ON TABLE public.empresas TO authenticated;

GRANT REFERENCES ON TABLE public.empresas TO authenticated;

GRANT TRIGGER ON TABLE public.empresas TO authenticated;

GRANT MAINTAIN ON TABLE public.empresas TO authenticated;

GRANT INSERT ON TABLE public.empresas TO service_role;

GRANT SELECT ON TABLE public.empresas TO service_role;

GRANT UPDATE ON TABLE public.empresas TO service_role;

GRANT DELETE ON TABLE public.empresas TO service_role;

GRANT TRUNCATE ON TABLE public.empresas TO service_role;

GRANT REFERENCES ON TABLE public.empresas TO service_role;

GRANT TRIGGER ON TABLE public.empresas TO service_role;

GRANT MAINTAIN ON TABLE public.empresas TO service_role;

GRANT INSERT ON TABLE public.perfiles TO postgres;

GRANT SELECT ON TABLE public.perfiles TO postgres;

GRANT UPDATE ON TABLE public.perfiles TO postgres;

GRANT DELETE ON TABLE public.perfiles TO postgres;

GRANT TRUNCATE ON TABLE public.perfiles TO postgres;

GRANT REFERENCES ON TABLE public.perfiles TO postgres;

GRANT TRIGGER ON TABLE public.perfiles TO postgres;

GRANT MAINTAIN ON TABLE public.perfiles TO postgres;

GRANT INSERT ON TABLE public.perfiles TO authenticated;

GRANT SELECT ON TABLE public.perfiles TO authenticated;

GRANT UPDATE ON TABLE public.perfiles TO authenticated;

GRANT DELETE ON TABLE public.perfiles TO authenticated;

GRANT TRUNCATE ON TABLE public.perfiles TO authenticated;

GRANT REFERENCES ON TABLE public.perfiles TO authenticated;

GRANT TRIGGER ON TABLE public.perfiles TO authenticated;

GRANT MAINTAIN ON TABLE public.perfiles TO authenticated;

GRANT INSERT ON TABLE public.perfiles TO service_role;

GRANT SELECT ON TABLE public.perfiles TO service_role;

GRANT UPDATE ON TABLE public.perfiles TO service_role;

GRANT DELETE ON TABLE public.perfiles TO service_role;

GRANT TRUNCATE ON TABLE public.perfiles TO service_role;

GRANT REFERENCES ON TABLE public.perfiles TO service_role;

GRANT TRIGGER ON TABLE public.perfiles TO service_role;

GRANT MAINTAIN ON TABLE public.perfiles TO service_role;

GRANT INSERT ON TABLE public.clientes TO postgres;

GRANT SELECT ON TABLE public.clientes TO postgres;

GRANT UPDATE ON TABLE public.clientes TO postgres;

GRANT DELETE ON TABLE public.clientes TO postgres;

GRANT TRUNCATE ON TABLE public.clientes TO postgres;

GRANT REFERENCES ON TABLE public.clientes TO postgres;

GRANT TRIGGER ON TABLE public.clientes TO postgres;

GRANT MAINTAIN ON TABLE public.clientes TO postgres;

GRANT INSERT ON TABLE public.clientes TO authenticated;

GRANT SELECT ON TABLE public.clientes TO authenticated;

GRANT UPDATE ON TABLE public.clientes TO authenticated;

GRANT DELETE ON TABLE public.clientes TO authenticated;

GRANT TRUNCATE ON TABLE public.clientes TO authenticated;

GRANT REFERENCES ON TABLE public.clientes TO authenticated;

GRANT TRIGGER ON TABLE public.clientes TO authenticated;

GRANT MAINTAIN ON TABLE public.clientes TO authenticated;

GRANT INSERT ON TABLE public.clientes TO service_role;

GRANT SELECT ON TABLE public.clientes TO service_role;

GRANT UPDATE ON TABLE public.clientes TO service_role;

GRANT DELETE ON TABLE public.clientes TO service_role;

GRANT TRUNCATE ON TABLE public.clientes TO service_role;

GRANT REFERENCES ON TABLE public.clientes TO service_role;

GRANT TRIGGER ON TABLE public.clientes TO service_role;

GRANT MAINTAIN ON TABLE public.clientes TO service_role;

GRANT INSERT ON TABLE public.tarifas_zona TO postgres;

GRANT SELECT ON TABLE public.tarifas_zona TO postgres;

GRANT UPDATE ON TABLE public.tarifas_zona TO postgres;

GRANT DELETE ON TABLE public.tarifas_zona TO postgres;

GRANT TRUNCATE ON TABLE public.tarifas_zona TO postgres;

GRANT REFERENCES ON TABLE public.tarifas_zona TO postgres;

GRANT TRIGGER ON TABLE public.tarifas_zona TO postgres;

GRANT MAINTAIN ON TABLE public.tarifas_zona TO postgres;

GRANT INSERT ON TABLE public.tarifas_zona TO authenticated;

GRANT SELECT ON TABLE public.tarifas_zona TO authenticated;

GRANT UPDATE ON TABLE public.tarifas_zona TO authenticated;

GRANT DELETE ON TABLE public.tarifas_zona TO authenticated;

GRANT TRUNCATE ON TABLE public.tarifas_zona TO authenticated;

GRANT REFERENCES ON TABLE public.tarifas_zona TO authenticated;

GRANT TRIGGER ON TABLE public.tarifas_zona TO authenticated;

GRANT MAINTAIN ON TABLE public.tarifas_zona TO authenticated;

GRANT INSERT ON TABLE public.tarifas_zona TO service_role;

GRANT SELECT ON TABLE public.tarifas_zona TO service_role;

GRANT UPDATE ON TABLE public.tarifas_zona TO service_role;

GRANT DELETE ON TABLE public.tarifas_zona TO service_role;

GRANT TRUNCATE ON TABLE public.tarifas_zona TO service_role;

GRANT REFERENCES ON TABLE public.tarifas_zona TO service_role;

GRANT TRIGGER ON TABLE public.tarifas_zona TO service_role;

GRANT MAINTAIN ON TABLE public.tarifas_zona TO service_role;

GRANT INSERT ON TABLE public.vista_pedidos_admin TO postgres;

GRANT SELECT ON TABLE public.vista_pedidos_admin TO postgres;

GRANT UPDATE ON TABLE public.vista_pedidos_admin TO postgres;

GRANT DELETE ON TABLE public.vista_pedidos_admin TO postgres;

GRANT TRUNCATE ON TABLE public.vista_pedidos_admin TO postgres;

GRANT REFERENCES ON TABLE public.vista_pedidos_admin TO postgres;

GRANT TRIGGER ON TABLE public.vista_pedidos_admin TO postgres;

GRANT MAINTAIN ON TABLE public.vista_pedidos_admin TO postgres;

GRANT INSERT ON TABLE public.vista_pedidos_admin TO authenticated;

GRANT SELECT ON TABLE public.vista_pedidos_admin TO authenticated;

GRANT UPDATE ON TABLE public.vista_pedidos_admin TO authenticated;

GRANT DELETE ON TABLE public.vista_pedidos_admin TO authenticated;

GRANT TRUNCATE ON TABLE public.vista_pedidos_admin TO authenticated;

GRANT REFERENCES ON TABLE public.vista_pedidos_admin TO authenticated;

GRANT TRIGGER ON TABLE public.vista_pedidos_admin TO authenticated;

GRANT MAINTAIN ON TABLE public.vista_pedidos_admin TO authenticated;

GRANT INSERT ON TABLE public.vista_pedidos_admin TO service_role;

GRANT SELECT ON TABLE public.vista_pedidos_admin TO service_role;

GRANT UPDATE ON TABLE public.vista_pedidos_admin TO service_role;

GRANT DELETE ON TABLE public.vista_pedidos_admin TO service_role;

GRANT TRUNCATE ON TABLE public.vista_pedidos_admin TO service_role;

GRANT REFERENCES ON TABLE public.vista_pedidos_admin TO service_role;

GRANT TRIGGER ON TABLE public.vista_pedidos_admin TO service_role;

GRANT MAINTAIN ON TABLE public.vista_pedidos_admin TO service_role;

GRANT INSERT ON TABLE public.movimientos_financieros TO postgres;

GRANT SELECT ON TABLE public.movimientos_financieros TO postgres;

GRANT UPDATE ON TABLE public.movimientos_financieros TO postgres;

GRANT DELETE ON TABLE public.movimientos_financieros TO postgres;

GRANT TRUNCATE ON TABLE public.movimientos_financieros TO postgres;

GRANT REFERENCES ON TABLE public.movimientos_financieros TO postgres;

GRANT TRIGGER ON TABLE public.movimientos_financieros TO postgres;

GRANT MAINTAIN ON TABLE public.movimientos_financieros TO postgres;

GRANT INSERT ON TABLE public.movimientos_financieros TO authenticated;

GRANT SELECT ON TABLE public.movimientos_financieros TO authenticated;

GRANT UPDATE ON TABLE public.movimientos_financieros TO authenticated;

GRANT DELETE ON TABLE public.movimientos_financieros TO authenticated;

GRANT TRUNCATE ON TABLE public.movimientos_financieros TO authenticated;

GRANT REFERENCES ON TABLE public.movimientos_financieros TO authenticated;

GRANT TRIGGER ON TABLE public.movimientos_financieros TO authenticated;

GRANT MAINTAIN ON TABLE public.movimientos_financieros TO authenticated;

GRANT INSERT ON TABLE public.movimientos_financieros TO service_role;

GRANT SELECT ON TABLE public.movimientos_financieros TO service_role;

GRANT UPDATE ON TABLE public.movimientos_financieros TO service_role;

GRANT DELETE ON TABLE public.movimientos_financieros TO service_role;

GRANT TRUNCATE ON TABLE public.movimientos_financieros TO service_role;

GRANT REFERENCES ON TABLE public.movimientos_financieros TO service_role;

GRANT TRIGGER ON TABLE public.movimientos_financieros TO service_role;

GRANT MAINTAIN ON TABLE public.movimientos_financieros TO service_role;

GRANT INSERT ON TABLE public.rutas_generales TO postgres;

GRANT SELECT ON TABLE public.rutas_generales TO postgres;

GRANT UPDATE ON TABLE public.rutas_generales TO postgres;

GRANT DELETE ON TABLE public.rutas_generales TO postgres;

GRANT TRUNCATE ON TABLE public.rutas_generales TO postgres;

GRANT REFERENCES ON TABLE public.rutas_generales TO postgres;

GRANT TRIGGER ON TABLE public.rutas_generales TO postgres;

GRANT MAINTAIN ON TABLE public.rutas_generales TO postgres;

GRANT INSERT ON TABLE public.rutas_generales TO authenticated;

GRANT SELECT ON TABLE public.rutas_generales TO authenticated;

GRANT UPDATE ON TABLE public.rutas_generales TO authenticated;

GRANT DELETE ON TABLE public.rutas_generales TO authenticated;

GRANT TRUNCATE ON TABLE public.rutas_generales TO authenticated;

GRANT REFERENCES ON TABLE public.rutas_generales TO authenticated;

GRANT TRIGGER ON TABLE public.rutas_generales TO authenticated;

GRANT MAINTAIN ON TABLE public.rutas_generales TO authenticated;

GRANT INSERT ON TABLE public.rutas_generales TO service_role;

GRANT SELECT ON TABLE public.rutas_generales TO service_role;

GRANT UPDATE ON TABLE public.rutas_generales TO service_role;

GRANT DELETE ON TABLE public.rutas_generales TO service_role;

GRANT TRUNCATE ON TABLE public.rutas_generales TO service_role;

GRANT REFERENCES ON TABLE public.rutas_generales TO service_role;

GRANT TRIGGER ON TABLE public.rutas_generales TO service_role;

GRANT MAINTAIN ON TABLE public.rutas_generales TO service_role;

GRANT INSERT ON TABLE public.flota_usuarios TO postgres;

GRANT SELECT ON TABLE public.flota_usuarios TO postgres;

GRANT UPDATE ON TABLE public.flota_usuarios TO postgres;

GRANT DELETE ON TABLE public.flota_usuarios TO postgres;

GRANT TRUNCATE ON TABLE public.flota_usuarios TO postgres;

GRANT REFERENCES ON TABLE public.flota_usuarios TO postgres;

GRANT TRIGGER ON TABLE public.flota_usuarios TO postgres;

GRANT MAINTAIN ON TABLE public.flota_usuarios TO postgres;

GRANT INSERT ON TABLE public.flota_usuarios TO authenticated;

GRANT SELECT ON TABLE public.flota_usuarios TO authenticated;

GRANT UPDATE ON TABLE public.flota_usuarios TO authenticated;

GRANT DELETE ON TABLE public.flota_usuarios TO authenticated;

GRANT TRUNCATE ON TABLE public.flota_usuarios TO authenticated;

GRANT REFERENCES ON TABLE public.flota_usuarios TO authenticated;

GRANT TRIGGER ON TABLE public.flota_usuarios TO authenticated;

GRANT MAINTAIN ON TABLE public.flota_usuarios TO authenticated;

GRANT INSERT ON TABLE public.flota_usuarios TO service_role;

GRANT SELECT ON TABLE public.flota_usuarios TO service_role;

GRANT UPDATE ON TABLE public.flota_usuarios TO service_role;

GRANT DELETE ON TABLE public.flota_usuarios TO service_role;

GRANT TRUNCATE ON TABLE public.flota_usuarios TO service_role;

GRANT REFERENCES ON TABLE public.flota_usuarios TO service_role;

GRANT TRIGGER ON TABLE public.flota_usuarios TO service_role;

GRANT MAINTAIN ON TABLE public.flota_usuarios TO service_role;

GRANT INSERT ON TABLE public.flota_invitaciones TO postgres;

GRANT SELECT ON TABLE public.flota_invitaciones TO postgres;

GRANT UPDATE ON TABLE public.flota_invitaciones TO postgres;

GRANT DELETE ON TABLE public.flota_invitaciones TO postgres;

GRANT TRUNCATE ON TABLE public.flota_invitaciones TO postgres;

GRANT REFERENCES ON TABLE public.flota_invitaciones TO postgres;

GRANT TRIGGER ON TABLE public.flota_invitaciones TO postgres;

GRANT MAINTAIN ON TABLE public.flota_invitaciones TO postgres;

GRANT INSERT ON TABLE public.flota_invitaciones TO authenticated;

GRANT SELECT ON TABLE public.flota_invitaciones TO authenticated;

GRANT UPDATE ON TABLE public.flota_invitaciones TO authenticated;

GRANT DELETE ON TABLE public.flota_invitaciones TO authenticated;

GRANT TRUNCATE ON TABLE public.flota_invitaciones TO authenticated;

GRANT REFERENCES ON TABLE public.flota_invitaciones TO authenticated;

GRANT TRIGGER ON TABLE public.flota_invitaciones TO authenticated;

GRANT MAINTAIN ON TABLE public.flota_invitaciones TO authenticated;

GRANT INSERT ON TABLE public.flota_invitaciones TO service_role;

GRANT SELECT ON TABLE public.flota_invitaciones TO service_role;

GRANT UPDATE ON TABLE public.flota_invitaciones TO service_role;

GRANT DELETE ON TABLE public.flota_invitaciones TO service_role;

GRANT TRUNCATE ON TABLE public.flota_invitaciones TO service_role;

GRANT REFERENCES ON TABLE public.flota_invitaciones TO service_role;

GRANT TRIGGER ON TABLE public.flota_invitaciones TO service_role;

GRANT MAINTAIN ON TABLE public.flota_invitaciones TO service_role;

GRANT INSERT ON TABLE public.flota_cierres_motoristas TO postgres;

GRANT SELECT ON TABLE public.flota_cierres_motoristas TO postgres;

GRANT UPDATE ON TABLE public.flota_cierres_motoristas TO postgres;

GRANT DELETE ON TABLE public.flota_cierres_motoristas TO postgres;

GRANT TRUNCATE ON TABLE public.flota_cierres_motoristas TO postgres;

GRANT REFERENCES ON TABLE public.flota_cierres_motoristas TO postgres;

GRANT TRIGGER ON TABLE public.flota_cierres_motoristas TO postgres;

GRANT MAINTAIN ON TABLE public.flota_cierres_motoristas TO postgres;

GRANT INSERT ON TABLE public.flota_cierres_motoristas TO authenticated;

GRANT SELECT ON TABLE public.flota_cierres_motoristas TO authenticated;

GRANT UPDATE ON TABLE public.flota_cierres_motoristas TO authenticated;

GRANT DELETE ON TABLE public.flota_cierres_motoristas TO authenticated;

GRANT TRUNCATE ON TABLE public.flota_cierres_motoristas TO authenticated;

GRANT REFERENCES ON TABLE public.flota_cierres_motoristas TO authenticated;

GRANT TRIGGER ON TABLE public.flota_cierres_motoristas TO authenticated;

GRANT MAINTAIN ON TABLE public.flota_cierres_motoristas TO authenticated;

GRANT INSERT ON TABLE public.flota_cierres_motoristas TO service_role;

GRANT SELECT ON TABLE public.flota_cierres_motoristas TO service_role;

GRANT UPDATE ON TABLE public.flota_cierres_motoristas TO service_role;

GRANT DELETE ON TABLE public.flota_cierres_motoristas TO service_role;

GRANT TRUNCATE ON TABLE public.flota_cierres_motoristas TO service_role;

GRANT REFERENCES ON TABLE public.flota_cierres_motoristas TO service_role;

GRANT TRIGGER ON TABLE public.flota_cierres_motoristas TO service_role;

GRANT MAINTAIN ON TABLE public.flota_cierres_motoristas TO service_role;

GRANT INSERT ON TABLE public.flota_solicitudes_tienda TO postgres;

GRANT SELECT ON TABLE public.flota_solicitudes_tienda TO postgres;

GRANT UPDATE ON TABLE public.flota_solicitudes_tienda TO postgres;

GRANT DELETE ON TABLE public.flota_solicitudes_tienda TO postgres;

GRANT TRUNCATE ON TABLE public.flota_solicitudes_tienda TO postgres;

GRANT REFERENCES ON TABLE public.flota_solicitudes_tienda TO postgres;

GRANT TRIGGER ON TABLE public.flota_solicitudes_tienda TO postgres;

GRANT MAINTAIN ON TABLE public.flota_solicitudes_tienda TO postgres;

GRANT INSERT ON TABLE public.flota_solicitudes_tienda TO service_role;

GRANT SELECT ON TABLE public.flota_solicitudes_tienda TO service_role;

GRANT UPDATE ON TABLE public.flota_solicitudes_tienda TO service_role;

GRANT DELETE ON TABLE public.flota_solicitudes_tienda TO service_role;

GRANT TRUNCATE ON TABLE public.flota_solicitudes_tienda TO service_role;

GRANT REFERENCES ON TABLE public.flota_solicitudes_tienda TO service_role;

GRANT TRIGGER ON TABLE public.flota_solicitudes_tienda TO service_role;

GRANT MAINTAIN ON TABLE public.flota_solicitudes_tienda TO service_role;

GRANT INSERT ON TABLE public.versiones_optimizacion TO postgres;

GRANT SELECT ON TABLE public.versiones_optimizacion TO postgres;

GRANT UPDATE ON TABLE public.versiones_optimizacion TO postgres;

GRANT DELETE ON TABLE public.versiones_optimizacion TO postgres;

GRANT TRUNCATE ON TABLE public.versiones_optimizacion TO postgres;

GRANT REFERENCES ON TABLE public.versiones_optimizacion TO postgres;

GRANT TRIGGER ON TABLE public.versiones_optimizacion TO postgres;

GRANT MAINTAIN ON TABLE public.versiones_optimizacion TO postgres;

GRANT INSERT ON TABLE public.versiones_optimizacion TO authenticated;

GRANT SELECT ON TABLE public.versiones_optimizacion TO authenticated;

GRANT UPDATE ON TABLE public.versiones_optimizacion TO authenticated;

GRANT DELETE ON TABLE public.versiones_optimizacion TO authenticated;

GRANT TRUNCATE ON TABLE public.versiones_optimizacion TO authenticated;

GRANT REFERENCES ON TABLE public.versiones_optimizacion TO authenticated;

GRANT TRIGGER ON TABLE public.versiones_optimizacion TO authenticated;

GRANT MAINTAIN ON TABLE public.versiones_optimizacion TO authenticated;

GRANT INSERT ON TABLE public.versiones_optimizacion TO service_role;

GRANT SELECT ON TABLE public.versiones_optimizacion TO service_role;

GRANT UPDATE ON TABLE public.versiones_optimizacion TO service_role;

GRANT DELETE ON TABLE public.versiones_optimizacion TO service_role;

GRANT TRUNCATE ON TABLE public.versiones_optimizacion TO service_role;

GRANT REFERENCES ON TABLE public.versiones_optimizacion TO service_role;

GRANT TRIGGER ON TABLE public.versiones_optimizacion TO service_role;

GRANT MAINTAIN ON TABLE public.versiones_optimizacion TO service_role;

GRANT INSERT ON TABLE public.tienda_cuentas_v2 TO postgres;

GRANT SELECT ON TABLE public.tienda_cuentas_v2 TO postgres;

GRANT UPDATE ON TABLE public.tienda_cuentas_v2 TO postgres;

GRANT DELETE ON TABLE public.tienda_cuentas_v2 TO postgres;

GRANT TRUNCATE ON TABLE public.tienda_cuentas_v2 TO postgres;

GRANT REFERENCES ON TABLE public.tienda_cuentas_v2 TO postgres;

GRANT TRIGGER ON TABLE public.tienda_cuentas_v2 TO postgres;

GRANT MAINTAIN ON TABLE public.tienda_cuentas_v2 TO postgres;

GRANT INSERT ON TABLE public.tienda_cuentas_v2 TO authenticated;

GRANT SELECT ON TABLE public.tienda_cuentas_v2 TO authenticated;

GRANT UPDATE ON TABLE public.tienda_cuentas_v2 TO authenticated;

GRANT DELETE ON TABLE public.tienda_cuentas_v2 TO authenticated;

GRANT TRUNCATE ON TABLE public.tienda_cuentas_v2 TO authenticated;

GRANT REFERENCES ON TABLE public.tienda_cuentas_v2 TO authenticated;

GRANT TRIGGER ON TABLE public.tienda_cuentas_v2 TO authenticated;

GRANT MAINTAIN ON TABLE public.tienda_cuentas_v2 TO authenticated;

GRANT INSERT ON TABLE public.tienda_cuentas_v2 TO service_role;

GRANT SELECT ON TABLE public.tienda_cuentas_v2 TO service_role;

GRANT UPDATE ON TABLE public.tienda_cuentas_v2 TO service_role;

GRANT DELETE ON TABLE public.tienda_cuentas_v2 TO service_role;

GRANT TRUNCATE ON TABLE public.tienda_cuentas_v2 TO service_role;

GRANT REFERENCES ON TABLE public.tienda_cuentas_v2 TO service_role;

GRANT TRIGGER ON TABLE public.tienda_cuentas_v2 TO service_role;

GRANT MAINTAIN ON TABLE public.tienda_cuentas_v2 TO service_role;

GRANT INSERT ON TABLE public.flota_propietarios_pendientes TO postgres;

GRANT SELECT ON TABLE public.flota_propietarios_pendientes TO postgres;

GRANT UPDATE ON TABLE public.flota_propietarios_pendientes TO postgres;

GRANT DELETE ON TABLE public.flota_propietarios_pendientes TO postgres;

GRANT TRUNCATE ON TABLE public.flota_propietarios_pendientes TO postgres;

GRANT REFERENCES ON TABLE public.flota_propietarios_pendientes TO postgres;

GRANT TRIGGER ON TABLE public.flota_propietarios_pendientes TO postgres;

GRANT MAINTAIN ON TABLE public.flota_propietarios_pendientes TO postgres;

GRANT INSERT ON TABLE public.flota_propietarios_pendientes TO authenticated;

GRANT SELECT ON TABLE public.flota_propietarios_pendientes TO authenticated;

GRANT UPDATE ON TABLE public.flota_propietarios_pendientes TO authenticated;

GRANT DELETE ON TABLE public.flota_propietarios_pendientes TO authenticated;

GRANT TRUNCATE ON TABLE public.flota_propietarios_pendientes TO authenticated;

GRANT REFERENCES ON TABLE public.flota_propietarios_pendientes TO authenticated;

GRANT TRIGGER ON TABLE public.flota_propietarios_pendientes TO authenticated;

GRANT MAINTAIN ON TABLE public.flota_propietarios_pendientes TO authenticated;

GRANT INSERT ON TABLE public.flota_propietarios_pendientes TO service_role;

GRANT SELECT ON TABLE public.flota_propietarios_pendientes TO service_role;

GRANT UPDATE ON TABLE public.flota_propietarios_pendientes TO service_role;

GRANT DELETE ON TABLE public.flota_propietarios_pendientes TO service_role;

GRANT TRUNCATE ON TABLE public.flota_propietarios_pendientes TO service_role;

GRANT REFERENCES ON TABLE public.flota_propietarios_pendientes TO service_role;

GRANT TRIGGER ON TABLE public.flota_propietarios_pendientes TO service_role;

GRANT MAINTAIN ON TABLE public.flota_propietarios_pendientes TO service_role;

GRANT INSERT ON TABLE public.motorista_ordenes_pedidos TO postgres;

GRANT SELECT ON TABLE public.motorista_ordenes_pedidos TO postgres;

GRANT UPDATE ON TABLE public.motorista_ordenes_pedidos TO postgres;

GRANT DELETE ON TABLE public.motorista_ordenes_pedidos TO postgres;

GRANT TRUNCATE ON TABLE public.motorista_ordenes_pedidos TO postgres;

GRANT REFERENCES ON TABLE public.motorista_ordenes_pedidos TO postgres;

GRANT TRIGGER ON TABLE public.motorista_ordenes_pedidos TO postgres;

GRANT MAINTAIN ON TABLE public.motorista_ordenes_pedidos TO postgres;

GRANT INSERT ON TABLE public.motorista_ordenes_pedidos TO authenticated;

GRANT SELECT ON TABLE public.motorista_ordenes_pedidos TO authenticated;

GRANT UPDATE ON TABLE public.motorista_ordenes_pedidos TO authenticated;

GRANT DELETE ON TABLE public.motorista_ordenes_pedidos TO authenticated;

GRANT TRUNCATE ON TABLE public.motorista_ordenes_pedidos TO authenticated;

GRANT REFERENCES ON TABLE public.motorista_ordenes_pedidos TO authenticated;

GRANT TRIGGER ON TABLE public.motorista_ordenes_pedidos TO authenticated;

GRANT MAINTAIN ON TABLE public.motorista_ordenes_pedidos TO authenticated;

GRANT INSERT ON TABLE public.motorista_ordenes_pedidos TO service_role;

GRANT SELECT ON TABLE public.motorista_ordenes_pedidos TO service_role;

GRANT UPDATE ON TABLE public.motorista_ordenes_pedidos TO service_role;

GRANT DELETE ON TABLE public.motorista_ordenes_pedidos TO service_role;

GRANT TRUNCATE ON TABLE public.motorista_ordenes_pedidos TO service_role;

GRANT REFERENCES ON TABLE public.motorista_ordenes_pedidos TO service_role;

GRANT TRIGGER ON TABLE public.motorista_ordenes_pedidos TO service_role;

GRANT MAINTAIN ON TABLE public.motorista_ordenes_pedidos TO service_role;

GRANT SELECT ON SEQUENCE public.deliveryya_codigo_tienda_seq TO postgres;

GRANT UPDATE ON SEQUENCE public.deliveryya_codigo_tienda_seq TO postgres;

GRANT USAGE ON SEQUENCE public.deliveryya_codigo_tienda_seq TO postgres;

GRANT SELECT ON SEQUENCE public.deliveryya_codigo_tienda_seq TO anon;

GRANT UPDATE ON SEQUENCE public.deliveryya_codigo_tienda_seq TO anon;

GRANT USAGE ON SEQUENCE public.deliveryya_codigo_tienda_seq TO anon;

GRANT SELECT ON SEQUENCE public.deliveryya_codigo_tienda_seq TO authenticated;

GRANT UPDATE ON SEQUENCE public.deliveryya_codigo_tienda_seq TO authenticated;

GRANT USAGE ON SEQUENCE public.deliveryya_codigo_tienda_seq TO authenticated;

GRANT SELECT ON SEQUENCE public.deliveryya_codigo_tienda_seq TO service_role;

GRANT UPDATE ON SEQUENCE public.deliveryya_codigo_tienda_seq TO service_role;

GRANT USAGE ON SEQUENCE public.deliveryya_codigo_tienda_seq TO service_role;

GRANT SELECT ON SEQUENCE public.pedidos_ediciones_id_seq TO postgres;

GRANT UPDATE ON SEQUENCE public.pedidos_ediciones_id_seq TO postgres;

GRANT USAGE ON SEQUENCE public.pedidos_ediciones_id_seq TO postgres;

GRANT SELECT ON SEQUENCE public.pedidos_ediciones_id_seq TO anon;

GRANT UPDATE ON SEQUENCE public.pedidos_ediciones_id_seq TO anon;

GRANT USAGE ON SEQUENCE public.pedidos_ediciones_id_seq TO anon;

GRANT SELECT ON SEQUENCE public.pedidos_ediciones_id_seq TO authenticated;

GRANT UPDATE ON SEQUENCE public.pedidos_ediciones_id_seq TO authenticated;

GRANT USAGE ON SEQUENCE public.pedidos_ediciones_id_seq TO authenticated;

GRANT SELECT ON SEQUENCE public.pedidos_ediciones_id_seq TO service_role;

GRANT UPDATE ON SEQUENCE public.pedidos_ediciones_id_seq TO service_role;

GRANT USAGE ON SEQUENCE public.pedidos_ediciones_id_seq TO service_role;

GRANT INSERT ON TABLE public.flota_tienda_propietarias TO postgres;

GRANT SELECT ON TABLE public.flota_tienda_propietarias TO postgres;

GRANT UPDATE ON TABLE public.flota_tienda_propietarias TO postgres;

GRANT DELETE ON TABLE public.flota_tienda_propietarias TO postgres;

GRANT TRUNCATE ON TABLE public.flota_tienda_propietarias TO postgres;

GRANT REFERENCES ON TABLE public.flota_tienda_propietarias TO postgres;

GRANT TRIGGER ON TABLE public.flota_tienda_propietarias TO postgres;

GRANT MAINTAIN ON TABLE public.flota_tienda_propietarias TO postgres;

GRANT INSERT ON TABLE public.flota_tienda_propietarias TO authenticated;

GRANT SELECT ON TABLE public.flota_tienda_propietarias TO authenticated;

GRANT UPDATE ON TABLE public.flota_tienda_propietarias TO authenticated;

GRANT DELETE ON TABLE public.flota_tienda_propietarias TO authenticated;

GRANT TRUNCATE ON TABLE public.flota_tienda_propietarias TO authenticated;

GRANT REFERENCES ON TABLE public.flota_tienda_propietarias TO authenticated;

GRANT TRIGGER ON TABLE public.flota_tienda_propietarias TO authenticated;

GRANT MAINTAIN ON TABLE public.flota_tienda_propietarias TO authenticated;

GRANT INSERT ON TABLE public.flota_tienda_propietarias TO service_role;

GRANT SELECT ON TABLE public.flota_tienda_propietarias TO service_role;

GRANT UPDATE ON TABLE public.flota_tienda_propietarias TO service_role;

GRANT DELETE ON TABLE public.flota_tienda_propietarias TO service_role;

GRANT TRUNCATE ON TABLE public.flota_tienda_propietarias TO service_role;

GRANT REFERENCES ON TABLE public.flota_tienda_propietarias TO service_role;

GRANT TRIGGER ON TABLE public.flota_tienda_propietarias TO service_role;

GRANT MAINTAIN ON TABLE public.flota_tienda_propietarias TO service_role;

GRANT INSERT ON TABLE public.rendiciones TO postgres;

GRANT SELECT ON TABLE public.rendiciones TO postgres;

GRANT UPDATE ON TABLE public.rendiciones TO postgres;

GRANT DELETE ON TABLE public.rendiciones TO postgres;

GRANT TRUNCATE ON TABLE public.rendiciones TO postgres;

GRANT REFERENCES ON TABLE public.rendiciones TO postgres;

GRANT TRIGGER ON TABLE public.rendiciones TO postgres;

GRANT MAINTAIN ON TABLE public.rendiciones TO postgres;

GRANT INSERT ON TABLE public.rendiciones TO authenticated;

GRANT SELECT ON TABLE public.rendiciones TO authenticated;

GRANT UPDATE ON TABLE public.rendiciones TO authenticated;

GRANT DELETE ON TABLE public.rendiciones TO authenticated;

GRANT TRUNCATE ON TABLE public.rendiciones TO authenticated;

GRANT REFERENCES ON TABLE public.rendiciones TO authenticated;

GRANT TRIGGER ON TABLE public.rendiciones TO authenticated;

GRANT MAINTAIN ON TABLE public.rendiciones TO authenticated;

GRANT INSERT ON TABLE public.rendiciones TO service_role;

GRANT SELECT ON TABLE public.rendiciones TO service_role;

GRANT UPDATE ON TABLE public.rendiciones TO service_role;

GRANT DELETE ON TABLE public.rendiciones TO service_role;

GRANT TRUNCATE ON TABLE public.rendiciones TO service_role;

GRANT REFERENCES ON TABLE public.rendiciones TO service_role;

GRANT TRIGGER ON TABLE public.rendiciones TO service_role;

GRANT MAINTAIN ON TABLE public.rendiciones TO service_role;

GRANT INSERT ON TABLE public.tienda_miembros TO postgres;

GRANT SELECT ON TABLE public.tienda_miembros TO postgres;

GRANT UPDATE ON TABLE public.tienda_miembros TO postgres;

GRANT DELETE ON TABLE public.tienda_miembros TO postgres;

GRANT TRUNCATE ON TABLE public.tienda_miembros TO postgres;

GRANT REFERENCES ON TABLE public.tienda_miembros TO postgres;

GRANT TRIGGER ON TABLE public.tienda_miembros TO postgres;

GRANT MAINTAIN ON TABLE public.tienda_miembros TO postgres;

GRANT INSERT ON TABLE public.tienda_miembros TO authenticated;

GRANT SELECT ON TABLE public.tienda_miembros TO authenticated;

GRANT UPDATE ON TABLE public.tienda_miembros TO authenticated;

GRANT DELETE ON TABLE public.tienda_miembros TO authenticated;

GRANT TRUNCATE ON TABLE public.tienda_miembros TO authenticated;

GRANT REFERENCES ON TABLE public.tienda_miembros TO authenticated;

GRANT TRIGGER ON TABLE public.tienda_miembros TO authenticated;

GRANT MAINTAIN ON TABLE public.tienda_miembros TO authenticated;

GRANT INSERT ON TABLE public.tienda_miembros TO service_role;

GRANT SELECT ON TABLE public.tienda_miembros TO service_role;

GRANT UPDATE ON TABLE public.tienda_miembros TO service_role;

GRANT DELETE ON TABLE public.tienda_miembros TO service_role;

GRANT TRUNCATE ON TABLE public.tienda_miembros TO service_role;

GRANT REFERENCES ON TABLE public.tienda_miembros TO service_role;

GRANT TRIGGER ON TABLE public.tienda_miembros TO service_role;

GRANT MAINTAIN ON TABLE public.tienda_miembros TO service_role;

GRANT INSERT ON TABLE public.motoristas TO postgres;

GRANT SELECT ON TABLE public.motoristas TO postgres;

GRANT UPDATE ON TABLE public.motoristas TO postgres;

GRANT DELETE ON TABLE public.motoristas TO postgres;

GRANT TRUNCATE ON TABLE public.motoristas TO postgres;

GRANT REFERENCES ON TABLE public.motoristas TO postgres;

GRANT TRIGGER ON TABLE public.motoristas TO postgres;

GRANT MAINTAIN ON TABLE public.motoristas TO postgres;

GRANT INSERT ON TABLE public.motoristas TO authenticated;

GRANT SELECT ON TABLE public.motoristas TO authenticated;

GRANT UPDATE ON TABLE public.motoristas TO authenticated;

GRANT DELETE ON TABLE public.motoristas TO authenticated;

GRANT TRUNCATE ON TABLE public.motoristas TO authenticated;

GRANT REFERENCES ON TABLE public.motoristas TO authenticated;

GRANT TRIGGER ON TABLE public.motoristas TO authenticated;

GRANT MAINTAIN ON TABLE public.motoristas TO authenticated;

GRANT INSERT ON TABLE public.motoristas TO service_role;

GRANT SELECT ON TABLE public.motoristas TO service_role;

GRANT UPDATE ON TABLE public.motoristas TO service_role;

GRANT DELETE ON TABLE public.motoristas TO service_role;

GRANT TRUNCATE ON TABLE public.motoristas TO service_role;

GRANT REFERENCES ON TABLE public.motoristas TO service_role;

GRANT TRIGGER ON TABLE public.motoristas TO service_role;

GRANT MAINTAIN ON TABLE public.motoristas TO service_role;

GRANT INSERT ON TABLE public.pedidos_ediciones TO postgres;

GRANT SELECT ON TABLE public.pedidos_ediciones TO postgres;

GRANT UPDATE ON TABLE public.pedidos_ediciones TO postgres;

GRANT DELETE ON TABLE public.pedidos_ediciones TO postgres;

GRANT TRUNCATE ON TABLE public.pedidos_ediciones TO postgres;

GRANT REFERENCES ON TABLE public.pedidos_ediciones TO postgres;

GRANT TRIGGER ON TABLE public.pedidos_ediciones TO postgres;

GRANT MAINTAIN ON TABLE public.pedidos_ediciones TO postgres;

GRANT INSERT ON TABLE public.pedidos_ediciones TO service_role;

GRANT SELECT ON TABLE public.pedidos_ediciones TO service_role;

GRANT UPDATE ON TABLE public.pedidos_ediciones TO service_role;

GRANT DELETE ON TABLE public.pedidos_ediciones TO service_role;

GRANT TRUNCATE ON TABLE public.pedidos_ediciones TO service_role;

GRANT REFERENCES ON TABLE public.pedidos_ediciones TO service_role;

GRANT TRIGGER ON TABLE public.pedidos_ediciones TO service_role;

GRANT MAINTAIN ON TABLE public.pedidos_ediciones TO service_role;

GRANT SELECT ON TABLE public.pedidos_ediciones TO authenticated;

GRANT INSERT ON TABLE public.flota_rechazos_detalle TO postgres;

GRANT SELECT ON TABLE public.flota_rechazos_detalle TO postgres;

GRANT UPDATE ON TABLE public.flota_rechazos_detalle TO postgres;

GRANT DELETE ON TABLE public.flota_rechazos_detalle TO postgres;

GRANT TRUNCATE ON TABLE public.flota_rechazos_detalle TO postgres;

GRANT REFERENCES ON TABLE public.flota_rechazos_detalle TO postgres;

GRANT TRIGGER ON TABLE public.flota_rechazos_detalle TO postgres;

GRANT MAINTAIN ON TABLE public.flota_rechazos_detalle TO postgres;

GRANT INSERT ON TABLE public.flota_rechazos_detalle TO authenticated;

GRANT SELECT ON TABLE public.flota_rechazos_detalle TO authenticated;

GRANT UPDATE ON TABLE public.flota_rechazos_detalle TO authenticated;

GRANT DELETE ON TABLE public.flota_rechazos_detalle TO authenticated;

GRANT TRUNCATE ON TABLE public.flota_rechazos_detalle TO authenticated;

GRANT REFERENCES ON TABLE public.flota_rechazos_detalle TO authenticated;

GRANT TRIGGER ON TABLE public.flota_rechazos_detalle TO authenticated;

GRANT MAINTAIN ON TABLE public.flota_rechazos_detalle TO authenticated;

GRANT INSERT ON TABLE public.flota_rechazos_detalle TO service_role;

GRANT SELECT ON TABLE public.flota_rechazos_detalle TO service_role;

GRANT UPDATE ON TABLE public.flota_rechazos_detalle TO service_role;

GRANT DELETE ON TABLE public.flota_rechazos_detalle TO service_role;

GRANT TRUNCATE ON TABLE public.flota_rechazos_detalle TO service_role;

GRANT REFERENCES ON TABLE public.flota_rechazos_detalle TO service_role;

GRANT TRIGGER ON TABLE public.flota_rechazos_detalle TO service_role;

GRANT MAINTAIN ON TABLE public.flota_rechazos_detalle TO service_role;

GRANT INSERT ON TABLE public.vista_cierre_financiero_admin TO postgres;

GRANT SELECT ON TABLE public.vista_cierre_financiero_admin TO postgres;

GRANT UPDATE ON TABLE public.vista_cierre_financiero_admin TO postgres;

GRANT DELETE ON TABLE public.vista_cierre_financiero_admin TO postgres;

GRANT TRUNCATE ON TABLE public.vista_cierre_financiero_admin TO postgres;

GRANT REFERENCES ON TABLE public.vista_cierre_financiero_admin TO postgres;

GRANT TRIGGER ON TABLE public.vista_cierre_financiero_admin TO postgres;

GRANT MAINTAIN ON TABLE public.vista_cierre_financiero_admin TO postgres;

GRANT INSERT ON TABLE public.vista_cierre_financiero_admin TO authenticated;

GRANT SELECT ON TABLE public.vista_cierre_financiero_admin TO authenticated;

GRANT UPDATE ON TABLE public.vista_cierre_financiero_admin TO authenticated;

GRANT DELETE ON TABLE public.vista_cierre_financiero_admin TO authenticated;

GRANT TRUNCATE ON TABLE public.vista_cierre_financiero_admin TO authenticated;

GRANT REFERENCES ON TABLE public.vista_cierre_financiero_admin TO authenticated;

GRANT TRIGGER ON TABLE public.vista_cierre_financiero_admin TO authenticated;

GRANT MAINTAIN ON TABLE public.vista_cierre_financiero_admin TO authenticated;

GRANT INSERT ON TABLE public.vista_cierre_financiero_admin TO service_role;

GRANT SELECT ON TABLE public.vista_cierre_financiero_admin TO service_role;

GRANT UPDATE ON TABLE public.vista_cierre_financiero_admin TO service_role;

GRANT DELETE ON TABLE public.vista_cierre_financiero_admin TO service_role;

GRANT TRUNCATE ON TABLE public.vista_cierre_financiero_admin TO service_role;

GRANT REFERENCES ON TABLE public.vista_cierre_financiero_admin TO service_role;

GRANT TRIGGER ON TABLE public.vista_cierre_financiero_admin TO service_role;

GRANT MAINTAIN ON TABLE public.vista_cierre_financiero_admin TO service_role;

GRANT INSERT ON TABLE public.vista_pedidos_motorista TO postgres;

GRANT SELECT ON TABLE public.vista_pedidos_motorista TO postgres;

GRANT UPDATE ON TABLE public.vista_pedidos_motorista TO postgres;

GRANT DELETE ON TABLE public.vista_pedidos_motorista TO postgres;

GRANT TRUNCATE ON TABLE public.vista_pedidos_motorista TO postgres;

GRANT REFERENCES ON TABLE public.vista_pedidos_motorista TO postgres;

GRANT TRIGGER ON TABLE public.vista_pedidos_motorista TO postgres;

GRANT MAINTAIN ON TABLE public.vista_pedidos_motorista TO postgres;

GRANT INSERT ON TABLE public.vista_pedidos_motorista TO authenticated;

GRANT SELECT ON TABLE public.vista_pedidos_motorista TO authenticated;

GRANT UPDATE ON TABLE public.vista_pedidos_motorista TO authenticated;

GRANT DELETE ON TABLE public.vista_pedidos_motorista TO authenticated;

GRANT TRUNCATE ON TABLE public.vista_pedidos_motorista TO authenticated;

GRANT REFERENCES ON TABLE public.vista_pedidos_motorista TO authenticated;

GRANT TRIGGER ON TABLE public.vista_pedidos_motorista TO authenticated;

GRANT MAINTAIN ON TABLE public.vista_pedidos_motorista TO authenticated;

GRANT INSERT ON TABLE public.vista_pedidos_motorista TO service_role;

GRANT SELECT ON TABLE public.vista_pedidos_motorista TO service_role;

GRANT UPDATE ON TABLE public.vista_pedidos_motorista TO service_role;

GRANT DELETE ON TABLE public.vista_pedidos_motorista TO service_role;

GRANT TRUNCATE ON TABLE public.vista_pedidos_motorista TO service_role;

GRANT REFERENCES ON TABLE public.vista_pedidos_motorista TO service_role;

GRANT TRIGGER ON TABLE public.vista_pedidos_motorista TO service_role;

GRANT MAINTAIN ON TABLE public.vista_pedidos_motorista TO service_role;

GRANT INSERT ON TABLE public.pedidos TO postgres;

GRANT SELECT ON TABLE public.pedidos TO postgres;

GRANT UPDATE ON TABLE public.pedidos TO postgres;

GRANT DELETE ON TABLE public.pedidos TO postgres;

GRANT TRUNCATE ON TABLE public.pedidos TO postgres;

GRANT REFERENCES ON TABLE public.pedidos TO postgres;

GRANT TRIGGER ON TABLE public.pedidos TO postgres;

GRANT MAINTAIN ON TABLE public.pedidos TO postgres;

GRANT INSERT ON TABLE public.pedidos TO authenticated;

GRANT SELECT ON TABLE public.pedidos TO authenticated;

GRANT UPDATE ON TABLE public.pedidos TO authenticated;

GRANT DELETE ON TABLE public.pedidos TO authenticated;

GRANT TRUNCATE ON TABLE public.pedidos TO authenticated;

GRANT REFERENCES ON TABLE public.pedidos TO authenticated;

GRANT TRIGGER ON TABLE public.pedidos TO authenticated;

GRANT MAINTAIN ON TABLE public.pedidos TO authenticated;

GRANT INSERT ON TABLE public.pedidos TO service_role;

GRANT SELECT ON TABLE public.pedidos TO service_role;

GRANT UPDATE ON TABLE public.pedidos TO service_role;

GRANT DELETE ON TABLE public.pedidos TO service_role;

GRANT TRUNCATE ON TABLE public.pedidos TO service_role;

GRANT REFERENCES ON TABLE public.pedidos TO service_role;

GRANT TRIGGER ON TABLE public.pedidos TO service_role;

GRANT MAINTAIN ON TABLE public.pedidos TO service_role;

GRANT INSERT ON TABLE public.flota_cupo_optimizacion_google TO postgres;

GRANT SELECT ON TABLE public.flota_cupo_optimizacion_google TO postgres;

GRANT UPDATE ON TABLE public.flota_cupo_optimizacion_google TO postgres;

GRANT DELETE ON TABLE public.flota_cupo_optimizacion_google TO postgres;

GRANT TRUNCATE ON TABLE public.flota_cupo_optimizacion_google TO postgres;

GRANT REFERENCES ON TABLE public.flota_cupo_optimizacion_google TO postgres;

GRANT TRIGGER ON TABLE public.flota_cupo_optimizacion_google TO postgres;

GRANT MAINTAIN ON TABLE public.flota_cupo_optimizacion_google TO postgres;

GRANT INSERT ON TABLE public.flota_cupo_optimizacion_google TO service_role;

GRANT SELECT ON TABLE public.flota_cupo_optimizacion_google TO service_role;

GRANT UPDATE ON TABLE public.flota_cupo_optimizacion_google TO service_role;

GRANT DELETE ON TABLE public.flota_cupo_optimizacion_google TO service_role;

GRANT TRUNCATE ON TABLE public.flota_cupo_optimizacion_google TO service_role;

GRANT REFERENCES ON TABLE public.flota_cupo_optimizacion_google TO service_role;

GRANT TRIGGER ON TABLE public.flota_cupo_optimizacion_google TO service_role;

GRANT MAINTAIN ON TABLE public.flota_cupo_optimizacion_google TO service_role;

GRANT INSERT ON TABLE public.motorista_recorridos_confirmados TO postgres;

GRANT SELECT ON TABLE public.motorista_recorridos_confirmados TO postgres;

GRANT UPDATE ON TABLE public.motorista_recorridos_confirmados TO postgres;

GRANT DELETE ON TABLE public.motorista_recorridos_confirmados TO postgres;

GRANT TRUNCATE ON TABLE public.motorista_recorridos_confirmados TO postgres;

GRANT REFERENCES ON TABLE public.motorista_recorridos_confirmados TO postgres;

GRANT TRIGGER ON TABLE public.motorista_recorridos_confirmados TO postgres;

GRANT MAINTAIN ON TABLE public.motorista_recorridos_confirmados TO postgres;

GRANT INSERT ON TABLE public.motorista_recorridos_confirmados TO service_role;

GRANT SELECT ON TABLE public.motorista_recorridos_confirmados TO service_role;

GRANT UPDATE ON TABLE public.motorista_recorridos_confirmados TO service_role;

GRANT DELETE ON TABLE public.motorista_recorridos_confirmados TO service_role;

GRANT TRUNCATE ON TABLE public.motorista_recorridos_confirmados TO service_role;

GRANT REFERENCES ON TABLE public.motorista_recorridos_confirmados TO service_role;

GRANT TRIGGER ON TABLE public.motorista_recorridos_confirmados TO service_role;

GRANT MAINTAIN ON TABLE public.motorista_recorridos_confirmados TO service_role;

GRANT INSERT ON TABLE public.flota_compensaciones_tienda TO postgres;

GRANT SELECT ON TABLE public.flota_compensaciones_tienda TO postgres;

GRANT UPDATE ON TABLE public.flota_compensaciones_tienda TO postgres;

GRANT DELETE ON TABLE public.flota_compensaciones_tienda TO postgres;

GRANT TRUNCATE ON TABLE public.flota_compensaciones_tienda TO postgres;

GRANT REFERENCES ON TABLE public.flota_compensaciones_tienda TO postgres;

GRANT TRIGGER ON TABLE public.flota_compensaciones_tienda TO postgres;

GRANT MAINTAIN ON TABLE public.flota_compensaciones_tienda TO postgres;

GRANT INSERT ON TABLE public.flota_compensaciones_tienda TO service_role;

GRANT SELECT ON TABLE public.flota_compensaciones_tienda TO service_role;

GRANT UPDATE ON TABLE public.flota_compensaciones_tienda TO service_role;

GRANT DELETE ON TABLE public.flota_compensaciones_tienda TO service_role;

GRANT TRUNCATE ON TABLE public.flota_compensaciones_tienda TO service_role;

GRANT REFERENCES ON TABLE public.flota_compensaciones_tienda TO service_role;

GRANT TRIGGER ON TABLE public.flota_compensaciones_tienda TO service_role;

GRANT MAINTAIN ON TABLE public.flota_compensaciones_tienda TO service_role;

GRANT INSERT ON TABLE public.flota_pagos_tienda TO postgres;

GRANT SELECT ON TABLE public.flota_pagos_tienda TO postgres;

GRANT UPDATE ON TABLE public.flota_pagos_tienda TO postgres;

GRANT DELETE ON TABLE public.flota_pagos_tienda TO postgres;

GRANT TRUNCATE ON TABLE public.flota_pagos_tienda TO postgres;

GRANT REFERENCES ON TABLE public.flota_pagos_tienda TO postgres;

GRANT TRIGGER ON TABLE public.flota_pagos_tienda TO postgres;

GRANT MAINTAIN ON TABLE public.flota_pagos_tienda TO postgres;

GRANT INSERT ON TABLE public.flota_pagos_tienda TO service_role;

GRANT SELECT ON TABLE public.flota_pagos_tienda TO service_role;

GRANT UPDATE ON TABLE public.flota_pagos_tienda TO service_role;

GRANT DELETE ON TABLE public.flota_pagos_tienda TO service_role;

GRANT TRUNCATE ON TABLE public.flota_pagos_tienda TO service_role;

GRANT REFERENCES ON TABLE public.flota_pagos_tienda TO service_role;

GRANT TRIGGER ON TABLE public.flota_pagos_tienda TO service_role;

GRANT MAINTAIN ON TABLE public.flota_pagos_tienda TO service_role;

-- fg

GRANT EXECUTE ON FUNCTION aceptar_invitacion_tienda(text) TO postgres;

GRANT EXECUTE ON FUNCTION aceptar_invitacion_tienda(text) TO authenticated;

GRANT EXECUTE ON FUNCTION aceptar_invitacion_tienda(text) TO service_role;

GRANT EXECUTE ON FUNCTION admin_confirmar_ruta_optimizada(uuid,uuid[]) TO postgres;

GRANT EXECUTE ON FUNCTION admin_confirmar_ruta_optimizada(uuid,uuid[]) TO authenticated;

GRANT EXECUTE ON FUNCTION admin_confirmar_ruta_optimizada(uuid,uuid[]) TO service_role;

GRANT EXECUTE ON FUNCTION crear_invitacion_tienda(uuid,integer) TO postgres;

GRANT EXECUTE ON FUNCTION crear_invitacion_tienda(uuid,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION crear_invitacion_tienda(uuid,integer) TO service_role;

GRANT EXECUTE ON FUNCTION deliveryya_asignar_codigo_tienda() TO postgres;

GRANT EXECUTE ON FUNCTION deliveryya_asignar_codigo_tienda() TO service_role;

GRANT EXECUTE ON FUNCTION deliveryya_fijar_autor_pedido() TO postgres;

GRANT EXECUTE ON FUNCTION deliveryya_fijar_autor_pedido() TO service_role;

GRANT EXECUTE ON FUNCTION deliveryya_propietario_membresia() TO postgres;

GRANT EXECUTE ON FUNCTION deliveryya_propietario_membresia() TO service_role;

GRANT EXECUTE ON FUNCTION editar_pedido_seguro(uuid,integer,jsonb) TO postgres;

GRANT EXECUTE ON FUNCTION editar_pedido_seguro(uuid,integer,jsonb) TO authenticated;

GRANT EXECUTE ON FUNCTION editar_pedido_seguro(uuid,integer,jsonb) TO service_role;

GRANT EXECUTE ON FUNCTION flota_aceptar_invitacion(text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_aceptar_invitacion(text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_aceptar_invitacion(text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_aceptar_tienda_propietaria(text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_aceptar_tienda_propietaria(text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_aceptar_tienda_propietaria(text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_anexar_pedidos_a_ruta(uuid,uuid[]) TO postgres;

GRANT EXECUTE ON FUNCTION flota_anexar_pedidos_a_ruta(uuid,uuid[]) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_anexar_pedidos_a_ruta(uuid,uuid[]) TO service_role;

GRANT EXECUTE ON FUNCTION flota_asignar_lote(uuid[],uuid) TO postgres;

GRANT EXECUTE ON FUNCTION flota_asignar_lote(uuid[],uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_asignar_lote(uuid[],uuid) TO service_role;

GRANT EXECUTE ON FUNCTION flota_asignar_pedidos_rapido(uuid[],uuid,date,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_asignar_pedidos_rapido(uuid[],uuid,date,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_asignar_pedidos_rapido(uuid[],uuid,date,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_boom_tarifa_minima_v1() TO PUBLIC;

GRANT EXECUTE ON FUNCTION flota_boom_tarifa_minima_v1() TO postgres;

GRANT EXECUTE ON FUNCTION flota_boom_tarifa_minima_v1() TO anon;

GRANT EXECUTE ON FUNCTION flota_boom_tarifa_minima_v1() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_boom_tarifa_minima_v1() TO service_role;

GRANT EXECUTE ON FUNCTION flota_cambiar_turno_pedido(uuid,text,integer) TO postgres;

GRANT EXECUTE ON FUNCTION flota_cambiar_turno_pedido(uuid,text,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_cambiar_turno_pedido(uuid,text,integer) TO service_role;

GRANT EXECUTE ON FUNCTION flota_cerrar_ruta(uuid) TO postgres;

GRANT EXECUTE ON FUNCTION flota_cerrar_ruta(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_cerrar_ruta(uuid) TO service_role;

GRANT EXECUTE ON FUNCTION flota_compensar_rechazo_en_rendicion(uuid,date,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_compensar_rechazo_en_rendicion(uuid,date,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_compensar_rechazo_en_rendicion(uuid,date,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_configurar_comision_general(uuid,integer) TO postgres;

GRANT EXECUTE ON FUNCTION flota_configurar_comision_general(uuid,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_configurar_comision_general(uuid,integer) TO service_role;

GRANT EXECUTE ON FUNCTION flota_configurar_comision_motorista(uuid,integer,boolean) TO postgres;

GRANT EXECUTE ON FUNCTION flota_configurar_comision_motorista(uuid,integer,boolean) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_configurar_comision_motorista(uuid,integer,boolean) TO service_role;

GRANT EXECUTE ON FUNCTION flota_confirmar_cierre_completo(uuid,integer,integer) TO postgres;

GRANT EXECUTE ON FUNCTION flota_confirmar_cierre_completo(uuid,integer,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_confirmar_cierre_completo(uuid,integer,integer) TO service_role;

GRANT EXECUTE ON FUNCTION flota_confirmar_compensacion_tienda(uuid,date,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_confirmar_compensacion_tienda(uuid,date,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_confirmar_compensacion_tienda(uuid,date,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_crear_invitacion(uuid,text,text,text,text,boolean,boolean,boolean,boolean,boolean) TO postgres;

GRANT EXECUTE ON FUNCTION flota_crear_invitacion(uuid,text,text,text,text,boolean,boolean,boolean,boolean,boolean) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_crear_invitacion(uuid,text,text,text,text,boolean,boolean,boolean,boolean,boolean) TO service_role;

GRANT EXECUTE ON FUNCTION flota_crear_ruta_turno(date,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_crear_ruta_turno(date,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_crear_ruta_turno(date,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_editar_motorista(uuid,text,text,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_editar_motorista(uuid,text,text,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_editar_motorista(uuid,text,text,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_fijar_colaboradores_sin_comision_v1() TO PUBLIC;

GRANT EXECUTE ON FUNCTION flota_fijar_colaboradores_sin_comision_v1() TO postgres;

GRANT EXECUTE ON FUNCTION flota_fijar_colaboradores_sin_comision_v1() TO anon;

GRANT EXECUTE ON FUNCTION flota_fijar_colaboradores_sin_comision_v1() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_fijar_colaboradores_sin_comision_v1() TO service_role;

GRANT EXECUTE ON FUNCTION flota_fijar_pct_pedido_colaborador_v1() TO PUBLIC;

GRANT EXECUTE ON FUNCTION flota_fijar_pct_pedido_colaborador_v1() TO postgres;

GRANT EXECUTE ON FUNCTION flota_fijar_pct_pedido_colaborador_v1() TO anon;

GRANT EXECUTE ON FUNCTION flota_fijar_pct_pedido_colaborador_v1() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_fijar_pct_pedido_colaborador_v1() TO service_role;

GRANT EXECUTE ON FUNCTION flota_historial_reprogramados_fecha(date) TO postgres;

GRANT EXECUTE ON FUNCTION flota_historial_reprogramados_fecha(date) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_historial_reprogramados_fecha(date) TO service_role;

GRANT EXECUTE ON FUNCTION flota_impedir_cobros_con_caja_presentada() TO postgres;

GRANT EXECUTE ON FUNCTION flota_impedir_cobros_con_caja_presentada() TO service_role;

GRANT EXECUTE ON FUNCTION flota_invitar_motorista(uuid) TO postgres;

GRANT EXECUTE ON FUNCTION flota_invitar_motorista(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_invitar_motorista(uuid) TO service_role;

GRANT EXECUTE ON FUNCTION flota_leer_comision_general(uuid) TO postgres;

GRANT EXECUTE ON FUNCTION flota_leer_comision_general(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_leer_comision_general(uuid) TO service_role;

GRANT EXECUTE ON FUNCTION flota_liberar_pedido_futuro_seguro(uuid,integer,date) TO postgres;

GRANT EXECUTE ON FUNCTION flota_liberar_pedido_futuro_seguro(uuid,integer,date) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_liberar_pedido_futuro_seguro(uuid,integer,date) TO service_role;

GRANT EXECUTE ON FUNCTION flota_liberar_pedidos_seguros(uuid[],jsonb,date,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_liberar_pedidos_seguros(uuid[],jsonb,date,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_liberar_pedidos_seguros(uuid[],jsonb,date,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_mis_solicitudes_tienda() TO postgres;

GRANT EXECUTE ON FUNCTION flota_mis_solicitudes_tienda() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_mis_solicitudes_tienda() TO service_role;

GRANT EXECUTE ON FUNCTION flota_ordenes_motoristas_fecha(date) TO postgres;

GRANT EXECUTE ON FUNCTION flota_ordenes_motoristas_fecha(date) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_ordenes_motoristas_fecha(date) TO service_role;

GRANT EXECUTE ON FUNCTION flota_pasar_pedidos_manana_central(uuid[],jsonb,date) TO postgres;

GRANT EXECUTE ON FUNCTION flota_pasar_pedidos_manana_central(uuid[],jsonb,date) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_pasar_pedidos_manana_central(uuid[],jsonb,date) TO service_role;

GRANT EXECUTE ON FUNCTION flota_proteger_persa_interna_v1() TO PUBLIC;

GRANT EXECUTE ON FUNCTION flota_proteger_persa_interna_v1() TO postgres;

GRANT EXECUTE ON FUNCTION flota_proteger_persa_interna_v1() TO anon;

GRANT EXECUTE ON FUNCTION flota_proteger_persa_interna_v1() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_proteger_persa_interna_v1() TO service_role;

GRANT EXECUTE ON FUNCTION flota_puede_leer(uuid) TO postgres;

GRANT EXECUTE ON FUNCTION flota_puede_leer(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_puede_leer(uuid) TO service_role;

GRANT EXECUTE ON FUNCTION flota_quitar_pedidos_ruta_seguros(uuid[],jsonb,date) TO postgres;

GRANT EXECUTE ON FUNCTION flota_quitar_pedidos_ruta_seguros(uuid[],jsonb,date) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_quitar_pedidos_ruta_seguros(uuid[],jsonb,date) TO service_role;

GRANT EXECUTE ON FUNCTION flota_reasignar_lote_seguro(uuid[],uuid,jsonb) TO postgres;

GRANT EXECUTE ON FUNCTION flota_reasignar_lote_seguro(uuid[],uuid,jsonb) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_reasignar_lote_seguro(uuid[],uuid,jsonb) TO service_role;

GRANT EXECUTE ON FUNCTION flota_reasignar_pedido_seguro(uuid,uuid,integer) TO postgres;

GRANT EXECUTE ON FUNCTION flota_reasignar_pedido_seguro(uuid,uuid,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_reasignar_pedido_seguro(uuid,uuid,integer) TO service_role;

GRANT EXECUTE ON FUNCTION flota_reclamar_propiedad() TO postgres;

GRANT EXECUTE ON FUNCTION flota_reclamar_propiedad() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_reclamar_propiedad() TO service_role;

GRANT EXECUTE ON FUNCTION flota_recorridos_confirmados_fecha(date) TO postgres;

GRANT EXECUTE ON FUNCTION flota_recorridos_confirmados_fecha(date) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_recorridos_confirmados_fecha(date) TO service_role;

GRANT EXECUTE ON FUNCTION flota_registrar_motorista(uuid,text,text,text,text,integer) TO postgres;

GRANT EXECUTE ON FUNCTION flota_registrar_motorista(uuid,text,text,text,text,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_registrar_motorista(uuid,text,text,text,text,integer) TO service_role;

GRANT EXECUTE ON FUNCTION flota_registrar_pago_tienda(uuid,date,integer,text,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_registrar_pago_tienda(uuid,date,integer,text,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_registrar_pago_tienda(uuid,date,integer,text,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_registrar_tienda(uuid,text,text,text,text,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_registrar_tienda(uuid,text,text,text,text,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_registrar_tienda(uuid,text,text,text,text,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_renovar_invitacion_tienda(uuid) TO postgres;

GRANT EXECUTE ON FUNCTION flota_renovar_invitacion_tienda(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_renovar_invitacion_tienda(uuid) TO service_role;

GRANT EXECUTE ON FUNCTION flota_reorganizar_pendientes_heredados(date,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_reorganizar_pendientes_heredados(date,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_reorganizar_pendientes_heredados(date,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_reprogramar_asignar_historico(uuid[],uuid,date,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_reprogramar_asignar_historico(uuid[],uuid,date,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_reprogramar_asignar_historico(uuid[],uuid,date,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_reprogramar_pedidos_asignados(uuid[],uuid,date,text,jsonb) TO postgres;

GRANT EXECUTE ON FUNCTION flota_reprogramar_pedidos_asignados(uuid[],uuid,date,text,jsonb) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_reprogramar_pedidos_asignados(uuid[],uuid,date,text,jsonb) TO service_role;

GRANT EXECUTE ON FUNCTION flota_reservar_optimizacion_google() TO postgres;

GRANT EXECUTE ON FUNCTION flota_reservar_optimizacion_google() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_reservar_optimizacion_google() TO service_role;

GRANT EXECUTE ON FUNCTION flota_resumen_ajustes_tienda(date) TO postgres;

GRANT EXECUTE ON FUNCTION flota_resumen_ajustes_tienda(date) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_resumen_ajustes_tienda(date) TO service_role;

GRANT EXECUTE ON FUNCTION flota_revisar_solicitud_tienda(uuid,boolean) TO postgres;

GRANT EXECUTE ON FUNCTION flota_revisar_solicitud_tienda(uuid,boolean) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_revisar_solicitud_tienda(uuid,boolean) TO service_role;

GRANT EXECUTE ON FUNCTION flota_revocar_usuario(uuid,uuid) TO postgres;

GRANT EXECUTE ON FUNCTION flota_revocar_usuario(uuid,uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_revocar_usuario(uuid,uuid) TO service_role;

GRANT EXECUTE ON FUNCTION flota_saldos_rechazos_por_tienda() TO postgres;

GRANT EXECUTE ON FUNCTION flota_saldos_rechazos_por_tienda() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_saldos_rechazos_por_tienda() TO service_role;

GRANT EXECUTE ON FUNCTION flota_solicitar_alta_tienda(text,text,text,text) TO postgres;

GRANT EXECUTE ON FUNCTION flota_solicitar_alta_tienda(text,text,text,text) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_solicitar_alta_tienda(text,text,text,text) TO service_role;

GRANT EXECUTE ON FUNCTION flota_solicitar_alta_tienda_simple() TO postgres;

GRANT EXECUTE ON FUNCTION flota_solicitar_alta_tienda_simple() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_solicitar_alta_tienda_simple() TO service_role;

GRANT EXECUTE ON FUNCTION flota_solicitudes_tienda_pendientes() TO postgres;

GRANT EXECUTE ON FUNCTION flota_solicitudes_tienda_pendientes() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_solicitudes_tienda_pendientes() TO service_role;

GRANT EXECUTE ON FUNCTION flota_tarifas_vigentes(uuid) TO postgres;

GRANT EXECUTE ON FUNCTION flota_tarifas_vigentes(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_tarifas_vigentes(uuid) TO service_role;

GRANT EXECUTE ON FUNCTION flota_usuarios_listar(uuid) TO postgres;

GRANT EXECUTE ON FUNCTION flota_usuarios_listar(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION flota_usuarios_listar(uuid) TO service_role;

GRANT EXECUTE ON FUNCTION flota_validar_origen_tarifa_pedido() TO PUBLIC;

GRANT EXECUTE ON FUNCTION flota_validar_origen_tarifa_pedido() TO postgres;

GRANT EXECUTE ON FUNCTION flota_validar_origen_tarifa_pedido() TO anon;

GRANT EXECUTE ON FUNCTION flota_validar_origen_tarifa_pedido() TO authenticated;

GRANT EXECUTE ON FUNCTION flota_validar_origen_tarifa_pedido() TO service_role;

GRANT EXECUTE ON FUNCTION listar_empleadas_tienda(uuid) TO postgres;

GRANT EXECUTE ON FUNCTION listar_empleadas_tienda(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION listar_empleadas_tienda(uuid) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_aceptar_invitacion(text) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_aceptar_invitacion(text) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_aceptar_invitacion(text) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_actualizar_estado_pedido(uuid,uuid,text,text,text) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_actualizar_estado_pedido(uuid,uuid,text,text,text) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_actualizar_estado_pedido(uuid,uuid,text,text,text) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_cerrar_entrega(uuid,text,text,text) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_cerrar_entrega(uuid,text,text,text) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_cerrar_entrega(uuid,text,text,text) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_compartir_gps(double precision,double precision,numeric) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_compartir_gps(double precision,double precision,numeric) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_compartir_gps(double precision,double precision,numeric) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_contacto_jefe() TO postgres;

GRANT EXECUTE ON FUNCTION motorista_contacto_jefe() TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_contacto_jefe() TO service_role;

GRANT EXECUTE ON FUNCTION motorista_corregir_cierre(date,integer,integer) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_corregir_cierre(date,integer,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_corregir_cierre(date,integer,integer) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_corregir_pedido(uuid,integer,jsonb,boolean) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_corregir_pedido(uuid,integer,jsonb,boolean) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_corregir_pedido(uuid,integer,jsonb,boolean) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_deshacer_no_me_fui(uuid,integer) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_deshacer_no_me_fui(uuid,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_deshacer_no_me_fui(uuid,integer) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_guardar_orden(uuid[]) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_guardar_orden(uuid[]) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_guardar_orden(uuid[]) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_guardar_recorrido(uuid[],jsonb,double precision,double precision) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_guardar_recorrido(uuid[],jsonb,double precision,double precision) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_guardar_recorrido(uuid[],jsonb,double precision,double precision) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_marcar_no_me_fui(uuid,integer,text) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_marcar_no_me_fui(uuid,integer,text) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_marcar_no_me_fui(uuid,integer,text) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_mis_ganancias_por_fecha(date) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_mis_ganancias_por_fecha(date) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_mis_ganancias_por_fecha(date) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_mis_tiendas() TO postgres;

GRANT EXECUTE ON FUNCTION motorista_mis_tiendas() TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_mis_tiendas() TO service_role;

GRANT EXECUTE ON FUNCTION motorista_pasar_pedido_manana(uuid,text,integer) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_pasar_pedido_manana(uuid,text,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_pasar_pedido_manana(uuid,text,integer) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_presentar_cierre(date,integer,integer) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_presentar_cierre(date,integer,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_presentar_cierre(date,integer,integer) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_recorrido_actual() TO postgres;

GRANT EXECUTE ON FUNCTION motorista_recorrido_actual() TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_recorrido_actual() TO service_role;

GRANT EXECUTE ON FUNCTION motorista_registrar_entrega_anterior(uuid,date,text,integer) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_registrar_entrega_anterior(uuid,date,text,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_registrar_entrega_anterior(uuid,date,text,integer) TO service_role;

GRANT EXECUTE ON FUNCTION motorista_registrar_rechazo_detallado(uuid,text,text,integer,text) TO postgres;

GRANT EXECUTE ON FUNCTION motorista_registrar_rechazo_detallado(uuid,text,text,integer,text) TO authenticated;

GRANT EXECUTE ON FUNCTION motorista_registrar_rechazo_detallado(uuid,text,text,integer,text) TO service_role;

GRANT EXECUTE ON FUNCTION provisionar_tienda_v2() TO postgres;

GRANT EXECUTE ON FUNCTION provisionar_tienda_v2() TO service_role;

GRANT EXECUTE ON FUNCTION registrar_movimiento_financiero() TO postgres;

GRANT EXECUTE ON FUNCTION registrar_movimiento_financiero() TO service_role;

GRANT EXECUTE ON FUNCTION revocar_empleado_tienda(uuid,uuid) TO postgres;

GRANT EXECUTE ON FUNCTION revocar_empleado_tienda(uuid,uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION revocar_empleado_tienda(uuid,uuid) TO service_role;

GRANT EXECUTE ON FUNCTION tienda_actualizar_configuracion(text,text,text) TO postgres;

GRANT EXECUTE ON FUNCTION tienda_actualizar_configuracion(text,text,text) TO authenticated;

GRANT EXECUTE ON FUNCTION tienda_actualizar_configuracion(text,text,text) TO service_role;

GRANT EXECUTE ON FUNCTION tienda_actualizar_configuracion_gps(text,text,text,double precision,double precision) TO postgres;

GRANT EXECUTE ON FUNCTION tienda_actualizar_configuracion_gps(text,text,text,double precision,double precision) TO authenticated;

GRANT EXECUTE ON FUNCTION tienda_actualizar_configuracion_gps(text,text,text,double precision,double precision) TO service_role;

GRANT EXECUTE ON FUNCTION tienda_agregar_pedido_a_ruta(uuid,text) TO postgres;

GRANT EXECUTE ON FUNCTION tienda_agregar_pedido_a_ruta(uuid,text) TO authenticated;

GRANT EXECUTE ON FUNCTION tienda_agregar_pedido_a_ruta(uuid,text) TO service_role;

GRANT EXECUTE ON FUNCTION tienda_cancelar_pedido_seguro(uuid,integer) TO postgres;

GRANT EXECUTE ON FUNCTION tienda_cancelar_pedido_seguro(uuid,integer) TO authenticated;

GRANT EXECUTE ON FUNCTION tienda_cancelar_pedido_seguro(uuid,integer) TO service_role;
