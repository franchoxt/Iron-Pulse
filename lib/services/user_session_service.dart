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

  /// URL del avatar actual del perfil (de la base de datos o metadatos de usuario)
  String? get avatarUrl {
    if (_profile?.avatarUrl != null && _profile!.avatarUrl!.trim().isNotEmpty) {
      return _profile!.avatarUrl!.trim();
    }
    final metaAvatar = currentUser?.userMetadata?['avatar_url'] as String?;
    if (metaAvatar != null && metaAvatar.trim().isNotEmpty) {
      return metaAvatar.trim();
    }
    return null;
  }

  /// Rol actual del usuario (por defecto 'client')
  UserRole get role => _profile?.role ?? _cachedRole;

  /// Indica si el usuario actual tiene privilegios de administrador
  bool get isAdmin => role == UserRole.admin;

  /// Indica si el usuario actual es cliente
  bool get isClient => role == UserRole.client;

  /// Indica si el usuario actual es instructor o entrenador
  bool get isInstructor => role == UserRole.instructor;

  /// Actualiza temporalmente el avatar de forma reactiva local
  void updateAvatarLocally(String newAvatarUrl) {
    if (_profile != null) {
      _profile = _profile!.copyWith(avatarUrl: newAvatarUrl);
      notifyListeners();
    }
  }

  /// Actualiza datos del perfil localmente de forma reactiva
  void updateProfileLocally({String? fullName, String? avatarUrl}) {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        fullName: fullName ?? _profile!.fullName,
        avatarUrl: avatarUrl ?? _profile!.avatarUrl,
      );
      notifyListeners();
    }
  }

  /// Establece manualmente el perfil y rol (para demo / prueba rápida o sugeridos)
  void setManualSession({
    required String name,
    required UserRole role,
    String? email,
    String? id,
    String? avatarUrl,
  }) {
    _cachedRole = role;
    _profile = UserProfileModel(
      id: id ?? (role == UserRole.instructor ? 'e1111111-1111-1111-1111-111111111111' : 'demo-${role.toDbString()}'),
      fullName: name,
      email: email,
      role: role,
      avatarUrl: avatarUrl ?? (role == UserRole.instructor ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200' : null),
    );
    _isLoading = false;
    notifyListeners();
  }

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
      final currentEmail = currentUser?.email ?? '';
      final metaRole = currentUser?.userMetadata?['role']?.toString().toLowerCase();

      // Consulta a la tabla 'profiles' para obtener el campo 'role'
      final data = await client
          .from('profiles')
          .select('id, full_name, avatar_url, role, updated_at')
          .eq('id', uid)
          .maybeSingle();

      UserProfileModel? loadedProfile =
          data != null ? UserProfileModel.fromJson(data) : null;
      final resolvedName = loadedProfile?.fullName ?? displayName;

      // Prioridad Instructor: si está en auth metadata, en overrides de sesión, en instructors table o en demo
      final isInst = metaRole == 'instructor' ||
          (DatabaseService.instance.getSessionOverride(uid)?.role == UserRole.instructor) ||
          (resolvedName.isNotEmpty &&
              DatabaseService.instance.getSessionOverride(resolvedName)?.role == UserRole.instructor) ||
          await DatabaseService.instance.checkIfUserIsInstructor(
            userId: uid,
            userName: resolvedName,
            email: currentEmail,
          );

      if (isInst) {
        _cachedRole = UserRole.instructor;
        _profile = (loadedProfile ??
                UserProfileModel(
                  id: uid,
                  fullName: resolvedName,
                  email: currentEmail,
                  role: UserRole.instructor,
                ))
            .copyWith(role: UserRole.instructor);
      } else if (loadedProfile != null) {
        _profile = loadedProfile;
        _cachedRole = loadedProfile.role;
      } else {
        // Manejo de error si el perfil no existe en la tabla profiles:
        debugPrint('Aviso: Perfil no encontrado para uid=$uid. Asegurando perfil por defecto...');
        final resolvedRole = UserRole.fromString(metaRole);

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
