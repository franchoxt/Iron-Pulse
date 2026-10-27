-- ==============================================================================
-- IRON PULSE - ESQUEMA DE BASE DE DATOS SUPABASE
-- Basado en: .agents/rules/tablas-supabase.md
-- ==============================================================================

-- 1. EXTENSIONES Y TIPOS PERSONALIZADOS
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('admin', 'client');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
    CREATE TYPE booking_status AS ENUM ('confirmed', 'waitlist', 'cancelled');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'class_intensity') THEN
    CREATE TYPE class_intensity AS ENUM ('Low', 'Medium', 'High');
  END IF;
END $$;

-- 2. TABLA DE PERFILES (Extiende auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  avatar_url TEXT,
  role user_role DEFAULT 'client'::user_role,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, now())
);

-- 3. CATEGORÍAS DE CLASES (Cardio, Strength, Yoga, etc.)
CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  icon_url TEXT
);

-- 4. INSTRUCTORES
CREATE TABLE IF NOT EXISTS instructors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  rating NUMERIC(3,2) DEFAULT 5.0
);

-- 5. CLASES (El "molde" de la clase)
CREATE TABLE IF NOT EXISTS classes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  intensity class_intensity DEFAULT 'Medium',
  duration_minutes INTEGER NOT NULL,
  base_price NUMERIC(10,2) DEFAULT 0.00
);

-- 6. HORARIOS / SESIONES (Instancias específicas de una clase)
CREATE TABLE IF NOT EXISTS class_schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES instructors(id) ON DELETE SET NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  capacity INTEGER NOT NULL,
  location_name TEXT,
  is_live BOOLEAN DEFAULT false
);

-- 7. RESERVAS (Unión entre Usuarios y Sesiones)
CREATE TABLE IF NOT EXISTS bookings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  schedule_id UUID REFERENCES class_schedules(id) ON DELETE CASCADE,
  status booking_status DEFAULT 'confirmed',
  is_present BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, now()),
  UNIQUE(user_id, schedule_id)
);

-- 8. COMUNICACIONES / MENSAJES
CREATE TABLE IF NOT EXISTS messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  subject TEXT,
  content TEXT,
  is_read BOOLEAN DEFAULT false,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, now())
);

-- ==============================================================================
-- TRIGGER PARA CREAR PERFIL AUTOMÁTICAMENTE AL REGISTRARSE
-- Asigna automáticamente el rol de cliente ('client') en la base de datos
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  assigned_role public.user_role;
BEGIN
  -- Extraer rol de metadata si viene especificado, o asignar 'client' por defecto
  BEGIN
    assigned_role := COALESCE(
      (new.raw_user_meta_data->>'role')::public.user_role,
      'client'::public.user_role
    );
  EXCEPTION WHEN OTHERS THEN
    assigned_role := 'client'::public.user_role;
  END;

  INSERT INTO public.profiles (id, full_name, avatar_url, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    COALESCE(new.raw_user_meta_data->>'avatar_url', ''),
    assigned_role
  )
  ON CONFLICT (id) DO UPDATE
    SET full_name = COALESCE(public.profiles.full_name, EXCLUDED.full_name),
        role = COALESCE(public.profiles.role, assigned_role),
        updated_at = timezone('utc'::TEXT, now());

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ==============================================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Políticas de lectura pública para catálogo del gimnasio
DROP POLICY IF EXISTS "Lectura pública de categorías" ON categories;
CREATE POLICY "Lectura pública de categorías" ON categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Lectura pública de instructores" ON instructors;
CREATE POLICY "Lectura pública de instructores" ON instructors FOR SELECT USING (true);

DROP POLICY IF EXISTS "Lectura pública de clases" ON classes;
CREATE POLICY "Lectura pública de clases" ON classes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Lectura pública de horarios" ON class_schedules;
CREATE POLICY "Lectura pública de horarios" ON class_schedules FOR SELECT USING (true);

