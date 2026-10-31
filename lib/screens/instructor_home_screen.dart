import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'instructor_dashboard_view.dart';
import 'instructor_edit_profile_screen.dart';
import 'instructor_schedule_view.dart';

/// Pantalla Principal (Home) para el Rol de Instructor en IRON PULSE.
///
/// Implementa una barra de navegación inferior moderna con 3 pestañas:
/// 1. Dashboard: Métricas de clases de hoy, alumnos y próxima sesión.
/// 2. Horarios (Schedule): Clases asignadas al instructor con acceso a asistencia.
/// 3. Mi Perfil: Autogestión de biografía, especialidades y vista pública.
class InstructorHomeScreen extends StatefulWidget {
  final String? instructorName;

  const InstructorHomeScreen({
    super.key,
    this.instructorName,
  });

  @override
  State<InstructorHomeScreen> createState() => _InstructorHomeScreenState();
}

class _InstructorHomeScreenState extends State<InstructorHomeScreen> {
  int _currentNavIndex = 0;

  void _onNavigateTab(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_currentNavIndex) {
      case 1:
        currentBody = const InstructorScheduleView();
        break;
      case 2:
        currentBody = const InstructorEditProfileScreen();
        break;
      case 0:
      default:
        currentBody = InstructorDashboardView(onNavigateTab: _onNavigateTab);
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: SafeArea(
        bottom: false,
        child: currentBody,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.calendar_month_outlined,
                label: 'Schedule',
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.person_outline_rounded,
                label: 'Profile',
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
      onTap: () => setState(() => _currentNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00BCEB).withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF00BCEB)
                    : const Color(0xFF6E7C90),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.style(
                color: isSelected
                    ? const Color(0xFF00BCEB)
                    : const Color(0xFF6E7C90),
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

