import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'class_details_screen.dart';

/// Pantalla de Lista de Clases (Schedule / Class Listing) para IRON PULSE.
///
/// Características visuales y de diseño (basadas en la guía y captura de diseño):
/// - Muestra todas las clases disponibles ordenadas de la fecha más cercana a la más lejana.
/// - Barra superior con subtítulo "IRON PULSE", título "Schedule" y botón de búsqueda interactivo.
/// - Selector horizontal de días con cápsula activa en cyan vibrante.
/// - Selector horizontal de categorías con chip activo en blanco y fondo oscuro inactivo.
/// - Contador dinámico de sesiones disponibles ("X available").
/// - Tarjetas de clase asimétricas con información completa a la izquierda y fotografía a la derecha.
/// - Estado dinámico de reserva: "Book", "Join Waitlist" o "Cancelar" si ya está reservada.
/// - Vinculada directamente con la pantalla Home del cliente.
class ClassListingScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBack;

  const ClassListingScreen({
    super.key,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  State<ClassListingScreen> createState() => _ClassListingScreenState();
}

class _ClassListingScreenState extends State<ClassListingScreen> {
  bool _isLoading = true;
  List<ClassScheduleModel> _allSchedules = [];
  List<CategoryModel> _categories = [];
  final Set<String> _bookedScheduleIds = {};

  // Filtros
  DateTime? _selectedDate; // null muestra todas las fechas (de la más cercana a la lejana)
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await DatabaseService.instance.getCategories();
      final schedules = await DatabaseService.instance.getSchedules();
      final userBookings = await DatabaseService.instance.getUserBookings();

      // Ordenar explícitamente de la fecha más cercana a la más lejana
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));

      final bookedIds = userBookings
          .where((b) => b.status != BookingStatus.cancelled)
          .map((b) => b.scheduleId)
          .toSet();

      if (mounted) {
        setState(() {
          _categories = categories;
          _allSchedules = schedules;
          _bookedScheduleIds.clear();
          _bookedScheduleIds.addAll(bookedIds);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ClassScheduleModel> get _filteredSchedules {
    return _allSchedules.where((schedule) {
      // 1. Filtro por fecha seleccionada
      if (_selectedDate != null) {
        final st = schedule.startTime;
        final isSameDay = st.year == _selectedDate!.year &&
            st.month == _selectedDate!.month &&
            st.day == _selectedDate!.day;
        if (!isSameDay) return false;
      }

      // 2. Filtro por categoría
      if (_selectedCategoryId != 'all') {
        final matchesCatId = schedule.gymClass?.categoryId == _selectedCategoryId;
        final cat = _categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => const CategoryModel(id: '', name: ''),
        );
        final matchesCatName = cat.name.isNotEmpty &&
            (schedule.gymClass?.name.toLowerCase().contains(cat.name.toLowerCase()) ?? false);
        if (!matchesCatId && !matchesCatName) return false;
      }

      // 3. Filtro por búsqueda de texto
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final name = schedule.gymClass?.name.toLowerCase() ?? '';
        final instructor = schedule.instructor?.name.toLowerCase() ?? '';
        final location = schedule.locationName?.toLowerCase() ?? '';
        if (!name.contains(q) && !instructor.contains(q) && !location.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _openClassDetails(ClassScheduleModel schedule, bool isBooked) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClassDetailsScreen(
          schedule: schedule,
          isInitialBooked: isBooked,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        if (updated) {
          _bookedScheduleIds.add(schedule.id);
        } else {
          _bookedScheduleIds.remove(schedule.id);
        }
      });
      _loadData();
    }
  }

  Future<void> _promptCancelReservation(ClassScheduleModel schedule) async {
    final confirmed = await showDialog<bool>(
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
                '¿Deseas cancelar tu reserva para "${schedule.gymClass?.name ?? 'esta clase'}"? Se liberará tu lugar en la sesión.',
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

    if (confirmed == true) {
      try {
        await DatabaseService.instance.cancelBooking(schedule.id);
        if (!mounted) return;
        setState(() {
          _bookedScheduleIds.remove(schedule.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFEF4444)),
            ),
            content: const Text(
              'Reserva cancelada exitosamente.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cancelar: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDayLabel(DateTime? dt) {
    if (dt == null) return 'All Available Classes';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    if (target.isAtSameMomentAs(today)) {
      return "Today's Sessions";
    }

    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return "${weekdays[dt.weekday - 1]}'s Sessions";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSchedules;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryCyan,
          backgroundColor: const Color(0xFF161C26),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header Superior (GYM & CO. / IRON PULSE + Schedule + Búsqueda)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopHeader(),
                      if (_isSearchExpanded) ...[
                        const SizedBox(height: 14),
                        _buildSearchInput(),
                      ],
                    ],
                  ),
                ),
              ),

              // 2. Selector Horizontal de Días (Mon 12, Tue 13...)
              SliverToBoxAdapter(
                child: _buildDaysHorizontalStrip(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 3. Selector Horizontal de Categorías (All Classes, Strength, Cardio, Yoga...)
              SliverToBoxAdapter(
                child: _buildCategoriesFilterStrip(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 22)),

              // 4. Encabezado de Sección ("Today's Sessions" • "4 available")
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDayLabel(_selectedDate),
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '${filtered.length} available',
                        style: AppTypography.style(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // 5. Lista de Tarjetas de Clases
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryCyan),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF161C26),
                              border: Border.all(color: const Color(0xFF263346)),
                            ),
                            child: const Icon(
                              Icons.event_busy_rounded,
                              color: Color(0xFF64748B),
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay clases disponibles',
                            style: AppTypography.style(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedDate != null
                                ? 'No se encontraron sesiones programadas para este día.'
                                : 'Pronto se añadirán nuevas clases al calendario.',
                            textAlign: TextAlign.center,
                            style: AppTypography.style(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                          if (_selectedDate != null || _selectedCategoryId != 'all') ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                  _selectedCategoryId = 'all';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Ver todas las clases'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final schedule = filtered[index];
                        final isBooked = _bookedScheduleIds.contains(schedule.id);
                        return _buildClassCard(schedule, isBooked);
                      },
                      childCount: filtered.length,
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
  // WIDGET: TOP HEADER (IRON PULSE / Schedule + Search Icon)
  // ===========================================================================
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Títulos
        Row(
          children: [
            if (widget.showBackButton || Navigator.canPop(context)) ...[
              GestureDetector(
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161C26),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF263346)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IRON PULSE',
                  style: AppTypography.style(
                    color: const Color(0xFF00A3E0),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Schedule',
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Botón de búsqueda circular
        GestureDetector(
          onTap: () {
            setState(() {
              _isSearchExpanded = !_isSearchExpanded;
              if (!_isSearchExpanded) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF161C26),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isSearchExpanded
                    ? const Color(0xFF00A3E0)
                    : const Color(0xFF263346),
                width: 1.2,
              ),
            ),
            child: Icon(
              _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
              color: _isSearchExpanded ? const Color(0xFF00A3E0) : Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // WIDGET: CAMPO DE BÚSQUEDA EXPANDIBLE
  // ===========================================================================
  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131924),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263346), width: 1.2),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por clase, coach o estudio...',
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: SELECTOR HORIZONTAL DE DÍAS (Mon 12, Tue 13...)
  // ===========================================================================
  Widget _buildDaysHorizontalStrip() {
    final now = DateTime.now();
    // Generar los próximos 14 días a partir de hoy
    final days = List.generate(14, (i) => now.add(Duration(days: i)));

    const weekdaysAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: days.length + 1, // +1 para el chip "All"
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          // Primer elemento: Chip "All"
          if (index == 0) {
            final isAllSelected = _selectedDate == null;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedDate = null);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 62,
                decoration: BoxDecoration(
                  color: isAllSelected ? const Color(0xFF00A3E0) : const Color(0xFF131924),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAllSelected ? const Color(0xFF00A3E0) : const Color(0xFF263346),
                    width: 1.2,
                  ),
                  boxShadow: isAllSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00A3E0).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ALL',
                      style: AppTypography.style(
                        color: isAllSelected ? Colors.white : const Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: isAllSelected ? Colors.white : const Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
            );
          }

          final day = days[index - 1];
          final isSelected = _selectedDate != null &&
              day.year == _selectedDate!.year &&
              day.month == _selectedDate!.month &&
              day.day == _selectedDate!.day;

          final weekdayName = weekdaysAbbr[day.weekday - 1];
          final dayNum = day.day.toString();

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedDate = null; // Toggle para ver todas
                } else {
                  _selectedDate = day;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 62,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00A3E0) : const Color(0xFF131924),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00A3E0) : const Color(0xFF263346),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00A3E0).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayName,
                    style: AppTypography.style(
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNum,
                    style: AppTypography.style(
                      color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET: SELECTOR HORIZONTAL DE CATEGORÍAS (All Classes, Strength...)
  // ===========================================================================
  Widget _buildCategoriesFilterStrip() {
    final allCategoryOptions = [
      {'id': 'all', 'name': 'All Classes'},
      ..._categories.map((c) => {'id': c.id, 'name': c.name}),
    ];

    // Fallbacks si categorías en Supabase aún están vacías
    if (_categories.isEmpty) {
      allCategoryOptions.addAll([
        {'id': 'cat-strength', 'name': 'Strength'},
        {'id': 'cat-cardio', 'name': 'Cardio'},
        {'id': 'cat-yoga', 'name': 'Yoga'},
        {'id': 'cat-hiit', 'name': 'HIIT'},
      ]);
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: allCategoryOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = allCategoryOptions[index];
          final catId = cat['id']!;
          final catName = cat['name']!;
          final isSelected = _selectedCategoryId == catId;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryId = catId);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF161C26),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? Colors.white : const Color(0xFF263346),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                catName,
                style: AppTypography.style(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET: TARJETA DE CLASE ASIMÉTRICA (FOTO A LA DERECHA)
  // ===========================================================================
  Widget _buildClassCard(ClassScheduleModel schedule, bool isBooked) {
    final gymClass = schedule.gymClass;
    final instructor = schedule.instructor;

    final availableSpots = isBooked
        ? (schedule.availableSpots > 0 ? schedule.availableSpots - 1 : 0)
        : schedule.availableSpots;
    final isFull = availableSpots <= 0;

    final timeStr = _formatTime(schedule.startTime);
    final durationStr = '${gymClass?.durationMinutes ?? 45}m';

    final tagText = gymClass?.intensity.displayName.toUpperCase() ?? 'HIIT';

    final imageUrl = (gymClass?.imageUrl != null && gymClass!.imageUrl!.isNotEmpty)
        ? gymClass.imageUrl!
        : 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600';

    return GestureDetector(
      onTap: () => _openClassDetails(schedule, isBooked),
      child: Container(
        height: 148,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF131924),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isBooked
                ? const Color(0xFF00A3E0).withValues(alpha: 0.6)
                : const Color(0xFF1E293B),
            width: isBooked ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              // 1. Columna izquierda: Información y CTA
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tag de clase + Horario
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tagText,
                              style: AppTypography.style(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$timeStr • $durationStr',
                            style: AppTypography.style(
                              color: const Color(0xFF00A3E0),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      // Título de la clase
                      Text(
                        gymClass?.name ?? 'Inferno Intervals',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),

                      // Instructor
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF94A3B8),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'with ${instructor?.name ?? 'Sarah J.'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.style(
                                color: const Color(0xFF94A3B8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Fila inferior: Availability + Botón Acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Indicador de disponibilidad
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isFull ? 'STATUS' : 'AVAILABILITY',
                                style: AppTypography.style(
                                  color: const Color(0xFF64748B),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (isBooked)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF22C55E),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reservado',
                                      style: AppTypography.style(
                                        color: const Color(0xFF22C55E),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              else if (isFull)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.block_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Full',
                                      style: AppTypography.style(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              else if (availableSpots <= 3)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$availableSpots spots left',
                                      style: AppTypography.style(
                                        color: const Color(0xFFF59E0B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF00A3E0),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$availableSpots / ${schedule.capacity}',
                                      style: AppTypography.style(
                                        color: const Color(0xFF00A3E0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // Botón CTA (Book / Join Waitlist / Cancelar)
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                if (isBooked) {
                                  _promptCancelReservation(schedule);
                                } else {
                                  _openClassDetails(schedule, isBooked);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBooked
                                    ? const Color(0xFFDC2626)
                                    : (isFull
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF00A3E0)),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: isFull && !isBooked
                                      ? const BorderSide(color: Color(0xFF334155))
                                      : BorderSide.none,
                                ),
                              ),
                              child: Text(
                                isBooked
                                    ? 'Cancelar'
                                    : (isFull ? 'Join Waitlist' : 'Book'),
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

              // 2. Columna derecha: Fotografía de la clase
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF1E293B),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: Color(0xFF475569),
                          size: 32,
                        ),
                      ),
                    ),
                    // Gradiente horizontal sutil para fundir la imagen con la tarjeta
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF131924),
                              const Color(0xFF131924).withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.25, 0.6],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
