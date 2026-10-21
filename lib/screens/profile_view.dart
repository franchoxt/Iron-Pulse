import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Vista de Perfil y Comunicaciones
/// Basado en .agents/rules/tablas-supabase.md (Profiles & Messages)
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final email = user?.email ?? 'javier@pulse.com';
    final name = email.split('@').first.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi Perfil',
                style: AppTypography.style(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta de Perfil
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: AppDimensions.cardBorderRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.cardBgLight,
                          child: const Icon(Icons.person_rounded,
                              size: 36, color: AppColors.primaryBlue),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cardBg, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.style(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: AppTypography.style(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: AppDimensions.chipBorderRadius,
                            ),
                            child: Text(
                              'MIEMBRO PRO • ATLETA',
                              style: AppTypography.style(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Comunicaciones y Mensajes (Regla 5 de tablas-supabase.md)
              Text(
                'Comunicaciones & Alertas',
                style: AppTypography.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 10),

              _buildMessageTile(
                title: 'Cupo liberado en lista de espera',
                content: 'Se liberó un lugar para la sesión de CrossFit WOD de las 18:00.',
                category: 'Waitlist',
                categoryColor: AppColors.alertAmber,
                time: 'Hace 10 min',
              ),
              const SizedBox(height: 10),
              _buildMessageTile(
                title: 'Pago mensual procesado con éxito',
                content: 'Tu membresía Iron Pulse Pro ha sido renovada correctamente.',
                category: 'Payment',
                categoryColor: AppColors.successGreen,
                time: 'Ayer',
              ),
              const SizedBox(height: 10),
              _buildMessageTile(
                title: 'Nuevo horario de fin de semana',
                content: 'Se agregaron 2 nuevas sesiones de Power Yoga los sábados por la mañana.',
                category: 'General',
                categoryColor: AppColors.primaryBlue,
                time: 'Hace 3 días',
              ),

              const SizedBox(height: 24),

              // Botón de Cerrar Sesión
              ElevatedButton(
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/auth');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardBg,
                  foregroundColor: AppColors.errorRed,
                  minimumSize: const Size(double.infinity, 48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.buttonBorderRadius,
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 18, color: AppColors.errorRed),
                    const SizedBox(width: 8),
                    Text(
                      'Cerrar Sesión',
                      style: AppTypography.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.errorRed,
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

  Widget _buildMessageTile({
    required String title,
    required String content,
    required String category,
    required Color categoryColor,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: AppDimensions.chipBorderRadius,
                  border: Border.all(color: categoryColor, width: 0.8),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: AppTypography.style(
                    color: categoryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                time,
                style: AppTypography.style(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.style(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            content,
            style: AppTypography.style(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
