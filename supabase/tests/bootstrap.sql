create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";
create schema if not exists extensions;
create or replace function extensions.gen_random_bytes(int) returns bytea language sql as $$select public.gen_random_bytes($1)$$;
create or replace function extensions.uuid_generate_v4() returns uuid language sql as $$select public.uuid_generate_v4()$$;
do $$begin
 if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
 if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
 if not exists(select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
end$$;
create schema if not exists auth;
create table if not exists auth.users(id uuid primary key default gen_random_uuid(), email text unique, raw_user_meta_data jsonb default '{}', email_confirmed_at timestamptz default now(), created_at timestamptz default now());
create or replace function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create or replace function auth.role() returns text language sql stable as $$select coalesce(nullif(current_setting('request.jwt.claim.role',true),''),'anon')$$;
create or replace function auth.email() returns text language sql stable as $$select email from auth.users where id=auth.uid()$$;
create or replace function auth.jwt() returns jsonb language sql stable as $$select jsonb_build_object('sub',auth.uid(),'email',auth.email())$$;
grant usage on schema public, auth, extensions to anon, authenticated, service_role;
grant execute on all functions in schema auth to anon, authenticated;
