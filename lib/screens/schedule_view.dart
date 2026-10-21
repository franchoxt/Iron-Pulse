import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Vista de Horarios y Sesiones (Schedule)
/// Basado en .agents/rules/tablas-supabase.md y guias-de-estilo-y-reglas-de-diseno.md
class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  bool _isLoading = true;
  List<ClassScheduleModel> _schedules = [];
  String _selectedCategory = 'all';
  List<CategoryModel> _categories = [];
  final Set<String> _bookedScheduleIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await DatabaseService.instance.getCategories();
      final schedules = await DatabaseService.instance.getSchedules(
        categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _categories = categories;
          _schedules = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBook(ClassScheduleModel schedule) async {
    final isAlreadyBooked = _bookedScheduleIds.contains(schedule.id);

    setState(() {
      if (isAlreadyBooked) {
        _bookedScheduleIds.remove(schedule.id);
      } else {
        _bookedScheduleIds.add(schedule.id);
      }
    });

    try {
      if (!isAlreadyBooked) {
        await DatabaseService.instance.bookClass(scheduleId: schedule.id);
      } else {
        await DatabaseService.instance.cancelBooking(schedule.id);
      }
    } catch (_) {}

    if (!mounted) return;

    final isBookedNow = _bookedScheduleIds.contains(schedule.id);
    final isWaitlist = schedule.isFull;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isBookedNow
                ? (isWaitlist ? AppColors.alertAmber : AppColors.successGreen)
                : AppColors.primaryBlue,
            width: 1.2,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isBookedNow
                  ? (isWaitlist ? Icons.hourglass_top_rounded : Icons.check_circle_rounded)
                  : Icons.info_outline_rounded,
              color: isBookedNow
                  ? (isWaitlist ? AppColors.alertAmber : AppColors.successGreen)
                  : AppColors.primaryLight,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isBookedNow
                    ? (isWaitlist
                        ? 'Clase llena: ¡Añadido a lista de espera (Waitlist)!'
                        : '¡Reserva confirmada con éxito!')
                    : 'Reserva cancelada.',
                style: AppTypography.style(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryBlue,
          backgroundColor: AppColors.cardBg,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horarios & Sesiones',
                        style: AppTypography.style(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reserva tu cupo en tiempo real o únete a la lista de espera',
                        style: AppTypography.style(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filtros de categorías
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.isEmpty ? 1 : _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (_categories.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat.id);
                          _loadData();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryBlue : AppColors.cardBg,
                            borderRadius: AppDimensions.chipBorderRadius,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtle,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat.name,
                            style: AppTypography.style(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textLight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Lista de sesiones
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryBlue),
                  ),
                )
              else if (_schedules.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy_rounded, color: AppColors.textSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No hay sesiones programadas en esta categoría',
                          style: AppTypography.style(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final schedule = _schedules[index];
                        final gymClass = schedule.gymClass;
                        final instructor = schedule.instructor;
                        final isBooked = _bookedScheduleIds.contains(schedule.id);
                        final available = isBooked
                            ? (schedule.availableSpots > 0 ? schedule.availableSpots - 1 : 0)
                            : schedule.availableSpots;
                        final isFull = available <= 0;
                        final intensity = gymClass?.intensity ?? ClassIntensity.medium;
                        final intensityColor = _getIntensityColor(intensity);

                        final startTimeStr =
                            '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}';
                        final endTimeStr =
                            '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: AppDimensions.cardBorderRadius,
                            border: Border.all(
                              color: isBooked
                                  ? AppColors.primaryBlue.withValues(alpha: 0.6)
                                  : AppColors.borderSubtle,
                              width: isBooked ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: AppDimensions.cardBorderRadius,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen superior con overlay e información clave
                                if (gymClass?.imageUrl != null)
                                  Stack(
                                    children: [
                                      SizedBox(
                                        height: 120,
                                        width: double.infinity,
                                        child: Image.network(
                                          gymClass!.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppColors.cardBgLight,
                                            child: const Icon(Icons.fitness_center_rounded,
                                                color: AppColors.primaryBlue, size: 36),
                                          ),
                                        ),
                                      ),
                                      // Dark Overlay para asegurar legibilidad
                                      Container(
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.3),
                                              Colors.black.withValues(alpha: 0.75),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Chips superiores: Intensidad & Live
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        right: 12,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Chip de Intensidad
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: intensityColor.withValues(alpha: 0.25),
                                                borderRadius: AppDimensions.chipBorderRadius,
                                                border: Border.all(color: intensityColor, width: 1),
                                              ),
                                              child: Text(
                                                'INTENSIDAD: ${intensity.displayName.toUpperCase()}',
                                                style: AppTypography.style(
                                                  color: intensityColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            if (schedule.happeningNow || schedule.isLive)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.errorRed.withValues(alpha: 0.3),
                                                  borderRadius: AppDimensions.chipBorderRadius,
                                                  border: Border.all(color: AppColors.errorRed),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.errorRed,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'EN VIVO',
                                                      style: AppTypography.style(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Horario destacado sobre la imagen
                                      Positioned(
                                        bottom: 10,
                                        left: 12,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.access_time_filled_rounded,
                                                color: Colors.white, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$startTimeStr - $endTimeStr (${gymClass.durationMinutes} min)',
                                              style: AppTypography.style(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                // Cuerpo de la tarjeta (Padding 16 según regla p-4 / p-6)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Título y Precio destacado
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              gymClass?.name ?? 'Sesión de Entrenamiento',
                                              style: AppTypography.style(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textWhite,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Precio destacado (Jerarquía Visual)
                                          Text(
                                            '\$${gymClass?.basePrice.toStringAsFixed(2) ?? '0.00'}',
                                            style: AppTypography.style(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primaryLight,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      // Instructor y Ubicación
                                      Row(
                                        children: [
                                          const Icon(Icons.person_pin_circle_rounded,
                                              size: 15, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            instructor?.name ?? 'Coach Iron Pulse',
                                            style: AppTypography.style(
                                              fontSize: 12,
                                              color: AppColors.textLight,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.location_on_outlined,
                                              size: 15, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              schedule.locationName ?? 'Studio Principal',
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.style(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      // Disponibilidad y Botón de Acción
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Cupos disponibles calculados en tiempo real
                                          Row(
                                            children: [
                                              Icon(
                                                isFull
                                                    ? Icons.warning_amber_rounded
                                                    : Icons.check_circle_outline_rounded,
                                                size: 16,
                                                color: isFull
                                                    ? AppColors.alertAmber
                                                    : AppColors.successGreen,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isFull
                                                    ? 'Sin cupos libres (Waitlist)'
                                                    : '$available de ${schedule.capacity} cupos libres',
                                                style: AppTypography.style(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isFull
                                                      ? AppColors.alertAmber
                                                      : AppColors.successGreen,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Botón táctil de altura mínima 48px y rounded-2xl
                                          ElevatedButton(
                                            onPressed: () => _handleBook(schedule),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isBooked
                                                  ? AppColors.cardBgLight
                                                  : (isFull ? AppColors.alertAmber : AppColors.primaryBlue),
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(120, 48),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: AppDimensions.buttonBorderRadius,
                                                side: BorderSide(
                                                  color: isBooked
                                                      ? AppColors.borderLight
                                                      : Colors.transparent,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              isBooked
                                                  ? 'Reservado ✓'
                                                  : (isFull ? 'Lista Espera' : 'Reservar'),
                                              style: AppTypography.style(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _schedules.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
