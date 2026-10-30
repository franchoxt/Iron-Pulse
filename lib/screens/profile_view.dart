import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_session_service.dart';
import '../theme/app_theme.dart';
import 'my_reservations_screen.dart';
import 'personal_information_screen.dart';

/// Pantalla de Perfil de Cliente para IRON PULSE.
///
/// Diseñada exactamente según la captura de diseño adjunta:
/// - Cabecera con título "Profile" y botón de ajustes en la esquina superior derecha.
/// - Avatar centrado con anillo cyan y botón flotante de edición (lápiz) que permite
///   cambiar o editar la foto de perfil en tiempo real (persiste en Supabase).
/// - Nombre del usuario centrado (ej. "Javier") y cápsula dorada "GOLD MEMBER".
/// - Tarjeta única de métricas dividida en 3 columnas: "CLASSES", "TRAINED", "BADGES".
/// - Sección "ACCOUNT SETTINGS" con tarjetas simétricas:
///   • Personal Information (Cyan)
///   • Membership & Billing (Magenta)
///   • Training History (Ámbar)
///   • Notifications (Azul)
/// - Botón "Log Out" simétrico en fondo rojo transparente con confirmación de salida.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isLoading = true;
  int _classesCount = 1;
  String _trainedTime = '1h';
  int _badgesCount = 5;

  String? _currentAvatarUrl;
  String _currentName = 'Javier';

  // Lista de avatares fitness predeterminados
  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', // Javier atleta
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', // Atleta femenina
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400', // Retrato deportivo
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400', // Fitness pro
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400', // CrossFit atleta
    'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400', // Gimnasio entrenamiento
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final userSession = UserSessionService.instance;

    if (userSession.profile == null &&
        AuthService.instance.currentUser != null) {
      await userSession.syncUserRole();
    }

    _currentName =
        userSession.displayName.isNotEmpty &&
            userSession.displayName != 'Atleta'
        ? userSession.displayName
        : 'Javier';

    _currentAvatarUrl = userSession.profile?.avatarUrl ?? _presetAvatars[0];

    try {
      final bookings = await DatabaseService.instance.getUserBookings();
      final confirmed = bookings
          .where((b) => b.status != BookingStatus.cancelled)
          .toList();

      int minutes = 0;
      for (final b in confirmed) {
        minutes += b.schedule?.gymClass?.durationMinutes ?? 60;
      }

      if (mounted) {
        setState(() {
          _classesCount = confirmed.isNotEmpty ? confirmed.length : 1;
          final hours = (minutes / 60).round();
          _trainedTime = hours > 0 ? '${hours}h' : '1h';
          _badgesCount = 5;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAvatar(String newUrl) async {
    setState(() {
      _currentAvatarUrl = newUrl;
    });

    UserSessionService.instance.updateAvatarLocally(newUrl);

    final success = await DatabaseService.instance.updateUserProfile(
      avatarUrl: newUrl,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131924),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00A3E0), width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF00A3E0),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success
                    ? 'Foto de perfil actualizada con éxito.'
                    : 'Foto de perfil actualizada en sesión local.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Barra Superior ("Profile" + Settings Gear)
              _buildTopBar(),

              const SizedBox(height: 18),

              // 2. Avatar Centrado con Anillo Cyan y Botón de Edición (Lápiz)
              _buildAvatarSection(),

              const SizedBox(height: 14),

              // 3. Nombre del Usuario
              Text(
                _currentName,
                style: AppTypography.style(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 8),

              // 4. Cápsula de Membresía ("GOLD MEMBER")
              _buildMembershipBadge(),

              const SizedBox(height: 24),

              // 5. Tarjeta de Métricas Única (CLASSES • TRAINED • BADGES)
              _buildMetricsCard(),

              const SizedBox(height: 28),

              // 6. Sección: ACCOUNT SETTINGS
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ACCOUNT SETTINGS',
                  style: AppTypography.style(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Opción 1: Personal Information (Cyan)
              _buildSettingCard(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF00A3E0),
                iconBgColor: const Color(0xFF0B2535),
                title: 'Personal Information',
                onTap: () => _navigateToPersonalInfo(),
              ),
              const SizedBox(height: 10),

              // Opción 2: Membership & Billing (Magenta / Rosa)
              _buildSettingCard(
                icon: Icons.credit_card_rounded,
                iconColor: const Color(0xFFE879F9),
                iconBgColor: const Color(0xFF2B1333),
                title: 'Membership & Billing',
                onTap: () => _showMembershipModal(),
              ),
              const SizedBox(height: 10),

              // Opción 3: Training History (Ámbar / Naranja)
              _buildSettingCard(
                icon: Icons.history_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFF2A1C0B),
                title: 'Training History',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const MyReservationsScreen(initialTab: 'history'),
                    ),
                  );
                  if (mounted) _loadProfileData();
                },
              ),
              const SizedBox(height: 10),

              // Opción 4: Notifications (Azul Claro)
              _buildSettingCard(
                icon: Icons.notifications_none_rounded,
                iconColor: const Color(0xFF38BDF8),
                iconBgColor: const Color(0xFF0D253A),
                title: 'Notifications',
                onTap: () => _showNotificationsModal(),
              ),

              const SizedBox(height: 28),

              // 7. Botón "Log Out" (Simétrico y fondo rojo transparente)
              _buildLogOutButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. BARRA SUPERIOR ("Profile" y Botón de Ajustes)
  // ===========================================================================
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Profile',
          style: AppTypography.style(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        GestureDetector(
          onTap: () => _showSettingsMenu(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF161C26),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF263346), width: 1.2),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. AVATAR CENTRADO CON ANILLO CYAN Y BOTÓN DE EDICIÓN
  // ===========================================================================
  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anillo decorativo exterior en Cyan
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00A3E0), width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A3E0).withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(56),
                child: Image.network(
                  _currentAvatarUrl ?? _presetAvatars[0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF161C26),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF00A3E0),
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Botón Flotante con Icono de Lápiz para cambiar/editar la foto
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _showEditPhotoModal(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A3E0),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0C1017),
                    width: 2.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. CÁPSULA DE MEMBRESÍA ("GOLD MEMBER")
  // ===========================================================================
  Widget _buildMembershipBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF261D08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEAB308).withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFEAB308),
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            'GOLD MEMBER',
            style: AppTypography.style(
              color: const Color(0xFFEAB308),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. TARJETA DE MÉTRICAS ÚNICA (CLASSES • TRAINED • BADGES)
  // ===========================================================================
  Widget _buildMetricsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF131924),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Segmento 1: CLASSES -> Al presionar navega a las clases inscritas (MyReservationsScreen)
          _buildMetricColumn(
            value: _isLoading ? '...' : '$_classesCount',
            label: 'CLASSES',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const MyReservationsScreen(initialTab: 'upcoming'),
                ),
              );
              if (mounted) _loadProfileData();
            },
          ),

          // Divisor vertical
          Container(width: 1, height: 36, color: const Color(0xFF222C3D)),

          // Segmento 2: TRAINED -> Al presionar navega al historial de clases entrenadas
          _buildMetricColumn(
            value: _isLoading ? '...' : _trainedTime,
            label: 'TRAINED',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const MyReservationsScreen(initialTab: 'history'),
                ),
              );
              if (mounted) _loadProfileData();
            },
          ),

          // Divisor vertical
          Container(width: 1, height: 36, color: const Color(0xFF222C3D)),

          // Segmento 3: BADGES -> Al presionar muestra las insignias del atleta
          _buildMetricColumn(
            value: '$_badgesCount',
            label: 'BADGES',
            onTap: () => _showBadgesModal(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTypography.style(
                    color: onTap != null
                        ? const Color(0xFF00A3E0)
                        : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 13,
                    color: Color(0xFF00A3E0),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF131924),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF222C3D), width: 1.2)),
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
            Text(
              'Tus Insignias & Logros (5)',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _buildBadgeItem(
              Icons.military_tech_rounded,
              'First Workout',
              'Completaste tu primera sesión en Iron Pulse.',
            ),
            _buildBadgeItem(
              Icons.bolt_rounded,
              'High Intensity Master',
              'Superaste una clase de HIIT de alta intensidad.',
            ),
            _buildBadgeItem(
              Icons.fitness_center_rounded,
              'Iron Beast',
              'Superaste el desafío de CrossFit WOD.',
            ),
            _buildBadgeItem(
              Icons.alarm_on_rounded,
              'Early Bird',
              'Entrenaste en horario matutino antes de las 8:00 AM.',
            ),
            _buildBadgeItem(
              Icons.stars_rounded,
              'Gold Consistency',
              'Membresía activa y constancia semanal.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF261D08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFEAB308).withValues(alpha: 0.6),
              ),
            ),
            child: Icon(icon, color: const Color(0xFFEAB308), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF22C55E),
            size: 18,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TARJETAS DE ACCOUNT SETTINGS (Icono Coloreado, Título, Chevron)
  // ===========================================================================
  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131924),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
        ),
        child: Row(
          children: [
            // Contenedor del Icono
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),

            const SizedBox(width: 14),

            // Título de la opción
            Expanded(
              child: Text(
                title,
                style: AppTypography.style(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Icono Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. BOTÓN "LOG OUT" SIMÉTRICO Y ROJO TRANSPARENTE
  // ===========================================================================
  Widget _buildLogOutButton() {
    return GestureDetector(
      onTap: () => _confirmSignOut(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: AppTypography.style(
                color: const Color(0xFFEF4444),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL PARA EDITAR O CAMBIAR FOTO DE PERFIL
  // ===========================================================================
  void _showEditPhotoModal() {
    final urlController = TextEditingController();
    String tempSelected = _currentAvatarUrl ?? _presetAvatars[0];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                    'Cambiar Foto de Perfil',
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Selecciona uno de los avatares fitness o introduce una URL personalizada.',
                style: AppTypography.style(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Vista previa actual
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00A3E0),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(43),
                        child: Image.network(
                          tempSelected,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: const Color(0xFF1E293B),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Avatares Deportivos Recomendados:',
                style: AppTypography.style(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // Carrusel de selección de avatares predeterminados
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetAvatars.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final avatar = _presetAvatars[index];
                    final isChosen = tempSelected == avatar;

                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          tempSelected = avatar;
                          urlController.text = '';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isChosen
                                ? const Color(0xFF00A3E0)
                                : const Color(0xFF263346),
                            width: isChosen ? 2.5 : 1.2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(29),
                          child: Image.network(avatar, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Entrada de URL de imagen
              Text(
                'O escribe la URL de tu imagen:',
                style: AppTypography.style(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161C26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF263346)),
                ),
                child: TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'https://ejemplo.com/mi-foto.jpg',
                    hintStyle: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
                    ),
                    prefixIcon: Icon(
                      Icons.link_rounded,
                      color: Color(0xFF00A3E0),
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      setModalState(() {
                        tempSelected = val.trim();
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 22),

              // Botón Guardar Foto
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final finalUrl = urlController.text.trim().isNotEmpty
                        ? urlController.text.trim()
                        : tempSelected;
                    Navigator.of(ctx).pop();
                    _updateAvatar(finalUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3E0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Guardar Foto',
                    style: AppTypography.style(
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

  // ===========================================================================
  // MODALES INFORMATIVOS Y CONFIGURACIÓN
  // ===========================================================================

  Future<void> _navigateToPersonalInfo() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PersonalInformationScreen(),
      ),
    );
    if (updated == true && mounted) {
      _loadProfileData();
    }
  }

  void _showMembershipModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF131924),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF222C3D), width: 1.2)),
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
            Text(
              'Membership & Billing',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _buildInfoRow('Plan Activo', 'Gold Unlimited Pass'),
            _buildInfoRow('Cuota Mensual', '\$49.99 / mes'),
            _buildInfoRow('Próxima Facturación', '24 de Noviembre, 2026'),
            _buildInfoRow('Método de Pago', '•••• •••• •••• 4242'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE879F9),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Gestionar Suscripción',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF131924),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF222C3D), width: 1.2)),
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
            Text(
              'Notificaciones',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _buildNotificationRow(
              'Recordatorio de Clases',
              '1 hora antes',
              true,
            ),
            _buildNotificationRow(
              'Alertas de Lista de Espera',
              'Instantáneo',
              true,
            ),
            _buildNotificationRow('Nuevas Clases y Sesiones', 'Semanal', false),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(String title, String subtitle, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            activeThumbColor: const Color(0xFF00A3E0),
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF131924),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF222C3D), width: 1.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Color(0xFF00A3E0)),
              title: const Text(
                'Cambiar Foto de Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditPhotoModal();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.security_rounded,
                color: Color(0xFFEAB308),
              ),
              title: const Text(
                'Seguridad y Contraseña',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración de seguridad activa.'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF38BDF8),
              ),
              title: const Text(
                'Ayuda y Soporte',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Soporte de Iron Pulse: soporte@ironpulse.fit',
                    ),
                  ),
                );
              },
            ),
            const Divider(color: Color(0xFF222C3D), height: 18),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
              ),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DIÁLOGO DE CONFIRMACIÓN DE CERRAR SESIÓN
  // ===========================================================================
  Future<void> _confirmSignOut() async {
    await AuthService.instance.showLogoutDialog(context);
  }
}
