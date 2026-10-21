import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ObjectiveData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const ObjectiveData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class ObjectiveCard extends StatelessWidget {
  final ObjectiveData data;
  final bool isSelected;
  final VoidCallback onTap;

  const ObjectiveCard({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF162112) : const Color(0xFF131720),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : const Color(0xFF1E2532),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNeon.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF26391A)
                    : const Color(0xFF1C222E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                data.icon,
                color: isSelected ? AppColors.primaryNeon : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(
                      color: AppColors.textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(
                      color: isSelected
                          ? AppColors.primaryNeon
                          : const Color(0xFF64748B),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
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
}
