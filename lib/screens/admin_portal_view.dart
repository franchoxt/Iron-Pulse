import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_session_service.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';

/// Gestión de Estudiantes (Student Management / Roster List)
///
/// Diseñada exactamente según la interfaz de "Gestión de Estudiantes":
/// 1. Top bar: Flecha atrás funcional + botón "EDIT ROSTER" en cian.
/// 2. Título de dos líneas: "Gestión de" (blanco) + "Estudiantes" (azul cian).
/// 3. Tres tarjetas de métricas superiores:
///    - ENROLLED (24 atletas inscritos)
///    - PRESENT (18 atletas presentes con check-in)
///    - SPOTS (6 cupos disponibles)
/// 4. Píldoras selectoras:
///    - CLASS: Punto cian + Nombre de la clase (ej. CrossFit 101) + flecha desplegable.
///    - DATE: Fecha seleccionada (ej. Oct 24, Today) + icono de calendario.
/// 5. Encabezado de sección: "ROSTER LIST" con contador "18 / 24 Checked In".
/// 6. Lista de estudiantes inscritos:
///    - Avatar con badge de checkmark verde al confirmar/asistir.
///    - Nombre y correo electrónico.
///    - Etiqueta de estado: CONFIRMED (verde), RESERVED (gris) o WAITLIST #1 (naranja).
///    - Control interactivo: Switch en azul cian para check-in inmediato de presencia,
///      o menú de 3 puntos verticales para estudiantes en lista de espera.
/// 7. Botón flotante FAB: Cuadrado redondeado cian con icono `+` para añadir estudiantes.
/// 8. Sincronización en tiempo real con Supabase (tabla `bookings` e `is_present`).
class AdminPortalView extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminPortalView({super.key, this.onBack});

  @override
  State<AdminPortalView> createState() => _AdminPortalViewState();
}

class _AdminPortalViewState extends State<AdminPortalView> {
  // Clases y horarios disponibles
  List<ClassScheduleModel> _schedules = [];
  ClassScheduleModel? _selectedSchedule;
  DateTime _selectedDate = DateTime.now();

  // Lista de estudiantes del roster para la sesión seleccionada
  List<Map<String, dynamic>> _rosterStudents = [];

