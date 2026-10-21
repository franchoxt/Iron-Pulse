/// Configuración de Supabase para Iron Pulse.
///
/// Las credenciales se leen de forma segura a través de variables de entorno
/// (`--dart-define` o `--dart-define-from-file=.env`).
///
/// Para desarrollo local, crea un archivo `.env` en la raíz del proyecto
/// basándote en `.env.example` con tus credenciales de Supabase.
class SupabaseConfig {
  /// URL del proyecto Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Clave anónima pública / publishable key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Comprueba si se han proporcionado credenciales válidas
  static bool get isConfigured {
    return supabaseUrl.trim().isNotEmpty &&
        supabaseAnonKey.trim().isNotEmpty &&
        supabaseUrl != 'https://TU_PROYECTO_AQUI.supabase.co' &&
        supabaseAnonKey != 'TU_SUPABASE_ANON_KEY_AQUI';
  }
}
