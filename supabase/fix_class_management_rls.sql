-- ==============================================================================
-- IRON PULSE: Solución definitiva para creación de clases y horarios en Supabase
-- ==============================================================================
-- En el SQL Editor de Supabase, borra lo que tengas en la pantalla y ejecuta esto:

-- 1. Clases
DROP POLICY IF EXISTS "Permitir gestión completa de clases" ON classes;
DROP POLICY IF EXISTS "Permitir insertar clases" ON classes;
DROP POLICY IF EXISTS "Permitir actualizar clases" ON classes;
DROP POLICY IF EXISTS "Permitir eliminar clases" ON classes;

CREATE POLICY "Permitir gestión completa de clases" ON classes
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- 2. Horarios (Class Schedules)
DROP POLICY IF EXISTS "Permitir gestión completa de horarios" ON class_schedules;
DROP POLICY IF EXISTS "Permitir insertar horarios" ON class_schedules;
DROP POLICY IF EXISTS "Permitir actualizar horarios" ON class_schedules;
DROP POLICY IF EXISTS "Permitir eliminar horarios" ON class_schedules;

CREATE POLICY "Permitir gestión completa de horarios" ON class_schedules
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- 3. Instructores
DROP POLICY IF EXISTS "Permitir gestión completa de instructores" ON instructors;
DROP POLICY IF EXISTS "Permitir insertar instructores" ON instructors;
DROP POLICY IF EXISTS "Permitir actualizar instructores" ON instructors;

CREATE POLICY "Permitir gestión completa de instructores" ON instructors
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- 4. Reservaciones (Bookings)
DROP POLICY IF EXISTS "Permitir gestión completa de reservas" ON bookings;
DROP POLICY IF EXISTS "Usuarios ven sus propias reservas" ON bookings;
DROP POLICY IF EXISTS "Usuarios crean sus propias reservas" ON bookings;
DROP POLICY IF EXISTS "Usuarios actualizan sus propias reservas" ON bookings;
DROP POLICY IF EXISTS "Usuarios eliminan sus propias reservas" ON bookings;

CREATE POLICY "Permitir gestión completa de reservas" ON bookings
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);
