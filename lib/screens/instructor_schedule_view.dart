import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../services/user_session_service.dart';
import '../theme/app_theme.dart';
import 'class_attendance_screen.dart';

/// Vista de Horarios y Clases Asignadas para el Instructor.
///
/// Permite al instructor:
/// 1. Consultar sus clases programadas filtradas por Hoy / Próximas / Pasadas.
/// 2. Ver la capacidad en tiempo real y alumnos inscritos.
/// 3. Abrir la toma de asistencia (`ClassAttendanceScreen`) con un solo toque.
class InstructorScheduleView extends StatefulWidget {
  final VoidCallback? onAttendanceChanged;

  const InstructorScheduleView({
    super.key,
    this.onAttendanceChanged,
  });

  @override
  State<InstructorScheduleView> createState() => _InstructorScheduleViewState();
}

class _InstructorScheduleViewState extends State<InstructorScheduleView> {
  List<ClassScheduleModel> _schedules = [];
  bool _isLoading = true;
  String _selectedFilter = 'Hoy'; // 'Hoy', 'Próximas', 'Pasadas', 'Todas'

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
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
          _schedules = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando horarios del instructor: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ClassScheduleModel> get _filteredSchedules {
    final now = DateTime.now();
    return _schedules.where((s) {
      if (_selectedFilter == 'Hoy') {
        return s.startTime.year == now.year &&
            s.startTime.month == now.month &&
            s.startTime.day == now.day;
      } else if (_selectedFilter == 'Próximas') {
        return s.endTime.isAfter(now);
      } else if (_selectedFilter == 'Pasadas') {
        return s.endTime.isBefore(now);
      }
      return true;
    }).toList();
  }

  void _openAttendance(ClassScheduleModel schedule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassAttendanceScreen(schedule: schedule),
      ),
    ).then((_) {
      _loadSchedules();
      if (widget.onAttendanceChanged != null) widget.onAttendanceChanged!();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSchedules;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Mis Clases',
            style: AppTypography.style(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Sesiones asignadas para impartir',
            style: AppTypography.style(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // Filtros: Hoy, Próximas, Pasadas, Todas
          _buildFilterChips(),

          const SizedBox(height: 20),

          // Lista de Clases
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: Color(0xFF00BCEB)),
              ),
            )
          else if (filtered.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final schedule = filtered[index];
                return _buildScheduleCard(schedule);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['Hoy', 'Próximas', 'Pasadas', 'Todas'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00BCEB) : const Color(0xFF141C26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00BCEB) : const Color(0xFF1E2836),
                  ),
                ),
                child: Text(
                  f,
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

  Widget _buildScheduleCard(ClassScheduleModel schedule) {
    final isLive = schedule.happeningNow || schedule.isLive;
    final confirmed = schedule.confirmedBookingsCount;
    final capacity = schedule.capacity;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLive ? const Color(0xFF00BCEB).withValues(alpha: 0.5) : const Color(0xFF1E2836),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openAttendance(schedule),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFF00BCEB).withValues(alpha: 0.18)
                            : const Color(0xFF1E2836),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLive
                              ? const Color(0xFF00BCEB).withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00BCEB),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isLive ? 'EN VIVO AHORA' : 'PROGRAMADA',
                            style: TextStyle(
                              color: isLive ? const Color(0xFF00BCEB) : const Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contador de inscritos
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$confirmed / $capacity Alumnos',
                        style: const TextStyle(
                          color: Color(0xFF00BCEB),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Título de la clase
                Text(
                  schedule.className,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                // Horario y Salón
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      schedule.timeRangeStr,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.place_outlined, color: Color(0xFF64748B), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schedule.locationName ?? 'Studio Principal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Botón Acción: Tomar Asistencia
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCEB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00BCEB).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist_rtl_rounded, color: Color(0xFF00BCEB), size: 17),
                      SizedBox(width: 6),
                      Text(
                        'Tomar Asistencia',
                        style: TextStyle(
                          color: Color(0xFF00BCEB),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, color: Color(0xFF64748B), size: 48),
          const SizedBox(height: 12),
          Text(
            'No hay clases asignadas para el filtro seleccionado',
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
}
