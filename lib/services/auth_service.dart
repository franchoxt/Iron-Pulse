import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import 'database_service.dart';
import 'user_session_service.dart';

/// Servicio de autenticación con Supabase para Iron Pulse.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Comprueba si Supabase ha sido inicializado correctamente
  bool get isInitialized {
    try {
      return SupabaseConfig.isConfigured &&
              Supabase.instance.client.auth.currentUser != null ||
          SupabaseConfig.isConfigured;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get client {
    if (!SupabaseConfig.isConfigured) {
      throw const AuthException(
        'Supabase no está configurado. Por favor ingresa tu URL y Anon Key en el archivo .env',
      );
    }
    return Supabase.instance.client;
  }

  /// Usuario actual autenticado
  User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Sesión actual activa
  Session? get currentSession {
    try {
      return client.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  /// Stream de cambios de estado de autenticación
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Iniciar sesión con email y contraseña
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('AuthException en signInWithEmail: ${e.message}');
      throw AuthException(_mapAuthError(e.message));
    } catch (e) {
      debugPrint('Error inesperado en signInWithEmail: $e');
      throw AuthException('Error al conectar con el servidor: $e');
    }
  }

  /// Registrar nuevo atleta con email, contraseña y nombre completo
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'display_name': fullName.trim(),
          'role': 'client',
        },
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('AuthException en signUpWithEmail: ${e.message}');
      throw AuthException(_mapAuthError(e.message));
    } catch (e) {
      debugPrint('Error inesperado en signUpWithEmail: $e');
      throw AuthException('Error al registrar usuario: $e');
    }
  }

  /// Enviar enlace de restablecimiento de contraseña al correo
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthException(_mapAuthError(e.message));
    } catch (e) {
      throw AuthException('Error al solicitar restablecimiento: $e');
    }
  }

  /// Cerrar sesión actual
  Future<void> signOut() async {
    try {
      if (isInitialized) {
        await client.auth.signOut();
      }
    } catch (e) {
      debugPrint('Error en signOut: $e');
    }
  }

  /// Cierra la sesión en Supabase, limpia almacenamiento local/memoria y redirige al Login
  Future<void> logout(BuildContext context) async {
    try {
      // 1. Cerrar sesión en el backend Supabase (limpia tokens de almacenamiento local)
      await signOut();
    } catch (e) {
      debugPrint('Aviso durante signOut en Supabase: $e');
    }

    // 2. Limpiar almacenamiento local en memoria de la sesión
    UserSessionService.instance.clear();
    DatabaseService.instance.clearSessionData();

    // 3. Redireccionar a la pantalla de Login limpiando todo el historial de navegación
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth',
        (route) => false,
      );
    }
  }

  /// Diálogo de confirmación para cerrar sesión (Cliente y Admin)
  Future<bool> showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF141C26),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF263346), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 26,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '¿Estás seguro de que deseas salir de tu cuenta en IRON PULSE?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Sí, Salir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await logout(context);
      return true;
    }
    return false;
  }

  /// Traduce los mensajes comunes de Supabase Auth a español amigable
  static String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Credenciales inválidas. Verifica tu correo y contraseña.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already exists')) {
      return 'Ya existe una cuenta registrada con este correo electrónico.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada.';
    }
    if (lower.contains('password should be at least')) {
      return 'La contraseña debe contener al menos 6 caracteres.';
    }
    if (lower.contains('invalid email') || lower.contains('valid email')) {
      return 'Por favor ingresa un correo electrónico válido.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Error de conexión. Verifica tu conexión a internet.';
    }
    if (lower.contains('rate limit')) {
      return 'Demasiados intentos. Espera unos momentos antes de volver a intentar.';
    }
    if (lower.contains('database error saving new user')) {
      return 'Error de base de datos en Supabase al registrar usuario. Asegúrate de ejecutar el script assign_client_role_trigger.sql en el SQL Editor de Supabase.';
    }
    return message;
  }
}