  // Métricas de la sesión
  int _enrolledCount = 24;
  int _presentCount = 18;
  int _spotsCount = 6;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDefaultRoster();
    _loadDataFromDatabase();
  }

  /// Carga inicial con el roster exacto de la referencia visual
  void _initDefaultRoster() {
    _rosterStudents = [
      {
        'id': 'booking-001',
        'userId': '00000000-0000-0000-0000-000000000010',
        'name': 'Alex Johnson',
        'email': 'alex.j@example.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      },
      {
        'id': 'booking-002',
        'userId': '00000000-0000-0000-0000-000000000011',
        'name': 'Maria Rodriguez',
        'email': 'maria.r@test.com',
        'status': 'reserved',
        'waitlistNumber': null,
        'isPresent': false,
        'avatar':
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
      },
      {
        'id': 'booking-003',
        'userId': '00000000-0000-0000-0000-000000000012',
        'name': 'Sam Wilson',
        'email': 'sam.wilson@demo.com',
        'status': 'waitlist',
        'waitlistNumber': 1,
        'isPresent': false,
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      },
      {
        'id': 'booking-004',
        'userId': '00000000-0000-0000-0000-000000000013',
        'name': 'Marcus Chen',
        'email': 'm.chen@gym.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      },
      {
        'id': 'booking-005',
        'userId': '00000000-0000-0000-0000-000000000014',
        'name': 'Sophia Davis',
        'email': 'sophia.d@gym.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      },
      {
        'id': 'booking-006',
        'userId': '00000000-0000-0000-0000-000000000015',
        'name': 'Lucas Miller',
        'email': 'l.miller@pulse.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
      },
      {
        'id': 'booking-007',
        'userId': '00000000-0000-0000-0000-000000000016',
        'name': 'Emma Taylor',
        'email': 'emma.t@ironpulse.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
      },
      {
        'id': 'booking-008',
        'userId': '00000000-0000-0000-0000-000000000017',
        'name': 'Liam Brown',
        'email': 'liam.b@test.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',
      },
      {
        'id': 'booking-009',
        'userId': '00000000-0000-0000-0000-000000000018',
        'name': 'Olivia Martinez',
        'email': 'olivia.m@gym.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
      },
      {
        'id': 'booking-010',
        'userId': '00000000-0000-0000-0000-000000000019',
        'name': 'Noah Wilson',
        'email': 'noah.w@ironpulse.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': '',
      },
      {
        'id': 'booking-011',
        'userId': '00000000-0000-0000-0000-000000000020',
        'name': 'Ava Anderson',
        'email': 'ava.a@pulse.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': '',
      },
      {
        'id': 'booking-012',
        'userId': '00000000-0000-0000-0000-000000000021',
        'name': 'Ethan Thomas',
        'email': 'ethan.t@test.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': '',
      },
      {
        'id': 'booking-013',
        'userId': '00000000-0000-0000-0000-000000000022',
        'name': 'Isabella Jackson',
        'email': 'isabella.j@ironpulse.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': '',
      },
      {
        'id': 'booking-014',
        'userId': '00000000-0000-0000-0000-000000000023',
        'name': 'Mason White',
        'email': 'mason.w@gym.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': '',
      },
      {
        'id': 'booking-015',
        'userId': '00000000-0000-0000-0000-000000000024',
        'name': 'Mia Harris',
        'email': 'mia.h@pulse.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': '',
      },
      {
        'id': 'booking-016',
        'userId': '00000000-0000-0000-0000-000000000025',
        'name': 'James Martin',
        'email': 'james.m@test.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': '',
      },
      {
        'id': 'booking-017',
        'userId': '00000000-0000-0000-0000-000000000026',
        'name': 'Charlotte Thompson',
        'email': 'charlotte.t@ironpulse.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': '',
      },
      {
        'id': 'booking-018',
        'userId': '00000000-0000-0000-0000-000000000027',
        'name': 'Benjamin Garcia',
        'email': 'benjamin.g@gym.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': true,
        'avatar': '',
      },
      {
        'id': 'booking-019',
        'userId': '00000000-0000-0000-0000-000000000028',
        'name': 'Amelia Martinez',
        'email': 'amelia.m@pulse.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': false,
        'avatar': '',
      },
      {
        'id': 'booking-020',
        'userId': '00000000-0000-0000-0000-000000000029',
        'name': 'Elijah Robinson',
        'email': 'elijah.r@test.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': false,
        'avatar': '',
      },
      {
        'id': 'booking-021',
        'userId': '00000000-0000-0000-0000-000000000030',
        'name': 'Harper Clark',
        'email': 'harper.c@ironpulse.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': false,
        'avatar': '',
      },
      {
        'id': 'booking-022',
        'userId': '00000000-0000-0000-0000-000000000031',
        'name': 'William Rodriguez',
        'email': 'william.r@gym.fit',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': false,
        'avatar': '',
      },
      {
        'id': 'booking-023',
        'userId': '00000000-0000-0000-0000-000000000032',
        'name': 'Evelyn Lewis',
        'email': 'evelyn.l@pulse.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': false,
        'avatar': '',
      },
      {
        'id': 'booking-024',
        'userId': '00000000-0000-0000-0000-000000000033',
        'name': 'Daniel Lee',
        'email': 'daniel.l@test.com',
        'status': 'confirmed',
        'waitlistNumber': null,
        'isPresent': false,
        'avatar': '',
      },
    ];

    _recalculateMetrics();
  }

  void _recalculateMetrics() {
    _enrolledCount = _rosterStudents.length;
    _presentCount = _rosterStudents.where((s) => s['isPresent'] == true).length;
    final capacity = _selectedSchedule?.capacity ?? 30;
    _spotsCount = (capacity - _enrolledCount).clamp(0, capacity);
  }

  Future<void> _loadDataFromDatabase() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await DatabaseService.instance.getSchedules();
      if (schedules.isNotEmpty) {
        // Encontrar clase de CrossFit o la primera disponible
        final matchCrossfit = schedules.firstWhere(
          (s) => s.className.toLowerCase().contains('crossfit'),
          orElse: () => schedules.first,
        );

        _schedules = schedules;
        _selectedSchedule = matchCrossfit;

        // Intentar cargar reservas reales de Supabase para este horario
        final remoteRoster = await DatabaseService.instance
            .getRosterForSchedule(matchCrossfit.id);
        if (remoteRoster.isNotEmpty) {
          _rosterStudents = remoteRoster;
        }
      }
    } catch (e) {
      debugPrint(
        'Aviso cargando datos de Supabase para gestión de estudiantes: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _recalculateMetrics();
          _isLoading = false;
        });
      }
    }
  }

  /// Conmutar presencia (Check-in) en tiempo real
  Future<void> _toggleStudentPresence(Map<String, dynamic> student) async {
    final newPresence = !(student['isPresent'] as bool? ?? false);
    setState(() {
      student['isPresent'] = newPresence;
      _recalculateMetrics();
    });

    final bookingId = student['id'] as String;
    await DatabaseService.instance.checkInStudent(
      bookingId: bookingId,
      isPresent: newPresence,
    );

    if (!mounted) return;
    final studentName = student['name'] as String;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131924),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: newPresence
                ? const Color(0xFF22C55E)
                : const Color(0xFF64748B),
            width: 1.2,
          ),
        ),
        content: Row(
          children: [
            Icon(
              newPresence
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: newPresence
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                newPresence
                    ? '$studentName marcado como Presente ✓'
                    : '$studentName marcado como Ausente',
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

  /// Promover estudiante de la lista de espera a confirmado
  Future<void> _promoteWaitlistStudent(Map<String, dynamic> student) async {
    setState(() {
      student['status'] = 'confirmed';
      student['waitlistNumber'] = null;
      _recalculateMetrics();
    });

    final bookingId = student['id'] as String;
    await DatabaseService.instance.updateBookingStatus(
      bookingId: bookingId,
      status: 'confirmed',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131924),
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${student['name']} fue promovido a CONFIRMADO ✓',
          style: const TextStyle(
            color: Color(0xFF00BCEB),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Eliminar estudiante del roster
  void _removeStudentFromRoster(Map<String, dynamic> student) {
    setState(() {
      _rosterStudents.removeWhere((s) => s['id'] == student['id']);
      _recalculateMetrics();
    });

    final bookingId = student['id'] as String;
    DatabaseService.instance.cancelBooking(bookingId);
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

  /// Selector de clase / horario
  void _showClassPicker() {
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
              'Seleccionar Clase',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (_schedules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'CrossFit 101 (Sesión Predeterminada)',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            else
              ..._schedules.map((schedule) {
                final isSelected = _selectedSchedule?.id == schedule.id;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: isSelected
                      ? const Color(0xFF00BCEB).withValues(alpha: 0.12)
                      : Colors.transparent,
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00BCEB)
                          : const Color(0xFF475569),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    schedule.className,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00BCEB)
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${schedule.timeRangeStr} • ${schedule.instructorName}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF00BCEB),
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedSchedule = schedule;
                      _recalculateMetrics();
                    });
                    Navigator.of(ctx).pop();
                    if (schedule.id.isNotEmpty) {
                      DatabaseService.instance
                          .getRosterForSchedule(schedule.id)
                          .then((remote) {
                            if (remote.isNotEmpty && mounted) {
                              setState(() {
                                _rosterStudents = remote;
                                _recalculateMetrics();
                              });
                            }
                          });
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Selector de fecha
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00BCEB),
              onPrimary: Colors.white,
              surface: Color(0xFF131924),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF131924),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDateDisplay() {
    final now = DateTime.now();
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final monthStr = months[_selectedDate.month - 1];
    if (isToday) {
      return '$monthStr ${_selectedDate.day}, Today';
    }
    return '$monthStr ${_selectedDate.day}, ${_selectedDate.year}';
  }

  /// Modal para agregar un estudiante al roster
  void _showAddStudentModal() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String statusSelected = 'confirmed';

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
                    'Añadir Estudiante al Roster',
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
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nombre Completo del Estudiante',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF161E28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF222C3D)),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF222C3D)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusSelectChip(
                      label: 'CONFIRMED',
                      status: 'confirmed',
                      currentStatus: statusSelected,
                      color: const Color(0xFF22C55E),
                      onTap: () =>
                          setModalState(() => statusSelected = 'confirmed'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatusSelectChip(
                      label: 'WAITLIST',
                      status: 'waitlist',
                      currentStatus: statusSelected,
                      color: const Color(0xFFF97316),
                      onTap: () =>
                          setModalState(() => statusSelected = 'waitlist'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isEmpty) return;

                    final isWaitlist = statusSelected == 'waitlist';
                    final nextWaitlistIndex =
                        _rosterStudents
                            .where((s) => s['status'] == 'waitlist')
                            .length +
                        1;

                    final newStudent = {
                      'id': 'booking-${DateTime.now().millisecondsSinceEpoch}',
                      'userId': 'user-${DateTime.now().millisecondsSinceEpoch}',
                      'name': name,
                      'email': email.isNotEmpty
                          ? email
                          : '${name.toLowerCase().replaceAll(' ', '.')}@gym.fit',
                      'status': statusSelected,
                      'waitlistNumber': isWaitlist ? nextWaitlistIndex : null,
                      'isPresent': false,
                      'avatar': '',
                    };

                    setState(() {
                      _rosterStudents.insert(0, newStudent);
                      _recalculateMetrics();
                    });

                    // Guardar en Supabase si hay sesión seleccionada
                    if (_selectedSchedule != null) {
                      DatabaseService.instance.addStudentToSchedule(
                        scheduleId: _selectedSchedule!.id,
                        fullName: name,
                        email: email.isNotEmpty
                            ? email
                            : '${name.toLowerCase().replaceAll(' ', '.')}@gym.fit',
                        status: statusSelected,
                      );
                    }

                    Navigator.of(ctx).pop();
                  },
                  child: const Text(
                    'Añadir al Roster',
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

  Widget _buildStatusSelectChip({
    required String label,
    required String status,
    required String currentStatus,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = currentStatus == status;
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
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  /// Opciones del menú superior EDIT ROSTER
  void _showEditRosterOptions() {
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
              'Opciones de Roster',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF22C55E),
              ),
              title: const Text(
                'Marcar Todos como Presentes',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  for (final s in _rosterStudents) {
                    if (s['status'] != 'waitlist') {
                      s['isPresent'] = true;
                    }
                  }
                  _recalculateMetrics();
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.remove_circle_outline_rounded,
                color: Color(0xFFF59E0B),
              ),
              title: const Text(
                'Desmarcar Asistencia de Todos',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  for (final s in _rosterStudents) {
                    s['isPresent'] = false;
                  }
                  _recalculateMetrics();
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.person_add_rounded,
                color: Color(0xFF00BCEB),
              ),
              title: const Text(
                'Añadir Estudiante al Roster',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showAddStudentModal();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.manage_accounts_rounded,
                color: Color(0xFFA855F7),
              ),
              title: const Text(
                'Gestionar Roles de Usuarios',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showManageRolesSheet();
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
                AuthService.instance.showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Sheet para gestionar roles de usuarios registrado en la base de datos
  Future<void> _showManageRolesSheet() async {
    final profiles = await DatabaseService.instance.getRegisteredProfiles();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF131924),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF222C3D), width: 1.2),
            ),
          ),
          child: Column(
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
                    'Gestión de Roles',
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
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final p = profiles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161E28),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF222C3D)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF222C3D),
                            backgroundImage: p.avatarUrl != null
                                ? NetworkImage(p.avatarUrl!)
                                : null,
                            child: p.avatarUrl == null
                                ? Text(
                                    (p.fullName ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName ?? 'Usuario',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  p.role.toDbString().toUpperCase(),
                                  style: TextStyle(
                                    color: p.isAdmin
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFF00BCEB),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                            color: const Color(0xFF161E28),
                            onSelected: (newRole) async {
                              await DatabaseService.instance.updateUserRole(
                                userId: p.id,
                                newRole: newRole,
                                userName: p.fullName ?? 'Usuario',
                              );
                              setSheetState(() {});
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'client',
                                child: Text(
                                  'Cliente',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'instructor',
                                child: Text(
                                  'Instructor',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'admin',
                                child: Text(
                                  'Administrador',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // 1. Barra Superior (Flecha atrás + EDIT ROSTER)
              _buildTopBar(),

              const SizedBox(height: 16),

              // 2. Título de Dos Líneas: "Gestión de" (blanco) + "Estudiantes" (azul cian)
              _buildMainTitle(),

              const SizedBox(height: 22),

              // 3. Fila de 3 Tarjetas de Métricas: ENROLLED (24) • PRESENT (18) • SPOTS (6)
              _buildMetricsRow(),

              const SizedBox(height: 16),

              // 4. Píldoras Selectoras de CLASS y DATE
              _buildSelectorPills(),

              const SizedBox(height: 24),

              // 5. Encabezado de Sección: "ROSTER LIST" y chip contador "18 / 24 Checked In"
              _buildRosterHeader(),

              const SizedBox(height: 14),

              // 6. Lista de Estudiantes Inscritos en el Roster
              _buildRosterList(),
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
          onTap: _showEditRosterOptions,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(
              'EDIT ROSTER',
              style: AppTypography.style(
                color: const Color(0xFF00BCEB),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
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
          'Estudiantes',
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

  Widget _buildMetricsRow() {
    return Row(
      children: [
        // 1. ENROLLED: Total de inscritos
        Expanded(
          child: _buildMetricCard(
            icon: Icons.groups_outlined,
            iconColor: const Color(0xFF00BCEB),
            label: 'ENROLLED',
            value: '$_enrolledCount',
          ),
        ),
        const SizedBox(width: 10),

        // 2. PRESENT: Total de presentes con check-in
        Expanded(
          child: _buildMetricCard(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF22C55E),
            label: 'PRESENT',
            value: '$_presentCount',
          ),
        ),
        const SizedBox(width: 10),

        // 3. SPOTS: Cupos libres restantes
        Expanded(
          child: _buildMetricCard(
            icon: Icons.event_seat_rounded,
            iconColor: const Color(0xFFF97316),
            label: 'SPOTS',
            value: '$_spotsCount',
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.style(
                  color: iconColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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

  /// Fila con las píldoras selectoras de CLASS y DATE
  Widget _buildSelectorPills() {
    final className = _selectedSchedule?.className ?? 'CrossFit 101';
    final dateDisplay = _formatDateDisplay();

    return Row(
      children: [
        // Píldora 1: CLASS
        Expanded(
          child: GestureDetector(
            onTap: _showClassPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141C26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E2836), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLASS',
                    style: AppTypography.style(
                      color: const Color(0xFF64748B),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BCEB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          className,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Píldora 2: DATE
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141C26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E2836), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATE',
                    style: AppTypography.style(
                      color: const Color(0xFF64748B),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dateDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFF64748B),
                        size: 15,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRosterHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ROSTER LIST',
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
            '$_presentCount / $_enrolledCount Checked In',
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

  Widget _buildRosterList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: CircularProgressIndicator(color: Color(0xFF00BCEB)),
        ),
      );
    }

    if (_rosterStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
              'No hay estudiantes registrados en este horario',
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
      itemCount: _rosterStudents.length,
      itemBuilder: (context, index) {
        final student = _rosterStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final String name = student['name'] as String? ?? 'Atleta';
    final String email = student['email'] as String? ?? 'atleta@ironpulse.fit';
    final String status = student['status'] as String? ?? 'confirmed';
    final bool isPresent = student['isPresent'] as bool? ?? false;
    final String avatarUrl = student['avatar'] as String? ?? '';
    final int? waitlistNumber = student['waitlistNumber'] as int?;

    final isWaitlist = status.toLowerCase() == 'waitlist';
    final isConfirmed = status.toLowerCase() == 'confirmed';
    final isReserved = status.toLowerCase() == 'reserved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2836), width: 1.0),
      ),
      child: Row(
        children: [
          // Avatar con Badge de verificación verde si está confirmado o presente
          Stack(
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
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              if (isConfirmed || isPresent)
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
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Información del Atleta (Nombre, Correo, Etiqueta de Estado)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
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
                const SizedBox(height: 4),

                // Etiqueta de Estado
                if (isConfirmed)
                  Text(
                    'CONFIRMED',
                    style: AppTypography.style(
                      color: const Color(0xFF22C55E),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  )
                else if (isReserved)
                  Text(
                    'RESERVED',
                    style: AppTypography.style(
                      color: const Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  )
                else if (isWaitlist)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFF97316).withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'WAITLIST #${waitlistNumber ?? 1}',
                      style: AppTypography.style(
                        color: const Color(0xFFF97316),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Control Derecho: Switch cian para presentes, o 3 puntos para lista de espera
          if (isWaitlist)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              color: const Color(0xFF161E28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF222C3D)),
              ),
              onSelected: (action) {
                if (action == 'promote') {
                  _promoteWaitlistStudent(student);
                } else if (action == 'remove') {
                  _removeStudentFromRoster(student);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'promote',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF00BCEB),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Promover a Confirmado',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Eliminar de Lista de Espera',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Switch.adaptive(
              value: isPresent,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF00BCEB),
              inactiveThumbColor: const Color(0xFF94A3B8),
              inactiveTrackColor: const Color(0xFF222C3D),
              onChanged: (_) => _toggleStudentPresence(student),
            ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _showAddStudentModal,
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
