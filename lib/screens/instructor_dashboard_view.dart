import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_image_helper.dart';
import 'class_attendance_screen.dart';

/// Vista de Dashboard para el Instructor (IRON PULSE).
///
/// Implementa el diseño exacto según el mockup:
/// 1. Header con "Welcome Back,", Nombre del Instructor, Avatar y Botón de Logout en rojo.
/// 2. Cuadrícula 2x2 de métricas: Classes Today, Total Students, Occupancy, My Classes.
/// 3. Sección "My Classes" con badge de asignadas y carrusel horizontal con cover, duración,
///    próximas sesiones, alumnos inscritos y total de sesiones.
/// 4. Sección "Today's Schedule" con sesiones de hoy, capacidad en tiempo real y acceso directo a asistencia.
class InstructorDashboardView extends StatefulWidget {
  final Function(int) onNavigateTab;

  const InstructorDashboardView({
    super.key,
    required this.onNavigateTab,
  });

  @override
  State<InstructorDashboardView> createState() => _InstructorDashboardViewState();
}

class _InstructorDashboardViewState extends State<InstructorDashboardView> {
  List<ClassScheduleModel> _instructorSchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final userId = UserSessionService.instance.userId;
    final userName = UserSessionService.instance.displayName;

    try {
      final list = await DatabaseService.instance.getInstructorSchedules(
        instructorId: userId,
        instructorName: userName,
      );
      if (mounted) {
        setState(() {
          _instructorSchedules = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando dashboard de instructor: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ClassScheduleModel> get _todaySchedules {
    final now = DateTime.now();
    return _instructorSchedules.where((s) {
      return s.startTime.year == now.year &&
          s.startTime.month == now.month &&
          s.startTime.day == now.day;
    }).toList();
  }

  int get _totalStudentsCount {
    int total = 0;
    final list = _todaySchedules.isNotEmpty ? _todaySchedules : _instructorSchedules;
    for (final s in list) {
      total += s.confirmedBookingsCount;
    }
    return total;
  }

  double get _occupancyRate {
    int totalCapacity = 0;
    int totalBooked = 0;
    final list = _todaySchedules.isNotEmpty ? _todaySchedules : _instructorSchedules;
    for (final s in list) {
      totalCapacity += s.capacity;
      totalBooked += s.confirmedBookingsCount;
    }
    if (totalCapacity == 0) return 80.0;
    return (totalBooked / totalCapacity) * 100;
  }

  List<ClassScheduleModel> get _uniqueClasses {
    final Map<String, ClassScheduleModel> uniqueMap = {};
    for (final s in _instructorSchedules) {
      final key = s.gymClass?.name.toLowerCase().trim() ?? s.classId;
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = s;
      }
    }
    return uniqueMap.values.toList();
  }

  int _upcomingSessionsForClass(String? className, String classId) {
    final now = DateTime.now();
    return _instructorSchedules.where((s) {
      final match = (className != null && s.className.toLowerCase() == className.toLowerCase()) ||
          s.classId == classId;
      return match && s.endTime.isAfter(now);
    }).length;
  }

  int _totalSessionsForClass(String? className, String classId) {
    return _instructorSchedules.where((s) {
      return (className != null && s.className.toLowerCase() == className.toLowerCase()) ||
          s.classId == classId;
    }).length;
  }

  Color _getIntensityColor(ClassIntensity? intensity) {
    switch (intensity) {
      case ClassIntensity.high:
        return const Color(0xFF7C3AED); // Púrpura
      case ClassIntensity.medium:
        return const Color(0xFF3B82F6); // Azul
      case ClassIntensity.low:
        return const Color(0xFF22C55E); // Verde
      default:
        return const Color(0xFF7C3AED);
    }
  }

  String _getIntensityLabel(ClassIntensity? intensity) {
    switch (intensity) {
      case ClassIntensity.high:
        return 'High';
      case ClassIntensity.medium:
        return 'Medium';
      case ClassIntensity.low:
        return 'Low';
      default:
        return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = UserSessionService.instance.displayName;
    final avatarUrl = UserSessionService.instance.avatarUrl;

    return RefreshIndicator(
      color: const Color(0xFF00BCEB),
      backgroundColor: const Color(0xFF141C26),
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: "Welcome Back,", Nombre, Avatar + Botón Logout Rojo
            _buildHeader(displayName, avatarUrl),

            const SizedBox(height: 22),

            // 2. Cuadrícula 2x2 de Métricas
            _buildMetricsGrid(),

            const SizedBox(height: 28),

            // 3. Sección "My Classes"
            _buildMyClassesSection(),

            const SizedBox(height: 28),

            // 4. Sección "Today's Schedule"
            _buildTodayScheduleSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String? avatar) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back,',
                style: AppTypography.style(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name.isNotEmpty ? name : 'Instructor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.style(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1E2836),
              backgroundImage: AvatarImageHelper.getAvatarImageProvider(avatar),
              child: avatar == null || avatar.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'I',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => AuthService.instance.showLogoutDialog(context),
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
              tooltip: 'Cerrar Sesión',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    final todayCount = _todaySchedules.length;
    final studentsCount = _totalStudentsCount;
    final rate = _occupancyRate;
    final classesCount = _uniqueClasses.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF3B82F6),
                value: '$todayCount',
                label: 'Classes Today',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people_outline_rounded,
                iconColor: const Color(0xFF22C55E),
                value: '$studentsCount',
                label: 'Total Students',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.pie_chart_outline_rounded,
                iconColor: const Color(0xFFF59E0B),
                value: '${rate.toInt()}%',
                label: 'Occupancy',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.school_outlined,
                iconColor: const Color(0xFF00BCEB),
                value: '$classesCount',
                label: 'My Classes',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E2836), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.style(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyClassesSection() {
    final uniqueClasses = _uniqueClasses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Classes',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCEB).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00BCEB).withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Text(
                '${uniqueClasses.length} assigned',
                style: const TextStyle(
                  color: Color(0xFF00BCEB),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: CircularProgressIndicator(color: Color(0xFF00BCEB)),
            ),
          )
        else if (uniqueClasses.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF141C26),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E2836)),
            ),
            child: const Center(
              child: Text(
                'No tienes clases asignadas actualmente.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
          )
        else
          SizedBox(
            height: 245,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: uniqueClasses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final schedule = uniqueClasses[index];
                return _buildClassCard(schedule);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildClassCard(ClassScheduleModel schedule) {
    final gymClass = schedule.gymClass;
    final imageUrl = gymClass?.imageUrl ??
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800';
    final categoryName = gymClass?.category?.name ?? 'Fitness';
    final intensity = gymClass?.intensity ?? ClassIntensity.high;
    final duration = gymClass?.durationMinutes ?? 60;
    final upcomingCount = _upcomingSessionsForClass(gymClass?.name, schedule.classId);
    final totalSessions = _totalSessionsForClass(gymClass?.name, schedule.classId);
    final enrolled = schedule.confirmedBookingsCount;

    return Container(
      width: 228,
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2836), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image con Badges de Categoría e Intensidad
          SizedBox(
            height: 108,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1A2332),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Color(0xFF64748B),
                      size: 36,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 9,
                  left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: _getIntensityColor(intensity),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getIntensityLabel(intensity),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido de la Tarjeta
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF94A3B8), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '$duration min',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_rounded,
                      color: upcomingCount > 0 ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                      size: 11.5,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$upcomingCount upcoming',
                      style: TextStyle(
                        color: upcomingCount > 0 ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                // Conteo de Alumnos Inscritos
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, color: Color(0xFF00BCEB), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '$enrolled alumnos inscritos',
                      style: const TextStyle(
                        color: Color(0xFF00BCEB),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.leaderboard_outlined, color: Color(0xFF64748B), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '$totalSessions total sessions',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection() {
    final todayList = _todaySchedules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Schedule",
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (todayList.isNotEmpty)
              GestureDetector(
                onTap: () => widget.onNavigateTab(1),
                child: Text(
                  'Ver Todas',
                  style: AppTypography.style(
                    color: const Color(0xFF00BCEB),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (todayList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF141C26),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E2836)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF22C55E),
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No tienes clases programadas para hoy',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Revisa tu calendario para las próximas sesiones.',
                    style: AppTypography.style(
                      color: const Color(0xFF64748B),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final schedule = todayList[index];
              return _buildTodayScheduleCard(schedule);
            },
          ),
      ],
    );
  }

  Widget _buildTodayScheduleCard(ClassScheduleModel schedule) {
    final isLive = schedule.happeningNow || schedule.isLive;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLive ? const Color(0xFF00BCEB).withValues(alpha: 0.5) : const Color(0xFF1E2836),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFF00BCEB).withValues(alpha: 0.18)
                            : const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isLive ? 'EN VIVO AHORA' : 'HOY',
                        style: TextStyle(
                          color: isLive ? const Color(0xFF00BCEB) : const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCEB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${schedule.confirmedBookingsCount} / ${schedule.capacity} Alumnos',
                        style: const TextStyle(
                          color: Color(0xFF00BCEB),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  schedule.className,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      schedule.timeRangeStr,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.place_outlined, color: Color(0xFF64748B), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schedule.locationName ?? 'Studio Principal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E2836), height: 1),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClassAttendanceScreen(schedule: schedule),
                  ),
                ).then((_) => _loadDashboardData());
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.checklist_rtl_rounded, color: Color(0xFF00BCEB), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Tomar Asistencia',
                      style: TextStyle(
                        color: Color(0xFF00BCEB),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
