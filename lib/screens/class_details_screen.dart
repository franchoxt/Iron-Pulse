import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de Detalles de la Clase para IRON PULSE.
///
/// Muestra información dinámica en tiempo real desde Supabase:
/// - Imagen de portada hero con gradiente y chips de intensidad
/// - Información del Instructor con avatar, bio y rating
/// - Fecha, hora formateada y duración exacta
/// - Disponibilidad de cupos en tiempo real y cálculo calórico estimado
/// - Descripción completa, categoría y ubicación del estudio
/// - Barra inferior con precio base y botón de reserva con confirmación
class ClassDetailsScreen extends StatefulWidget {
  final ClassScheduleModel schedule;
  final bool isInitialBooked;

  const ClassDetailsScreen({
    super.key,
    required this.schedule,
    this.isInitialBooked = false,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  late bool _isBooked;
  late int _availableSpots;
  bool _isLoadingBooking = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isBooked = widget.isInitialBooked;
    _availableSpots = widget.schedule.availableSpots;
    _checkInitialBookingStatus();
  }

  Future<void> _checkInitialBookingStatus() async {
    final booked = await DatabaseService.instance.isUserBooked(widget.schedule.id);
    if (mounted && booked != _isBooked) {
      setState(() {
        _isBooked = booked;
      });
    }
  }

  Color _getIntensityColor(ClassIntensity intensity) {
    switch (intensity) {
      case ClassIntensity.low:
        return AppColors.intensityLow;
      case ClassIntensity.medium:
        return AppColors.intensityMedium;
      case ClassIntensity.high:
        return AppColors.intensityHigh;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int _calculateCalories(int durationMinutes, ClassIntensity intensity) {
    switch (intensity) {
      case ClassIntensity.low:
        return (durationMinutes * 5.5).round();
      case ClassIntensity.medium:
        return (durationMinutes * 8.2).round();
      case ClassIntensity.high:
        return (durationMinutes * 11.0).round();
    }
  }

  Future<void> _handleBookingToggle() async {
    setState(() => _isLoadingBooking = true);

    try {
      if (!_isBooked) {
        await DatabaseService.instance.bookClass(scheduleId: widget.schedule.id);
        if (!mounted) return;
        setState(() {
          _isBooked = true;
          if (_availableSpots > 0) _availableSpots--;
        });

        _showBookingSuccessDialog(
          className: widget.schedule.gymClass?.name ?? 'la clase',
          date: widget.schedule.startTime,
        );
      } else {
        await DatabaseService.instance.cancelBooking(widget.schedule.id);
        if (!mounted) return;
        setState(() {
          _isBooked = false;
          _availableSpots++;
        });

        _showFeedback(
          title: 'Reserva Cancelada',
          message: 'Se ha liberado tu cupo para esta sesión.',
          isSuccess: false,
        );
      }
    } catch (e) {
      // Si la base de datos indica que el usuario ya tenía reservada esta clase
      if (e.toString().contains('bookings_user_id_schedule_id_key') ||
          e.toString().contains('23505') ||
          e.toString().contains('duplicate key')) {
        if (!mounted) return;
        setState(() {
          _isBooked = true;
        });
        _showBookingSuccessDialog(
          className: widget.schedule.gymClass?.name ?? 'la clase',
          date: widget.schedule.startTime,
        );
        return;
      }

      if (!mounted) return;
      _showFeedback(
        title: 'Error de Reserva',
        message: 'No se pudo completar la operación: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingBooking = false);
      }
    }
  }

  void _addToInAppCalendar(String className) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131924),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primaryCyan, width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(Icons.event_available_rounded, color: AppColors.primaryCyan, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Agregado a tu Calendario!',
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Puedes consultar "$className" en la sección de Mis Reservaciones > Calendar.',
                    style: AppTypography.style(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showBookingSuccessDialog({
    required String className,
    required DateTime date,
  }) {
    final dateFormatted = _formatDate(date);
    bool addedToInAppCalendar = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF161C26),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFF263346),
                    width: 1.2,
                  ),
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
                    // Icono superior: círculo externo oscuro con círculo interno cyan y checkmark
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF102837),
                        border: Border.all(
                          color: const Color(0xFF1E3F56),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00A3E0),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF0A101D),
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Título: Class Booked!
                    Text(
                      'Class Booked!',
                      style: AppTypography.style(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtítulo: You're all set for [CLASS] on [DATE].
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "You're all set for ${className.toUpperCase()} on $dateFormatted.",
                        textAlign: TextAlign.center,
                        style: AppTypography.style(
                          color: const Color(0xFF8D9AA8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Botón Principal: Add to Calendar (Sólo dentro de la app)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: addedToInAppCalendar
                            ? null
                            : () {
                                setDialogState(() {
                                  addedToInAppCalendar = true;
                                });
                                _addToInAppCalendar(className);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: addedToInAppCalendar
                              ? const Color(0xFF166534)
                              : Colors.white,
                          foregroundColor: addedToInAppCalendar
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          disabledBackgroundColor: const Color(0xFF166534),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (addedToInAppCalendar) ...[
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              addedToInAppCalendar
                                  ? 'Added to Calendar ✓'
                                  : 'Add to Calendar',
                              style: AppTypography.style(
                                color: addedToInAppCalendar
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Botón Secundario: Done
                    GestureDetector(
                      onTap: () => Navigator.of(dialogCtx).pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Done',
                          style: AppTypography.style(
                            color: const Color(0xFFCBD5E1),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Enlace para cancelar reserva
                    GestureDetector(
                      onTap: () {
                        Navigator.of(dialogCtx).pop();
                        _promptCancelReservation();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Cancelar reserva',
                          style: AppTypography.style(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _promptCancelReservation() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161C26),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF263346), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
                  color: const Color(0xFF3B1215),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                'Cancelar Reserva',
                style: AppTypography.style(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '¿Estás seguro de que deseas cancelar tu reserva para "${widget.schedule.gymClass?.name ?? 'esta clase'}"? Se liberará tu cupo para otros atletas.',
                textAlign: TextAlign.center,
                style: AppTypography.style(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Mantener',
                        style: AppTypography.style(
                          color: const Color(0xFFCBD5E1),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Sí, Cancelar',
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 14,
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

    if (shouldCancel == true) {
      await _cancelReservation();
    }
  }

  Future<void> _cancelReservation() async {
    setState(() => _isLoadingBooking = true);
    try {
      await DatabaseService.instance.cancelBooking(widget.schedule.id);
      if (!mounted) return;
      setState(() {
        _isBooked = false;
        _availableSpots++;
      });
      _showFeedback(
        title: 'Reserva Cancelada',
        message: 'Se ha liberado tu cupo para esta clase.',
        isSuccess: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showFeedback(
        title: 'Error al Cancelar',
        message: 'No se pudo cancelar la reserva: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingBooking = false);
      }
    }
  }

  void _showFeedback({
    required String title,
    required String message,
    bool isSuccess = false,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFF2A1215)
            : (isSuccess ? const Color(0xFF0F291E) : const Color(0xFF1E293B)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isError
                ? const Color(0xFFEF4444)
                : (isSuccess ? AppColors.successGreen : AppColors.primaryBlue),
            width: 1.2,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : (isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded),
              color: isError
                  ? const Color(0xFFEF4444)
                  : (isSuccess ? AppColors.successGreen : AppColors.primaryBlue),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    message,
                    style: AppTypography.style(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstructorProfile(InstructorModel instructor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF131924),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF222C3D), width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFF1E293B),
                backgroundImage: NetworkImage(
                  instructor.avatarUrl ??
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                instructor.name,
                style: AppTypography.style(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    instructor.rating.toStringAsFixed(1),
                    style: AppTypography.style(
                      color: const Color(0xFFF59E0B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '• Head Coach',
                    style: AppTypography.style(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                instructor.bio ??
                    'Especialista certificado en acondicionamiento metabólico y entrenamiento de alto rendimiento.',
                textAlign: TextAlign.center,
                style: AppTypography.style(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final gymClass = schedule.gymClass;
    final instructor = schedule.instructor ??
        const InstructorModel(
          id: 'inst-default',
          name: 'Coach Sarah',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          bio: 'Head trainer especializada en circuitos funcionales y fuerza.',
        );

    final duration = gymClass?.durationMinutes ?? 45;
    final intensity = gymClass?.intensity ?? ClassIntensity.high;
    final intensityColor = _getIntensityColor(intensity);
    final calories = _calculateCalories(duration, intensity);
    final price = gymClass?.basePrice ?? 25.00;

    final isWaitlist = _availableSpots <= 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_isBooked);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0C1017),
        body: Stack(
          children: [
            // Contenido Scrolleable
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Image con Overlay y Título
                  _buildHeroHeader(gymClass, intensity, intensityColor),

                  // 2. Contenido Principal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),

                        // Tarjeta del Instructor
                        _buildInstructorCard(instructor),

                        const SizedBox(height: 16),

                        // Tarjeta Date, Time & Duration
                        _buildDateTimeDurationCard(schedule, duration),

                        const SizedBox(height: 16),

                        // Tarjetas Availability & Intensity
                        _buildMetricsRow(intensity, intensityColor, calories, isWaitlist),

                        const SizedBox(height: 24),

                        // Sección: About the Class
                        _buildAboutSection(gymClass, schedule),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Barra inferior Sticky fija con precio y botón de reserva
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomStickyBar(price, isWaitlist),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(GymClassModel? gymClass, ClassIntensity intensity, Color intensityColor) {
    final imageUrl = (gymClass?.imageUrl != null && gymClass!.imageUrl!.isNotEmpty)
        ? gymClass.imageUrl!
        : 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800';

    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF131924),
              child: const Icon(Icons.fitness_center_rounded, size: 64, color: Color(0xFF334155)),
            ),
          ),

          // Gradiente oscuro superior para botones y barra de estado
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Gradiente oscuro inferior que se funde con el fondo de la pantalla
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0C1017).withValues(alpha: 0.65),
                    const Color(0xFF0C1017),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Botones superiores (Atrás, Compartir, Favorito)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.topCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón Atrás
                    _buildCircleActionButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(_isBooked),
                    ),

                    // Botones Compartir y Favorito
                    Row(
                      children: [
                        _buildCircleActionButton(
                          icon: Icons.share_outlined,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enlace de la clase copiado al portapapeles.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildCircleActionButton(
                          icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          iconColor: const Color(0xFF06B6D4),
                          onTap: () {
                            setState(() => _isFavorite = !_isFavorite);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido sobre la imagen: Tag de Intensidad y Título de la Clase
          Positioned(
            bottom: 12,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tag de Intensidad (ej. HIGH INTENSITY)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: intensityColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: intensityColor.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${intensity.displayName.toUpperCase()} INTENSITY',
                    style: AppTypography.style(
                      color: intensityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Título de la Clase
                Text(
                  gymClass?.name ?? 'HIIT Power Circuit',
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.50),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildInstructorCard(InstructorModel instructor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131924),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
      ),
      child: Row(
        children: [
          // Avatar del Instructor
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              instructor.avatarUrl ??
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: const Color(0xFF1E293B),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Información del Instructor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSTRUCTOR',
                  style: AppTypography.style(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  instructor.name,
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Botón View Profile
          GestureDetector(
            onTap: () => _showInstructorProfile(instructor),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryCyan.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'View Profile',
                style: AppTypography.style(
                  color: AppColors.primaryCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeDurationCard(ClassScheduleModel schedule, int duration) {
    final dateStr = _formatDate(schedule.startTime);
    final timeStr = _formatTime(schedule.startTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131924),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
      ),
      child: Row(
        children: [
          // Columna 1: Date & Time con Icono
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date & Time',
                        style: AppTypography.style(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateStr • $timeStr',
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divisor vertical
          Container(
            width: 1,
            height: 38,
            color: const Color(0xFF222C3D),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Columna 2: Duration
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration',
                  style: AppTypography.style(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$duration min',
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(ClassIntensity intensity, Color intensityColor, int calories, bool isWaitlist) {
    return Row(
      children: [
        // Tarjeta 1: Availability
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131924),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Availability',
                      style: AppTypography.style(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFF475569),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isWaitlist ? 'Waitlist' : '$_availableSpots Spots',
                  style: AppTypography.style(
                    color: isWaitlist ? const Color(0xFFF59E0B) : const Color(0xFFF97316),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isWaitlist
                            ? const Color(0xFFF59E0B)
                            : (_availableSpots <= 4
                                ? const Color(0xFFF97316)
                                : const Color(0xFF22C55E)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isWaitlist
                          ? 'Full'
                          : (_availableSpots <= 4 ? 'Filling fast' : 'Available'),
                      style: AppTypography.style(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Tarjeta 2: Intensity
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131924),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Intensity',
                      style: AppTypography.style(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.bolt_rounded,
                      color: intensityColor.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  intensity.displayName,
                  style: AppTypography.style(
                    color: intensityColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '~$calories kcal',
                  style: AppTypography.style(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(GymClassModel? gymClass, ClassScheduleModel schedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About the Class',
          style: AppTypography.style(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          gymClass?.description ??
              'Push your limits with this high performance workout. We combine explosive movements with short recovery periods to boost your metabolic capacity, tone muscles, and increase functional strength.',
          style: AppTypography.style(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 18),

        // Ubicación y Estudio
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131924),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.primaryCyan,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ubicación: ${schedule.locationName ?? 'Main Arena • Studio A'}',
                  style: AppTypography.style(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStickyBar(double price, bool isWaitlist) {
    return Container(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1017).withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Precio Total
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Price',
                style: AppTypography.style(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: AppTypography.style(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),

          // Botón Reserve Now / Cancelar
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoadingBooking
                    ? null
                    : () {
                        if (_isBooked) {
                          _promptCancelReservation();
                        } else {
                          _handleBookingToggle();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBooked
                      ? const Color(0xFFDC2626)
                      : (isWaitlist
                          ? const Color(0xFFD97706)
                          : const Color(0xFF0284C7)),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _isBooked
                          ? const Color(0xFFEF4444)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                ),
                child: _isLoadingBooking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isBooked
                                ? 'Cancelar'
                                : (isWaitlist ? 'Join Waitlist' : 'Reserve Now'),
                            style: AppTypography.style(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isBooked
                                ? Icons.close_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
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
