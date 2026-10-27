-- ==============================================================================
-- IRON PULSE - CORRECCIÓN DE TRIGGER: ASIGNACIÓN AUTOMÁTICA DEL ROL CLIENTE
-- ==============================================================================
-- Este script soluciona el error:
-- {"code":"unexpected_failure","message":"Database error saving new user"}
--
-- Causa: En Supabase, el trigger que se dispara al registrar un usuario en
-- auth.users se ejecuta con el rol supabase_auth_admin sin el search_path de
-- 'public', lo que causaba que fallara al buscar el tipo user_role o la tabla profiles.
-- Con este script se define search_path explícito y protección contra excepciones.

-- 1. Desconectar temporalmente el trigger previo
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Asegurar tipo user_role
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE public.user_role AS ENUM ('admin', 'client');
  END IF;
END $$;

-- 3. Asegurar la tabla profiles y la columna role
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  avatar_url TEXT,
  role public.user_role DEFAULT 'client'::public.user_role,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, now())
);

-- Si la columna role ya existía con otro tipo o sin default, asegurar el default
DO $$ 
BEGIN
  BEGIN
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role public.user_role DEFAULT 'client'::public.user_role;
    ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'client'::public.user_role;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
END $$;

-- 4. Función del trigger blindada con search_path y manejo de excepciones
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1), 'Atleta'),
    COALESCE(new.raw_user_meta_data->>'avatar_url', ''),
    'client'::public.user_role
  )
  ON CONFLICT (id) DO UPDATE
    SET full_name = COALESCE(public.profiles.full_name, EXCLUDED.full_name),
        role = COALESCE(public.profiles.role, 'client'::public.user_role),
        updated_at = timezone('utc'::TEXT, now());

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Blindaje: bajo ninguna circunstancia este trigger debe abortar el registro en auth.users
  RAISE WARNING 'handle_new_user exception: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- 5. Crear el trigger AFTER INSERT en auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Habilitar RLS y Políticas de acceso en profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios pueden leer perfiles" ON public.profiles;
CREATE POLICY "Usuarios pueden leer perfiles" ON public.profiles 
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Usuarios pueden insertar su propio perfil" ON public.profiles;
CREATE POLICY "Usuarios pueden insertar su propio perfil" ON public.profiles 
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Usuarios pueden editar su propio perfil" ON public.profiles;
CREATE POLICY "Usuarios pueden editar su propio perfil" ON public.profiles 
  FOR UPDATE TO authenticated USING (auth.uid() = id);
