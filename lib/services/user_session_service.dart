import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'database_service.dart';

/// Servicio y Estado Global de Sesión de Usuario para IRON PULSE.
///
/// Implementa la lógica de diferenciación de roles (admin vs client)
/// y expone un ChangeNotifier observable en toda la aplicación.
class UserSessionService extends ChangeNotifier {
  UserSessionService._internal();
  static final UserSessionService instance = UserSessionService._internal();

  UserProfileModel? _profile;
  UserRole _cachedRole = UserRole.client;
  bool _isLoading = false;

  /// Perfil actual del usuario autenticado
  UserProfileModel? get profile => _profile;

  /// Rol actual del usuario (por defecto 'client')
  UserRole get role => _profile?.role ?? _cachedRole;

  /// Indica si el usuario actual tiene privilegios de administrador
  bool get isAdmin => role == UserRole.admin;

  /// Indica si el usuario actual es cliente
  bool get isClient => role == UserRole.client;

  /// Indica si se está cargando o sincronizando el rol
  bool get isLoading => _isLoading;

  /// Usuario autenticado de Supabase
  User? get currentUser => AuthService.instance.currentUser;

  /// ID del usuario autenticado actual
  String get userId => currentUser?.id ?? '';

  /// Nombre para mostrar del usuario
  String get displayName {
    if (_profile?.fullName != null && _profile!.fullName!.trim().isNotEmpty) {
      return _profile!.fullName!.trim();
    }
    final metaName = currentUser?.userMetadata?['full_name'] as String?;
    if (metaName != null && metaName.trim().isNotEmpty) {
      return metaName.trim();
    }
    final email = currentUser?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return isAdmin ? 'Admin' : 'Atleta';
  }

  /// 1. Obtiene el ID del usuario autenticado actual.
  /// 2. Realiza la consulta a la tabla 'profiles' para obtener el campo 'role'.
  /// 3. Guarda este rol en el estado global para que la app sea consciente del rol.
  ///    Maneja el caso de error o ausencia de perfil garantizando fallback seguro.
  Future<UserRole> syncUserRole({String? explicitUserId}) async {
    final uid = explicitUserId ?? currentUser?.id;

    if (uid == null || uid.isEmpty) {
      _profile = null;
      _cachedRole = UserRole.client;
      notifyListeners();
      return UserRole.client;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (!SupabaseConfig.isConfigured) {
        // Modo demo / offline
        _cachedRole = UserRole.client;
        _isLoading = false;
        notifyListeners();
        return _cachedRole;
      }

      final client = Supabase.instance.client;

      // Consulta a la tabla 'profiles' para obtener el campo 'role'
      final data = await client
          .from('profiles')
          .select('id, full_name, avatar_url, role, updated_at')
          .eq('id', uid)
          .maybeSingle();

      if (data != null) {
        _profile = UserProfileModel.fromJson(data);
        _cachedRole = _profile!.role;
      } else {
        // Manejo de error si el perfil no existe en la tabla profiles:
        // Se intenta recuperar rol desde los metadatos de auth y se asegura el perfil
        debugPrint('Aviso: Perfil no encontrado para uid=$uid. Asegurando perfil por defecto...');
        final metaRoleString = currentUser?.userMetadata?['role'] as String?;
        final resolvedRole = UserRole.fromString(metaRoleString);

        _profile = await DatabaseService.instance.ensureUserProfile(
          userId: uid,
          fullName: displayName,
          role: resolvedRole,
        );
        _cachedRole = _profile?.role ?? resolvedRole;
      }
    } catch (e) {
      debugPrint('Error al sincronizar rol de usuario: $e');
      // Fallback seguro: mantener rol client si falla la conexión
      final metaRoleString = currentUser?.userMetadata?['role'] as String?;
      _cachedRole = UserRole.fromString(metaRoleString);
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return role;
  }

  /// Limpia la sesión y el rol en memoria al cerrar sesión
  void clear() {
    _profile = null;
    _cachedRole = UserRole.client;
    _isLoading = false;
    notifyListeners();
  }
}
