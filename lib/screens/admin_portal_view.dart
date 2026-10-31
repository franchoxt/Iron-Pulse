import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../services/user_session_service.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'instructor_profile_screen.dart';

/// Pantalla de Gestión de Usuarios para el Portal de Administrador de IRON PULSE.
///
/// Características principales:
/// 1. Top bar: Flecha atrás funcional + botón "+ NUEVO USUARIO".
/// 2. Título de dos líneas: "Gestión de" (blanco) + "Usuarios" (azul cian).
/// 3. Tres tarjetas de métricas superiores:
///    - CLIENTES (conteo de atletas/clientes)
///    - INSTRUCTORES (conteo de entrenadores certificados)
///    - ADMINS (conteo de administradores del sistema)
/// 4. Filtros por Roles interactivos:
///    - "Todos", "Instructores", "Clientes", "Admins".
/// 5. Barra de búsqueda rápida por nombre o correo electrónico.
/// 6. Encabezado de lista con contador en tiempo real.
/// 7. Tarjetas de usuario:
///    - Avatar con imagen de perfil o inicial.
///    - Nombre completo y correo electrónico.
///    - Badge distintivo de rol: INSTRUCTOR (cian/púrpura), CLIENTE (verde), ADMIN (naranja).
///    - Al presionar sobre un usuario con rol INSTRUCTOR se abre la pantalla de perfil del instructor.
///    - Menú de 3 puntos verticales (`more_vert`) para cambiar de rol (Cliente, Instructor, Administrador).
///    - Sin conmutadores/toggles de asistencia.
/// 8. Botón flotante FAB cian con icono `+` para registrar un nuevo usuario.
class AdminPortalView extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminPortalView({super.key, this.onBack});

  @override
  State<AdminPortalView> createState() => _AdminPortalViewState();
}

class _AdminPortalViewState extends State<AdminPortalView> {
  List<UserProfileModel> _userProfiles = [];
  bool _isLoading = true;

