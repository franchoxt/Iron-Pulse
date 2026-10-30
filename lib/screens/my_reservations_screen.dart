import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'class_details_screen.dart';

/// Pantalla "Mis Reservaciones" (My Reservations) para IRON PULSE.
///
/// Características visuales y funcionales:
/// - Conectada en tiempo real a Supabase (tabla `bookings` con joins a `class_schedules`, `classes` e `instructors`).
/// - Conmutador superior de vista: 'List' y 'Calendar' interactivo.
/// - Pestañas de estado: 'UPCOMING' y 'HISTORY' con indicador cyan.
/// - Agrupación por fechas ('TODAY, 14 OCT', etc.).
/// - Tarjeta de reserva con barra lateral de acento verde/naranja, hora de inicio,
///   duración, badges de CONFIRMED / WAITLIST y botón de cancelación 'CANCEL RESERVATION' / 'LEAVE WAITLIST'.
/// - Diálogo de confirmación para cancelar reserva en Supabase en tiempo real.
class MyReservationsScreen extends StatefulWidget {
  final bool isFromBottomNav;
  final String initialTab;
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToExplore;

  const MyReservationsScreen({
    super.key,
    this.isFromBottomNav = false,
    this.initialTab = 'upcoming',
    this.onNavigateToHome,
    this.onNavigateToExplore,
  });

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  // Estado de vista: 'list' o 'calendar'
  String _viewMode = 'list';

  // Pestaña activa: 'upcoming' o 'history'
  late String _activeTab;

  // Día seleccionado en vista calendario (por defecto hoy)
  DateTime _selectedCalendarDay = DateTime.now();

  bool _isLoading = true;
  List<BookingModel> _allBookings = [];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await DatabaseService.instance.getUserBookings();
      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Filtrado de reservas próximas (Upcoming)
  List<BookingModel> get _upcomingBookings {
    final now = DateTime.now();
    // Clases cuyo fin sea posterior a hoy (con margen de 12 horas para sesiones de hoy)
    final threshold = now.subtract(const Duration(hours: 12));
    final upcoming = _allBookings.where((booking) {
      if (booking.status == BookingStatus.cancelled) return false;
      final schedule = booking.schedule;
      if (schedule == null) return true;
      return schedule.endTime.isAfter(threshold);
    }).toList();

    // Si por alguna razón ninguna reserva califica como futura, pero el usuario tiene reservas activas,
    // mostrarlas en UPCOMING para que el cliente pueda verlas y gestionarlas
    if (upcoming.isEmpty && _allBookings.any((b) => b.status != BookingStatus.cancelled)) {
      return _allBookings.where((b) => b.status != BookingStatus.cancelled).toList();
    }
    return upcoming;
  }

  // Filtrado de historial (History)
  List<BookingModel> get _historyBookings {
    final now = DateTime.now();
    return _allBookings.where((booking) {
      if (booking.status == BookingStatus.cancelled) return true;
      final schedule = booking.schedule;
      if (schedule == null) return false;
      return schedule.endTime.isBefore(now);
    }).toList();
  }

  // Lista activa según la pestaña seleccionada
  List<BookingModel> get _currentList {
    final list = _activeTab == 'upcoming' ? _upcomingBookings : _historyBookings;

    // Si está en modo calendario, filtrar por el día seleccionado
    if (_viewMode == 'calendar') {
      return list.where((b) {
        final start = b.schedule?.startTime ?? b.createdAt;
        return start.year == _selectedCalendarDay.year &&
            start.month == _selectedCalendarDay.month &&
            start.day == _selectedCalendarDay.day;
      }).toList();
    }

    return list;
  }