-- Políticas de Perfiles
DROP POLICY IF EXISTS "Usuarios pueden leer perfiles" ON profiles;
CREATE POLICY "Usuarios pueden leer perfiles" ON profiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Usuarios pueden insertar su propio perfil" ON profiles;
CREATE POLICY "Usuarios pueden insertar su propio perfil" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Usuarios pueden editar su propio perfil" ON profiles;
CREATE POLICY "Usuarios pueden editar su propio perfil" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Políticas de Reservas
DROP POLICY IF EXISTS "Usuarios ven sus propias reservas" ON bookings;
CREATE POLICY "Usuarios ven sus propias reservas" ON bookings FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuarios crean sus propias reservas" ON bookings;
CREATE POLICY "Usuarios crean sus propias reservas" ON bookings FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuarios actualizan sus propias reservas" ON bookings;
CREATE POLICY "Usuarios actualizan sus propias reservas" ON bookings FOR UPDATE TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuarios eliminan sus propias reservas" ON bookings;
CREATE POLICY "Usuarios eliminan sus propias reservas" ON bookings FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ==============================================================================
-- DATOS SEMILLA (Seed Data)
-- ==============================================================================
INSERT INTO categories (id, name, icon_url) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'Strength', 'barbell'),
  ('b2222222-2222-2222-2222-222222222222', 'Cardio / HIIT', 'flame'),
  ('c3333333-3333-3333-3333-333333333333', 'Power Yoga', 'sparkles'),
  ('d4444444-4444-4444-4444-444444444444', 'CrossFit', 'activity')
ON CONFLICT (id) DO NOTHING;

INSERT INTO instructors (id, name, avatar_url, bio, rating) VALUES
  ('e1111111-1111-1111-1111-111111111111', 'Marcus Vance', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150', 'Head Coach de CrossFit y levantamiento olímpico.', 4.9),
  ('e2222222-2222-2222-2222-222222222222', 'Elena Rostova', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150', 'Especialista en movilidad, Yoga dinámico y control corporal.', 5.0),
  ('e3333333-3333-3333-3333-333333333333', 'Carlos Vega', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', 'Master trainer de HIIT e intervalos anaeróbicos de alta potencia.', 4.8)
ON CONFLICT (id) DO NOTHING;

INSERT INTO classes (id, name, description, image_url, category_id, intensity, duration_minutes, base_price) VALUES
  (
    'f1111111-1111-1111-1111-111111111111',
    'CrossFit WOD: Iron Beast',
    'Sesión de máxima intensidad que combina levantamiento olímpico y acondicionamiento metabólico.',
    'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800',
    'd4444444-4444-4444-4444-444444444444',
    'High',
    60,
    25.00
  ),
  (
    'f2222222-2222-2222-2222-222222222222',
    'Power Yoga Flow',
    'Secuencia dinámica para tonificación muscular, balance y recuperación neuromuscular.',
    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
    'c3333333-3333-3333-3333-333333333333',
    'Low',
    50,
    18.00
  ),
  (
    'f3333333-3333-3333-3333-333333333333',
    'HIIT Pulse 45',
    'Intervalos anaeróbicos para acelerar el metabolismo y quemar calorías al máximo ritmo.',
    'https://images.unsplash.com/photo-1601422407692-ec4eeec1d9b3?w=800',
    'b2222222-2222-2222-2222-222222222222',
    'Medium',
    45,
    20.00
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO class_schedules (id, class_id, instructor_id, start_time, end_time, capacity, location_name, is_live) VALUES
  (
    '11111111-1111-1111-1111-111111111111',
    'f1111111-1111-1111-1111-111111111111',
    'e1111111-1111-1111-1111-111111111111',
    timezone('utc', now() + interval '2 hours'),
    timezone('utc', now() + interval '3 hours'),
    16,
    'Main Arena / Box 1',
    false
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'f2222222-2222-2222-2222-222222222222',
    'e2222222-2222-2222-2222-222222222222',
    timezone('utc', now() + interval '4 hours'),
    timezone('utc', now() + interval '4 hours 50 minutes'),
    12,
    'Studio Zen / Sala A',
    false
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    'f3333333-3333-3333-3333-333333333333',
    'e3333333-3333-3333-3333-333333333333',
    timezone('utc', now() + interval '6 hours'),
    timezone('utc', now() + interval '6 hours 45 minutes'),
    20,
    'Pulse Studio',
    false
  )
ON CONFLICT (id) DO NOTHING;
