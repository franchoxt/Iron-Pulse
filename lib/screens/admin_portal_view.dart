import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Portal de Administrador & Gestión de Estudiantes (Check-in)
/// Basado en .agents/rules/tablas-supabase.md (Punto 4: Admin Portal & Stats y Gestión de Estudiantes)
class AdminPortalView extends StatefulWidget {
  const AdminPortalView({super.key});

  @override
  State<AdminPortalView> createState() => _AdminPortalViewState();
}

class _AdminPortalViewState extends State<AdminPortalView> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'occupancyRate': '0.0',
    'totalCapacity': 0,
    'totalConfirmed': 0,
    'happeningNowCount': 0,
  };

  // Lista de estudiantes demo para el check-in presencial
  final List<Map<String, dynamic>> _students = [
    {
      'id': 'st-1',
      'name': 'Javier Rodríguez',
      'email': 'javier@pulse.com',
      'status': 'confirmed',
      'isPresent': true,
      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
    },
    {
      'id': 'st-2',
      'name': 'Sofía Morales',
      'email': 'sofia.m@fitness.org',
      'status': 'confirmed',
      'isPresent': false,
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
    },
    {
      'id': 'st-3',
      'name': 'Mateo Herrera',
      'email': 'mateo.h@iron.dev',
      'status': 'confirmed',
      'isPresent': true,
      'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
    },
    {
      'id': 'st-4',
      'name': 'Valentina Silva',
      'email': 'valentina@pulse.com',
      'status': 'waitlist',
      'isPresent': false,
      'avatar': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=100',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await DatabaseService.instance.getAdminStats();

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCheckIn(Map<String, dynamic> student) async {
    final newStatus = !(student['isPresent'] as bool);
    setState(() {
      student['isPresent'] = newStatus;
    });

    try {
      await DatabaseService.instance.checkInStudent(
        bookingId: student['id'] as String,
        isPresent: newStatus,
      );
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: newStatus ? AppColors.successGreen : AppColors.alertAmber,
          ),
        ),
        content: Row(
          children: [
            Icon(
              newStatus ? Icons.check_circle_rounded : Icons.person_remove_rounded,
              color: newStatus ? AppColors.successGreen : AppColors.alertAmber,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              newStatus
                  ? 'Check-in: ${student['name']} marcado como presente ✓'
                  : '${student['name']} desmarcado de asistencia',
              style: AppTypography.style(color: AppColors.textWhite, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    final double occupancy = double.tryParse(_stats['occupancyRate'].toString()) ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadAdminData,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portal de Admin',
                          style: AppTypography.style(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monitoreo y Control de Sesiones',
                          style: AppTypography.style(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: AppDimensions.chipBorderRadius,
                        border: Border.all(color: AppColors.primaryBlue),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: AppColors.primaryBlue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'ROL: ADMIN',
                            style: AppTypography.style(
                              color: AppColors.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 1. STATS: Occupancy Rate & Happening Now (Regla 4)
                Row(
                  children: [
                    // Occupancy Rate Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: AppDimensions.cardBorderRadius,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tasa de Ocupación',
                                  style: AppTypography.style(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Icon(Icons.pie_chart_rounded, color: AppColors.primaryBlue, size: 16),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$occupancy%',
                              style: AppTypography.style(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textWhite,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (occupancy / 100).clamp(0.0, 1.0),
                                backgroundColor: AppColors.cardBgLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  occupancy > 80 ? AppColors.alertAmber : AppColors.successGreen,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_stats['totalConfirmed']} de ${_stats['totalCapacity']} cupos',
                              style: AppTypography.style(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Happening Now Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: AppDimensions.cardBorderRadius,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Happening Now',
                                  style: AppTypography.style(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.successGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_stats['happeningNowCount']}',
                              style: AppTypography.style(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textWhite,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withValues(alpha: 0.15),
                                borderRadius: AppDimensions.chipBorderRadius,
                              ),
                              child: Text(
                                'Sesiones en curso',
                                style: AppTypography.style(
                                  fontSize: 11,
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Control activo',
                              style: AppTypography.style(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. GESTIÓN DE ESTUDIANTES (Check-in con is_present)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gestión de Asistencia (Check-in)',
                      style: AppTypography.style(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textWhite,
                      ),
                    ),
                    Text(
                      '${_students.where((s) => s['isPresent'] == true).length}/${_students.length} presentes',
                      style: AppTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Marca quién llegó a la sesión para registrar su presencia (is_present)',
                  style: AppTypography.style(fontSize: 12, color: AppColors.textSecondary),
                ),

                const SizedBox(height: 14),

                // Lista de Estudiantes
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _students.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final isPresent = student['isPresent'] as bool;
                    final isWaitlist = student['status'] == 'waitlist';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPresent
                              ? AppColors.successGreen.withValues(alpha: 0.5)
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(student['avatar'] as String),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      student['name'] as String,
                                      style: AppTypography.style(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (isWaitlist)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.alertAmber.withValues(alpha: 0.2),
                                          borderRadius: AppDimensions.chipBorderRadius,
                                        ),
                                        child: Text(
                                          'Waitlist',
                                          style: AppTypography.style(
                                            color: AppColors.alertAmber,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student['email'] as String,
                                  style: AppTypography.style(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Botón interactivo de Check-in
                          GestureDetector(
                            onTap: () => _toggleCheckIn(student),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? AppColors.successGreen
                                    : AppColors.cardBgLight,
                                borderRadius: AppDimensions.buttonBorderRadius,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPresent ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isPresent ? Colors.white : AppColors.textSecondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isPresent ? 'Presente' : 'Check-in',
                                    style: AppTypography.style(
                                      color: isPresent ? Colors.white : AppColors.textLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