  // Agrupación por fecha
  Map<String, List<BookingModel>> _groupBookingsByDate(List<BookingModel> bookings) {
    final Map<String, List<BookingModel>> groups = {};
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    const weekdays = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    for (final booking in bookings) {
      final date = booking.schedule?.startTime ?? booking.createdAt;
      final bookingDay = DateTime(date.year, date.month, date.day);

      String label;
      final dateStr = '${date.day} ${months[date.month - 1]}';

      if (bookingDay.isAtSameMomentAs(today)) {
        label = 'TODAY, $dateStr';
      } else if (bookingDay.isAtSameMomentAs(tomorrow)) {
        label = 'TOMORROW, $dateStr';
      } else if (bookingDay.isAtSameMomentAs(yesterday)) {
        label = 'YESTERDAY, $dateStr';
      } else {
        final dayName = weekdays[date.weekday - 1];
        label = '$dayName, $dateStr';
      }

      groups.putIfAbsent(label, () => []).add(booking);
    }

    return groups;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Cancelación de reserva con confirmación
  Future<void> _promptCancelBooking(BookingModel booking) async {
    final className = booking.schedule?.gymClass?.name ?? 'esta clase';
    final isWaitlist = booking.status == BookingStatus.waitlist;
    final actionTitle = isWaitlist ? 'Salir de Lista de Espera' : 'Cancelar Reserva';
    final actionButtonText = isWaitlist ? 'Salir de lista' : 'Sí, cancelar reserva';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF161C26),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF263346), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWaitlist
                      ? const Color(0xFF2D2312)
                      : const Color(0xFF2E1518),
                  border: Border.all(
                    color: isWaitlist
                        ? const Color(0xFF6B481B)
                        : const Color(0xFF6B2227),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  isWaitlist ? Icons.hourglass_top_rounded : Icons.event_busy_rounded,
                  color: isWaitlist ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                actionTitle,
                style: AppTypography.style(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '¿Estás seguro de que deseas cancelar tu ${isWaitlist ? 'puesto en lista de espera' : 'reserva'} para "$className"?',
                textAlign: TextAlign.center,
                style: AppTypography.style(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Volver',
                        style: AppTypography.style(
                          color: const Color(0xFFCBD5E1),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isWaitlist
                            ? const Color(0xFFD97706)
                            : const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        actionButtonText,
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 13,
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

    if (confirmed == true) {
      await _cancelReservationAction(booking);
    }
  }

  Future<void> _cancelReservationAction(BookingModel booking) async {
    final success = await DatabaseService.instance.cancelBooking(booking.scheduleId);
    if (!mounted) return;

    if (success) {
      setState(() {
        _allBookings.removeWhere((b) => b.id == booking.id || b.scheduleId == booking.scheduleId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF131924),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.alertAmber, width: 1.0),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.alertAmber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reserva de "${booking.schedule?.gymClass?.name ?? 'la clase'}" cancelada.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _openDetails(BookingModel booking) async {
    final schedule = booking.schedule;
    if (schedule == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassDetailsScreen(
          schedule: schedule,
          isInitialBooked: booking.status != BookingStatus.cancelled,
        ),
      ),
    );

    // Al regresar, refrescar la lista por si hubo cambios
    _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Bar
            _buildTopBar(),

            const SizedBox(height: 12),

            // 2. View Mode Switcher (List / Calendar)
            _buildViewModeSwitcher(),

            const SizedBox(height: 14),

            // 3. Tabs (UPCOMING / HISTORY)
            _buildTabsHeader(),

            // 4. Contenido Principal
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadBookings,
                color: AppColors.primaryCyan,
                backgroundColor: const Color(0xFF161C26),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryCyan),
                      )
                    : _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP APP BAR
  // ===========================================================================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Botón Atrás circular
          GestureDetector(
            onTap: () {
              if (widget.isFromBottomNav && widget.onNavigateToHome != null) {
                widget.onNavigateToHome!();
              } else if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              } else if (widget.onNavigateToHome != null) {
                widget.onNavigateToHome!();
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161C26),
                border: Border.all(color: const Color(0xFF263346), width: 1.0),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Título de Pantalla
          Expanded(
            child: Text(
              'My Reservations',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // Icono de Notificaciones con punto azul
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF161C26),
                  border: Border.all(color: const Color(0xFF263346), width: 1.0),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0C1017), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CONMUTADOR DE MODO (List vs Calendar)
  // ===========================================================================
  Widget _buildViewModeSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF131924),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF222D3D), width: 1.0),
      ),
      child: Row(
        children: [
          // Botón List
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = 'list'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _viewMode == 'list'
                      ? const Color(0xFF1F2937)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: _viewMode == 'list'
                      ? Border.all(color: const Color(0xFF334155), width: 1.0)
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 18,
                      color: _viewMode == 'list' ? Colors.white : const Color(0xFF8D9AA8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'List',
                      style: AppTypography.style(
                        color: _viewMode == 'list' ? Colors.white : const Color(0xFF8D9AA8),
                        fontSize: 13.5,
                        fontWeight: _viewMode == 'list' ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón Calendar
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = 'calendar'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _viewMode == 'calendar'
                      ? const Color(0xFF1F2937)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: _viewMode == 'calendar'
                      ? Border.all(color: const Color(0xFF334155), width: 1.0)
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: _viewMode == 'calendar' ? Colors.white : const Color(0xFF8D9AA8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calendar',
                      style: AppTypography.style(
                        color: _viewMode == 'calendar' ? Colors.white : const Color(0xFF8D9AA8),
                        fontSize: 13.5,
                        fontWeight: _viewMode == 'calendar' ? FontWeight.w700 : FontWeight.w500,
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

  // ===========================================================================
  // 3. PESTAÑAS (UPCOMING vs HISTORY)
  // ===========================================================================
  Widget _buildTabsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1A2332), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Tab UPCOMING
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'upcoming'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _activeTab == 'upcoming'
                          ? const Color(0xFF00A3E0)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'UPCOMING',
                  style: AppTypography.style(
                    color: _activeTab == 'upcoming'
                        ? const Color(0xFF00A3E0)
                        : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),

          // Tab HISTORY
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'history'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _activeTab == 'history'
                          ? const Color(0xFF00A3E0)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'HISTORY',
                  style: AppTypography.style(
                    color: _activeTab == 'history'
                        ? const Color(0xFF00A3E0)
                        : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. CONTENIDO PRINCIPAL
  // ===========================================================================
  Widget _buildContent() {
    final list = _currentList;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        // Si está en modo Calendario, mostrar tira horizontal de días interactiva
        if (_viewMode == 'calendar')
          SliverToBoxAdapter(
            child: _buildInteractiveCalendarStrip(),
          ),

        if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else ...[
          // Renderizado agrupado por fecha
          ..._buildGroupedCardsSlivers(list),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ],
    );
  }

  // Tira de días interactiva para modo Calendario
  Widget _buildInteractiveCalendarStrip() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Días que tienen reservaciones
    final daysWithBookings = _allBookings.map((b) {
      final dt = b.schedule?.startTime ?? b.createdAt;
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selecciona una fecha',
                style: AppTypography.style(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${_selectedCalendarDay.day}/${_selectedCalendarDay.month}/${_selectedCalendarDay.year}',
                style: AppTypography.style(
                  color: AppColors.primaryCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 14, // 2 semanas
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = today.add(Duration(days: index - 2)); // 2 días atrás hasta 11 días adelante
                final isSelected = day.year == _selectedCalendarDay.year &&
                    day.month == _selectedCalendarDay.month &&
                    day.day == _selectedCalendarDay.day;
                final isToday = day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;
                final hasBooking = daysWithBookings.any((d) =>
                    d.year == day.year && d.month == day.month && d.day == day.day);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCalendarDay = day;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : (isToday ? const Color(0xFF1E2738) : const Color(0xFF161C26)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryCyan
                            : (isToday ? const Color(0xFF334155) : const Color(0xFF222D3D)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNames[day.weekday - 1],
                          style: AppTypography.style(
                            color: isSelected ? Colors.white : const Color(0xFF8D9AA8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${day.day}',
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasBooking
                                ? (isSelected ? Colors.white : AppColors.primaryCyan)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1F2937), thickness: 1),
        ],
      ),
    );
  }

  // Slivers de grupos por fecha
  List<Widget> _buildGroupedCardsSlivers(List<BookingModel> bookings) {
    final groups = _groupBookingsByDate(bookings);
    final slivers = <Widget>[];

    groups.forEach((dateLabel, listInDate) {
      // Encabezado de fecha
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              dateLabel,
              style: AppTypography.style(
                color: const Color(0xFF8290A0),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      );

      // Tarjetas de ese día
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final booking = listInDate[index];
              return _buildReservationCard(booking);
            },
            childCount: listInDate.length,
          ),
        ),
      );
    });

    return slivers;
  }

  // ===========================================================================
  // 5. TARJETA DE RESERVACIÓN (Diseño idéntico a la imagen)
  // ===========================================================================
  Widget _buildReservationCard(BookingModel booking) {
    final schedule = booking.schedule;
    final gymClass = schedule?.gymClass;
    final instructor = schedule?.instructor;

    final className = gymClass?.name ?? 'Sesión de Entrenamiento';
    final instructorName = instructor?.name ?? 'Coach Iron Pulse';
    final locationName = schedule?.locationName ?? 'Room A • Main Studio';
    final startTime = schedule?.startTime ?? booking.createdAt;
    final startTimeStr = _formatTime(startTime);
    final durationMinutes = gymClass?.durationMinutes ??
        (schedule != null ? schedule.endTime.difference(startTime).inMinutes : 45);

    final isConfirmed = booking.status == BookingStatus.confirmed;
    final isWaitlist = booking.status == BookingStatus.waitlist;

    // Color de la barra vertical lateral
    final Color barColor;
    if (isConfirmed) {
      barColor = const Color(0xFF22C55E); // Verde
    } else if (isWaitlist) {
      barColor = const Color(0xFFF59E0B); // Ámbar / Naranja
    } else {
      barColor = const Color(0xFF64748B); // Gris
    }

    return GestureDetector(
      onTap: () => _openDetails(booking),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161C26),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF253041), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Barra vertical de acento en el extremo izquierdo
                Container(
                  width: 4.5,
                  margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // 2. Columna de Tiempo de Inicio y Duración
                SizedBox(
                  width: 66,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start',
                          style: AppTypography.style(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          startTimeStr,
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 1,
                          height: 16,
                          color: const Color(0xFF263346),
                        ),
                        const Spacer(),
                        Text(
                          '${durationMinutes}m',
                          style: AppTypography.style(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Separador vertical sutil
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  color: const Color(0xFF1F2937),
                ),

                // 3. Columna de Detalles y Botón de Acción
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de la Clase + Chip de Estado
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                className,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.style(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(booking.status),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Fila Instructor
                        Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Instructor: $instructorName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.style(
                                  color: const Color(0xFF8D9AA8),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Fila Ubicación
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                locationName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.style(
                                  color: const Color(0xFF8D9AA8),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Botón de Acción inferior
                        _buildActionButton(booking),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Chip de Estado: CONFIRMED o WAITLIST
  Widget _buildStatusChip(BookingStatus status) {
    if (status == BookingStatus.confirmed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF10281D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1B4D36), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'CONFIRMED',
              style: AppTypography.style(
                color: const Color(0xFF22C55E),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else if (status == BookingStatus.waitlist) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2312),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4D381B), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 10.5,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(width: 4),
            Text(
              'WAITLIST',
              style: AppTypography.style(
                color: const Color(0xFFF59E0B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF221A1C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4D1E22), width: 1.0),
        ),
        child: Text(
          'CANCELLED',
          style: AppTypography.style(
            color: const Color(0xFFEF4444),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
  }

  // Botón de acción: CANCEL RESERVATION / LEAVE WAITLIST / VIEW DETAILS
  Widget _buildActionButton(BookingModel booking) {
    final isWaitlist = booking.status == BookingStatus.waitlist;

    final String label;
    if (_activeTab == 'history') {
      label = 'VIEW DETAILS';
    } else if (isWaitlist) {
      label = 'LEAVE WAITLIST';
    } else {
      label = 'CANCEL RESERVATION';
    }

    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton(
        onPressed: () {
          if (_activeTab == 'history') {
            _openDetails(booking);
          } else {
            _promptCancelBooking(booking);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F2937),
          foregroundColor: const Color(0xFFCBD5E1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2C384A), width: 0.8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: AppTypography.style(
            color: const Color(0xFFCBD5E1),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  // Estado vacío
  Widget _buildEmptyState() {
    final isUpcoming = _activeTab == 'upcoming';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF131924),
                border: Border.all(color: const Color(0xFF263346), width: 1.2),
              ),
              child: Icon(
                isUpcoming ? Icons.calendar_today_rounded : Icons.history_rounded,
                size: 38,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isUpcoming
                  ? 'No tienes reservaciones próximas'
                  : 'No tienes clases en tu historial',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'Explora el horario de clases y reserva tu lugar para comenzar a entrenar.'
                  : 'Las clases completadas o canceladas aparecerán aquí.',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                color: const Color(0xFF8D9AA8),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            if (isUpcoming && widget.onNavigateToExplore != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onNavigateToExplore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: Text(
                  'Explorar Clases',
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
