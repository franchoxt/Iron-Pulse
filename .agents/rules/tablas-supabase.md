---
trigger: always_on
---

-- 1. EXTENSIONES Y TIPOS PERSONALIZADOS
create type user_role as enum ('admin', 'client');
create type booking_status as enum ('confirmed', 'waitlist', 'cancelled');
create type class_intensity as enum ('Low', 'Medium', 'High');

-- 2. TABLA DE PERFILES (Extiende auth.users)
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  avatar_url text,
  role user_role default 'client'::user_role,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 3. CATEGORÍAS DE CLASES (Cardio, Strength, Yoga, etc.)
create table categories (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  icon_url text
);

-- 4. INSTRUCTORES
create table instructors (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  avatar_url text,
  bio text,
  rating numeric(3,2) default 5.0
);

-- 5. CLASES (El "molde" de la clase)
create table classes (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  image_url text,
  category_id uuid references categories(id),
  intensity class_intensity default 'Medium',
  duration_minutes integer not null, -- Ejemplo: 45, 60
  base_price numeric(10,2) default 0.00
);

-- 6. HORARIOS / SESIONES (Instancias específicas de una clase)
create table class_schedules (
  id uuid default gen_random_uuid() primary key,
  class_id uuid references classes(id) on delete cascade,
  instructor_id uuid references instructors(id),
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  capacity integer not null,
  location_name text, -- Ejemplo: 'Studio A', 'Main Studio'
  is_live boolean default false
);

-- 7. RESERVAS (Unión entre Usuarios y Sesiones)
create table bookings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  schedule_id uuid references class_schedules(id) on delete cascade,
  status booking_status default 'confirmed',
  is_present boolean default false, -- Para el Check-in (Gestión de Estudiantes)
  created_at timestamp with time zone default timezone('utc'::text, now()),
  
  unique(user_id, schedule_id) -- Evita reservas duplicadas
);

-- 8. COMUNICACIONES / MENSAJES
create table messages (
  id uuid default gen_random_uuid() primary key,
  sender_id uuid references profiles(id),
  subject text,
  content text,
  is_read boolean default false,
  category text, -- 'Waitlist', 'Payment', 'General'
  created_at timestamp with time zone default timezone('utc'::text, now())
);

Análisis de Tablas según la UI
1. Gestión de Roles (Admin vs Cliente)
La tabla profiles vinculada a auth.users permite que, mediante un Trigger en Supabase, cada vez que alguien se registre, se cree un perfil con el rol client por defecto. Los administradores se asignan manualmente o mediante una función.

2. El Dashboard y Listado de Clases
categories: Alimenta los filtros de la parte superior (Cardio, Strength, Yoga).

class_schedules: Es la tabla principal para la vista de "Schedule". Permite calcular la disponibilidad en tiempo real: cupos_disponibles = capacity - (count bookings where status='confirmed').

3. Reserva y Detalles (Client View)
classes: Contiene la información estática (Imagen, Intensidad, Descripción).

bookings: Registra quién va a qué clase. Si la clase está llena, el status cambia a waitlist. El campo is_present se usa en la pantalla de Gestión de Estudiantes para marcar quién llegó a la clase.

4. Admin Portal & Stats
Occupancy Rate: Se calcula dividiendo el total de bookings confirmados por la suma de capacity de las class_schedules del día.

Happening Now: Se obtiene filtrando class_schedules donde la hora actual esté entre start_time y end_time.

5. Mensajería y Alertas
La tabla messages soporta la pantalla de Communications, permitiendo filtrar por fallos de pago o notificaciones de lista de espera.
