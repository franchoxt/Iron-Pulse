import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de Gestión de Asistencia de Clase (Class Attendance) para Instructores.
///
/// Permite al instructor:
/// 1. Ver la información de la sesión seleccionada (Clase, Horario, Ubicación).
/// 2. Métricas rápidas: Total Inscritos, Presentes (Checked-in) y Cupos libres.
/// 3. Lista de estudiantes inscritos con filtro de búsqueda.
/// 4. Control Toggle Switch interactivo para marcar asistencia (`is_present`)
///    con sincronización en tiempo real con Supabase.
class ClassAttendanceScreen extends StatefulWidget {
  final ClassScheduleModel schedule;

  const ClassAttendanceScreen({
    super.key,
    required this.schedule,
  });

  @override
  State<ClassAttendanceScreen> createState() => _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends State<ClassAttendanceScreen> {
  List<Map<String, dynamic>> _roster = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoster() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseService.instance.getClassBookings(widget.schedule.id);
      if (mounted) {
        setState(() {
          _roster = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando asistencia de clase: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _enrolledCount => _roster.length;
  int get _presentCount => _roster.where((s) => s['isPresent'] == true).length;
  int get _spotsRemaining =>
      (widget.schedule.capacity - _enrolledCount).clamp(0, widget.schedule.capacity);

  List<Map<String, dynamic>> get _filteredRoster {
    if (_searchQuery.isEmpty) return _roster;
    final q = _searchQuery.toLowerCase();
    return _roster.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      final email = (s['email'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _togglePresence(Map<String, dynamic> student) async {
    final current = student['isPresent'] as bool? ?? false;
    final updated = !current;

    setState(() {
      student['isPresent'] = updated;
    });

    final bookingId = student['id'] as String;
    await DatabaseService.instance.updateAttendance(
      bookingId: bookingId,
      isPresent: updated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final filtered = _filteredRoster;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              _buildTopBar(),

              const SizedBox(height: 18),

              // Info de la sesión
              _buildSessionHeader(schedule),

              const SizedBox(height: 20),

              // Métricas: ENROLLED • PRESENT • SPOTS
              _buildMetricsRow(),

              const SizedBox(height: 18),

              // Barra de búsqueda
              _buildSearchBar(),

              const SizedBox(height: 18),

              // Encabezado de Roster
              _buildRosterHeader(filtered.length),

              const SizedBox(height: 14),

              // Lista de estudiantes con Switch
              _buildStudentsList(filtered),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF161F2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF243247)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'CLASE EN VIVO',
                style: AppTypography.style(
                  color: const Color(0xFF22C55E),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionHeader(ClassScheduleModel schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Toma de Asistencia',
          style: AppTypography.style(
            color: const Color(0xFF00BCEB),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          schedule.className,
          style: AppTypography.style(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF94A3B8),
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              schedule.timeRangeStr,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.place_outlined,
              color: Color(0xFF94A3B8),
              size: 15,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                schedule.locationName ?? 'Studio Principal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'INSCRITOS',
            value: '$_enrolledCount',
            color: const Color(0xFF00BCEB),
            icon: Icons.groups_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            label: 'PRESENTES',
            value: '$_presentCount',
            color: const Color(0xFF22C55E),
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            label: 'CUPOS',
            value: '$_spotsRemaining',
            color: const Color(0xFFF97316),
            icon: Icons.event_seat_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2836)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

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
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        decoration: InputDecoration(
          hintText: 'Buscar atleta en la lista...',
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
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

  Widget _buildRosterHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ROSTER DE ATLETAS',
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
            '$_presentCount / $_enrolledCount Presentes',
            style: const TextStyle(
              color: Color(0xFF00BCEB),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList(List<Map<String, dynamic>> students) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: CircularProgressIndicator(color: Color(0xFF00BCEB)),
        ),
      );
    }

    if (students.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded, color: Color(0xFF64748B), size: 48),
            const SizedBox(height: 12),
            Text(
              'No hay atletas inscritos en esta sesión',
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
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final name = student['name'] as String? ?? 'Atleta';
        final email = student['email'] as String? ?? 'atleta@ironpulse.fit';
        final isPresent = student['isPresent'] as bool? ?? false;
        final avatar = student['avatar'] as String? ?? '';
        final status = student['status'] as String? ?? 'confirmed';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF141C26),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPresent
                  ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                  : const Color(0xFF1E2836),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF222C3D),
                    backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  if (isPresent)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 9,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Nombre y Correo
              Expanded(
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (status == 'waitlist') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'WAITLIST',
                              style: TextStyle(
                                color: Color(0xFFF97316),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Control interactivo: Switch de Check-in
              Switch.adaptive(
                value: isPresent,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF00BCEB),
                inactiveThumbColor: const Color(0xFF94A3B8),
                inactiveTrackColor: const Color(0xFF222C3D),
                onChanged: (_) => _togglePresence(student),
              ),
            ],
          ),
        );
      },
    );
  }
}
