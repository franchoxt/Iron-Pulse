import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'schedule_view.dart';
import 'admin_portal_view.dart';
import 'profile_view.dart';

/// Pantalla Principal del Dashboard de Administrador
/// Diseñada exactamente según la interfaz de administración de IRON PULSE
class AdminDashboardScreen extends StatefulWidget {
  final String adminName;

  const AdminDashboardScreen({
    super.key,
    this.adminName = 'Coach',
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentNavIndex = 0;
  Map<String, dynamic> _stats = {
    'occupancyRate': '92',
    'totalCapacity': 20,
    'totalConfirmed': 15,
    'happeningNowCount': 1,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DatabaseService.instance.getAdminStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (_) {}
  }

  void _showCreateClassModal() {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    final capacityController = TextEditingController(text: '20');
    String selectedIntensity = 'High';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF161A23),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Color(0xFF2B3446), width: 1),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Crear Nueva Clase',
                          style: AppTypography.style(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre de la Clase (ej. HIIT w/ Sarah)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2B3446)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Duración (min)',
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF2B3446)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: capacityController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Capacidad Cupos',
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF2B3446)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Intensidad',
                      style: AppTypography.style(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Low', 'Medium', 'High'].map((intensity) {
                        final isSelected = selectedIntensity == intensity;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(intensity),
                            selected: isSelected,
                            onSelected: (val) {
                              setModalState(() => selectedIntensity = intensity);
                            },
                            selectedColor: AppColors.primaryBlue,
                            backgroundColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryBlue : const Color(0xFF2B3446),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.cardBg,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Clase "${nameController.text.isNotEmpty ? nameController.text : 'HIIT'}" creada con éxito',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Guardar Clase',
                        style: AppTypography.style(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_currentNavIndex) {
      case 1:
        currentBody = const ScheduleView();
        break;
      case 2:
        currentBody = const AdminPortalView();
        break;
      case 3:
        currentBody = const ProfileView();
        break;
      case 0:
      default:
        currentBody = _buildAdminDashboard();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: currentBody,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ===========================================================================
  // CUERPO DEL DASHBOARD DE ADMINISTRADOR (EXACTO A LA IMAGEN)
  // ===========================================================================
  Widget _buildAdminDashboard() {
    final double occupancy = double.tryParse(_stats['occupancyRate'].toString()) ?? 92.0;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP APP BAR (Avatar con punto verde + Welcome Back / Admin Portal + Campana)
            _buildTopAppBar(),

            const SizedBox(height: 22),

            // 2. METRICAS PRINCIPALES: SCHEDULED CLASSES & OCCUPANCY RATE
            Row(
              children: [
                // Tarjeta 1: Scheduled Classes
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A23),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF222836)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icono Calendario + Chip "Today"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10283F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF13A4EC),
                                size: 18,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF182438),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Today',
                                style: AppTypography.style(
                                  color: const Color(0xFF60A5FA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Gran Número: 8
                        Text(
                          '8',
                          style: AppTypography.style(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Etiqueta
                        Text(
                          'Scheduled\nClasses',
                          style: AppTypography.style(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8E9BAE),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Tarjeta 2: Occupancy Rate
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A23),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF222836)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icono Pie Chart + Trend "+ 5%"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10283F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.pie_chart_rounded,
                                color: Color(0xFF13A4EC),
                                size: 18,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 16,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '5%',
                                  style: AppTypography.style(
                                    color: const Color(0xFF22C55E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Gran Número: 92%
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              occupancy.toInt().toString(),
                              style: AppTypography.style(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '%',
                              style: AppTypography.style(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8E9BAE),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Barra de progreso cian
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (occupancy / 100).clamp(0.0, 1.0),
                            backgroundColor: const Color(0xFF253347),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF13A4EC)),
                            minHeight: 5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Etiqueta
                        Text(
                          'Occupancy Rate',
                          style: AppTypography.style(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8E9BAE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 3. SEGUNDA FILA: TOTAL STUDENTS (142 +12%) & ACTIVE TYPES (24 types)
            Row(
              children: [
                // Total Students
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A23),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF222836)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL STUDENTS',
                          style: AppTypography.style(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7E8B9D),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '142',
                              style: AppTypography.style(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+12%',
                              style: AppTypography.style(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Active Types
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A23),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF222836)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE TYPES',
                          style: AppTypography.style(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7E8B9D),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '24',
                              style: AppTypography.style(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'types',
                              style: AppTypography.style(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF7E8B9D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4. SECCIÓN QUICK ACTIONS (+ Create Class / Calendar)
            Text(
              'QUICK ACTIONS',
              style: AppTypography.style(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF7E8B9D),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Botón "+ Create Class" (Azul Cian Brillante)
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF13A4EC).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13A4EC),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: _showCreateClassModal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF13A4EC),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Create Class',
                            style: AppTypography.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Botón "Calendar" (Tarjeta Oscura)
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF161A23),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF262D3D)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () {
                        setState(() => _currentNavIndex = 1);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xFFBDC8D1),
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Calendar',
                            style: AppTypography.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // 5. SECCIÓN HAPPENING NOW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HAPPENING NOW',
                  style: AppTypography.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7E8B9D),
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _currentNavIndex = 1);
                  },
                  child: Text(
                    'View All',
                    style: AppTypography.style(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF13A4EC),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // TARJETA DE CLASE EN VIVO (HIIT w/ Sarah, Badge LIVE, 15/20, Avatars, Manage Class)
            _buildLiveClassCard(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP APP BAR CON AVATAR Y BADGE DE NOTIFICACIÓN
  // ===========================================================================
  Widget _buildTopAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Avatar con indicador de estado verde
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF283244), width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                        backgroundColor: Color(0xFFE5C09B),
                        child: Icon(Icons.person, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0D14), width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // Textos: WELCOME BACK / Admin Portal
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME BACK',
                  style: AppTypography.style(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7E8B9D),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Admin Portal',
                  style: AppTypography.style(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Botón Notificaciones con punto azul
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF161A23),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF242C3D)),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF13A4EC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0A0D14), width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // TARJETA DE CLASE EN VIVO (HIIT w/ Sarah)
  // ===========================================================================
  Widget _buildLiveClassCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A23),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF222836)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen superior con atletas y badge • LIVE
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF212836),
                      child: const Center(
                        child: Icon(Icons.fitness_center_rounded, color: Color(0xFF13A4EC), size: 36),
                      ),
                    ),
                  ),
                ),

                // Dark Gradient
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),

                // Badge • LIVE en la esquina superior derecha
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEF4444), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'LIVE',
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Contenido inferior
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y Cupos (15/20)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HIIT w/ Sarah',
                        style: AppTypography.style(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132338),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '15',
                              style: AppTypography.style(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF13A4EC),
                              ),
                            ),
                            Text(
                              '/20',
                              style: AppTypography.style(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8E9BAE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Horario: 10:00 AM - 11:00 AM
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF7E8B9D),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '10:00 AM - 11:00 AM',
                        style: AppTypography.style(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8E9BAE),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Fila inferior: Avatares superpuestos (+12) & Botón Manage Class
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Avatares superpuestos
                      SizedBox(
                        height: 32,
                        child: Row(
                          children: [
                            _buildAvatarOverlap('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80', 0),
                            _buildAvatarOverlap('https://images.unsplash.com/photo-1517841905240-472988babdf9?w=80', -10),
                            _buildAvatarOverlap('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80', -10),
                            Transform.translate(
                              offset: const Offset(-30, 0),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B2433),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF161A23), width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    '+12',
                                    style: AppTypography.style(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF13A4EC),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botón texto: Manage Class
                      GestureDetector(
                        onTap: () {
                          setState(() => _currentNavIndex = 2);
                        },
                        child: Text(
                          'Manage Class',
                          style: AppTypography.style(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF13A4EC),
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
  }

  Widget _buildAvatarOverlap(String url, double leftOffset) {
    return Transform.translate(
      offset: Offset(leftOffset, 0),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF161A23), width: 1.5),
        ),
        child: ClipOval(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const CircleAvatar(
              backgroundColor: Color(0xFF263345),
              child: Icon(Icons.person, size: 14, color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BAR ADMIN (Home, Classes, Users, Settings)
  // ===========================================================================
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F131C),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2638), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.grid_view_rounded,
                label: 'Home',
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.fitness_center_rounded,
                label: 'Classes',
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.people_alt_rounded,
                label: 'Users',
              ),
              _buildBottomNavItem(
                index: 3,
                icon: Icons.settings_rounded,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF13A4EC).withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF13A4EC)
                    : const Color(0xFF6E7C90),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.style(
                color: isSelected
                    ? const Color(0xFF13A4EC)
                    : const Color(0xFF6E7C90),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