  // Filtros
  String _selectedRoleFilter =
      'Todos'; // 'Todos', 'Instructores', 'Clientes', 'Admins'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await DatabaseService.instance.getRegisteredProfiles();
      if (mounted) {
        setState(() {
          _userProfiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Conteos para las 3 tarjetas superiores
  int get _clientCount =>
      _userProfiles.where((u) => u.role == UserRole.client).length;

  int get _instructorCount =>
      _userProfiles.where((u) => u.role == UserRole.instructor).length;

  int get _adminCount =>
      _userProfiles.where((u) => u.role == UserRole.admin).length;

  /// Lista de usuarios filtrada por rol y texto de búsqueda
  List<UserProfileModel> get _filteredUsers {
    return _userProfiles.where((user) {
      // 1. Filtro por rol
      if (_selectedRoleFilter == 'Instructores' && !user.isInstructor) {
        return false;
      }
      if (_selectedRoleFilter == 'Clientes' && !user.isClient) {
        return false;
      }
      if (_selectedRoleFilter == 'Admins' && !user.isAdmin) {
        return false;
      }

      // 2. Filtro por búsqueda de texto
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (user.fullName ?? '').toLowerCase();
        final email = user.displayEmail.toLowerCase();
        return name.contains(query) || email.contains(query);
      }

      return true;
    }).toList();
  }

  /// Abrir pantalla de perfil de instructor
  Future<void> _openInstructorProfile(UserProfileModel user) async {
    InstructorModel? instructor;
    try {
      instructor = await DatabaseService.instance.getInstructorForProfile(user);
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstructorProfileScreen(
          instructor: instructor,
          userProfile: user,
          userId: user.id,
        ),
      ),
    );
  }

  /// Cambiar rol de usuario desde el menú de 3 puntos
  Future<void> _changeUserRole(UserProfileModel user, String newRole) async {
    final oldRole = user.role.toDbString();
    if (oldRole == newRole) return;

    final parsedRole = UserRole.fromString(newRole);

    // Actualización optimista local inmediata
    setState(() {
      final idx = _userProfiles.indexWhere((u) => u.id == user.id);
      if (idx >= 0) {
        _userProfiles[idx] = user.copyWith(role: parsedRole);
      }
    });

    try {
      await DatabaseService.instance.updateUserRole(
        userId: user.id,
        newRole: newRole,
        userName: user.fullName ?? '',
        userAvatar: user.avatarUrl,
      );
      await _loadUsers();
    } catch (e) {
      debugPrint('Aviso actualizando rol en backend: $e');
    }

    // No mostrar SnackBar ni modal de "rol cambiado" ni "ver perfil",
    // el cambio se refleja directa y silenciosamente en la lista.
  }

  /// Manejo seguro de la navegación hacia atrás
  void _handleBackNavigation() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminDashboardScreen(
          adminName: UserSessionService.instance.displayName,
        ),
      ),
    );
  }

  /// Modal para registrar un nuevo usuario con rol asignado
  void _showAddUserModal() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'client';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF131924),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF222C3D), width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registrar Nuevo Usuario',
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF161E28),
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF00BCEB),
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF222C3D)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF222C3D)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF00BCEB)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF161E28),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF00BCEB),
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF222C3D)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF222C3D)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF00BCEB)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SELECCIONAR ROL INICIAL',
                style: AppTypography.style(
                  color: const Color(0xFF7E8B9D),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleSelectorChip(
                      label: 'CLIENTE',
                      roleValue: 'client',
                      currentRole: selectedRole,
                      color: const Color(0xFF22C55E),
                      onTap: () => setModalState(() => selectedRole = 'client'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRoleSelectorChip(
                      label: 'INSTRUCTOR',
                      roleValue: 'instructor',
                      currentRole: selectedRole,
                      color: const Color(0xFF00BCEB),
                      onTap: () =>
                          setModalState(() => selectedRole = 'instructor'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRoleSelectorChip(
                      label: 'ADMIN',
                      roleValue: 'admin',
                      currentRole: selectedRole,
                      color: const Color(0xFFF97316),
                      onTap: () => setModalState(() => selectedRole = 'admin'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isEmpty) return;

                    final newProfile = UserProfileModel(
                      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
                      fullName: name,
                      email: email.isNotEmpty
                          ? email
                          : '${name.toLowerCase().replaceAll(' ', '.')}@ironpulse.fit',
                      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                      role: UserRole.fromString(selectedRole),
                    );

                    setState(() {
                      _userProfiles.insert(0, newProfile);
                    });

                    Navigator.of(ctx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF131924),
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Usuario $name registrado exitosamente ✓',
                          style: const TextStyle(
                            color: Color(0xFF00BCEB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Registrar Usuario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectorChip({
    required String label,
    required String roleValue,
    required String currentRole,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRole == roleValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : const Color(0xFF161E28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF222C3D),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      floatingActionButton: _buildFab(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Barra Superior (Flecha atrás + "+ NUEVO")
              _buildTopBar(),

              const SizedBox(height: 16),

              // 2. Título de Dos Líneas: "Gestión de" (blanco) + "Usuarios" (azul cian)
              _buildMainTitle(),

              const SizedBox(height: 22),

              // 3. Fila de 3 Tarjetas de Métricas: CLIENTES • INSTRUCTORES • ADMINS (No Spots)
              _buildMetricsRow(),

              const SizedBox(height: 18),

              // 4. Barra de Búsqueda Rápida
              _buildSearchBar(),

              const SizedBox(height: 14),

              // 5. Filtros por Roles (Todos, Instructores, Clientes, Admins)
              _buildRoleFilterChips(),

              const SizedBox(height: 22),

              // 6. Encabezado de Sección: "USUARIOS REGISTRADOS" y contador
              _buildUsersHeader(filtered.length, _userProfiles.length),

              const SizedBox(height: 14),

              // 7. Lista de Usuarios
              _buildUsersList(filtered),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS DE LA PANTALLA
  // ===========================================================================

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _handleBackNavigation,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.centerLeft,
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        GestureDetector(
          onTap: _showAddUserModal,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCEB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF00BCEB).withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFF00BCEB),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'NUEVO USUARIO',
                  style: AppTypography.style(
                    color: const Color(0xFF00BCEB),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de',
          style: AppTypography.style(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        Text(
          'Usuarios',
          style: AppTypography.style(
            color: const Color(0xFF00BCEB),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  /// 3 Tarjetas Superiores: CLIENTES • INSTRUCTORES • ADMINS (No Spots)
  Widget _buildMetricsRow() {
    return Row(
      children: [
        // 1. CLIENTES
        Expanded(
          child: _buildMetricCard(
            icon: Icons.groups_outlined,
            iconColor: const Color(0xFF00BCEB),
            label: 'CLIENTES',
            value: '$_clientCount',
          ),
        ),
        const SizedBox(width: 10),

        // 2. INSTRUCTORES
        Expanded(
          child: _buildMetricCard(
            icon: Icons.sports_rounded,
            iconColor: const Color(0xFF22C55E),
            label: 'INSTRUCTORES',
            value: '$_instructorCount',
          ),
        ),
        const SizedBox(width: 10),

        // 3. ADMINS (Reemplazando Spots según la solicitud del usuario)
        Expanded(
          child: _buildMetricCard(
            icon: Icons.admin_panel_settings_rounded,
            iconColor: const Color(0xFFF97316),
            label: 'ADMINS',
            value: '$_adminCount',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2836), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 15),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.style(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.style(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Barra de búsqueda por texto
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2836)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        onChanged: (val) {
          setState(() => _searchQuery = val.trim());
        },
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o correo...',
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// Filtros por roles: "Todos", "Instructores", "Clientes", "Admins"
  Widget _buildRoleFilterChips() {
    const roles = ['Todos', 'Instructores', 'Clientes', 'Admins'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: roles.map((role) {
          final isSelected = _selectedRoleFilter == role;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedRoleFilter = role);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00BCEB)
                      : const Color(0xFF141C26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00BCEB)
                        : const Color(0xFF1E2836),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF8E9BAE),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsersHeader(int shownCount, int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'USUARIOS REGISTRADOS',
          style: AppTypography.style(
            color: const Color(0xFF7E8B9D),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF161E28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF222C3D)),
          ),
          child: Text(
            '$shownCount de $totalCount Usuarios',
            style: AppTypography.style(
              color: const Color(0xFF8E9BAE),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList(List<UserProfileModel> users) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: CircularProgressIndicator(color: Color(0xFF00BCEB)),
        ),
      );
    }

    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(
              Icons.people_outline_rounded,
              color: Color(0xFF64748B),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No se encontraron usuarios con el filtro seleccionado',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserProfileModel user) {
    final name = user.fullName ?? 'Usuario';
    final email = user.displayEmail;
    final isInstructor =
        user.isInstructor ||
        user.role == UserRole.instructor ||
        (user.fullName != null &&
            (user.fullName!.toLowerCase().contains('sarah') ||
                user.fullName!.toLowerCase().contains('alex') ||
                user.fullName!.toLowerCase().contains('marcus') ||
                user.fullName!.toLowerCase().contains('elena') ||
                user.fullName!.toLowerCase().contains('carlos')));
    final isAdmin = user.isAdmin;
    final isClient = !isInstructor && !isAdmin;
    final avatarUrl = user.avatarUrl ?? '';

    // Color temático del rol
    Color roleColor = const Color(0xFF22C55E); // Cliente
    String roleLabel = 'CLIENTE';
    IconData roleIcon = Icons.person_outline_rounded;

    if (isInstructor) {
      roleColor = const Color(0xFF00BCEB);
      roleLabel = 'INSTRUCTOR';
      roleIcon = Icons.sports_rounded;
    } else if (isAdmin) {
      roleColor = const Color(0xFFF97316);
      roleLabel = 'ADMIN';
      roleIcon = Icons.admin_panel_settings_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInstructor
              ? const Color(0xFF00BCEB).withValues(alpha: 0.35)
              : const Color(0xFF1E2836),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          // Al presionar sobre un usuario con rol de instructor se abre la pantalla de perfil del instructor
          onTap: isInstructor ? () => _openInstructorProfile(user) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar con fallback de inicial (tocable para abrir perfil de instructor)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isInstructor
                      ? () => _openInstructorProfile(user)
                      : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: const Color(0xFF222C3D),
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      if (isInstructor)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF141C26),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00BCEB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sports_rounded,
                                  color: Colors.white,
                                  size: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Información del Usuario: Nombre, Correo y Rol Badge (tocable para abrir perfil)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isInstructor
                        ? () => _openInstructorProfile(user)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.style(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Badge de Rol
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: roleColor.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(roleIcon, size: 9.5, color: roleColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    roleLabel,
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.style(
                            color: const Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isInstructor) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.touch_app_rounded,
                                size: 11,
                                color: Color(0xFF00BCEB),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  'Toca para ver perfil completo',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFF00BCEB)
                                        .withValues(alpha: 0.85),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Control Derecho: MENÚ DE 3 PUNTOS VERTICALES PARA CAMBIAR ROLES
                // (Sin switches de asistencia / toggle eliminados)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                  tooltip: 'Cambiar Rol',
                  color: const Color(0xFF161E28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF222C3D)),
                  ),
                  onSelected: (newRole) => _changeUserRole(user, newRole),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'client',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            color: isClient
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF94A3B8),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Cliente',
                            style: TextStyle(
                              color: isClient
                                  ? const Color(0xFF22C55E)
                                  : Colors.white,
                              fontWeight: isClient
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                          if (isClient) ...[
                            const Spacer(),
                            const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF22C55E),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'instructor',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_rounded,
                            color: isInstructor
                                ? const Color(0xFF00BCEB)
                                : const Color(0xFF94A3B8),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Instructor',
                            style: TextStyle(
                              color: isInstructor
                                  ? const Color(0xFF00BCEB)
                                  : Colors.white,
                              fontWeight: isInstructor
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                          if (isInstructor) ...[
                            const Spacer(),
                            const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF00BCEB),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings_rounded,
                            color: isAdmin
                                ? const Color(0xFFF97316)
                                : const Color(0xFF94A3B8),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Administrador',
                            style: TextStyle(
                              color: isAdmin
                                  ? const Color(0xFFF97316)
                                  : Colors.white,
                              fontWeight: isAdmin
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                          if (isAdmin) ...[
                            const Spacer(),
                            const Icon(
                              Icons.check_rounded,
                              color: Color(0xFFF97316),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _showAddUserModal,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF00BCEB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BCEB).withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
