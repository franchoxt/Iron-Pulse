import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

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
        data: {'full_name': fullName.trim(), 'display_name': fullName.trim()},
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
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Error en signOut: $e');
    }
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
    return message;
  }
}
