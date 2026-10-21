import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Botón principal según guias-de-estilo-y-reglas-de-diseno.md:
/// Fondo azul #3B82F6, texto blanco, bordes redondeados (rounded-2xl / 16px), altura mínima de 48px.
class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool hasGlow;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.height = 48,
    this.hasGlow = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height < AppDimensions.minButtonHeight
        ? AppDimensions.minButtonHeight
        : height;

    return Container(
      width: double.infinity,
      height: effectiveHeight,
      decoration: BoxDecoration(
        borderRadius: AppDimensions.buttonBorderRadius,
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: AppColors.primaryBlue,
        borderRadius: AppDimensions.buttonBorderRadius,
        child: InkWell(
          borderRadius: AppDimensions.buttonBorderRadius,
          onTap: isLoading ? null : onPressed,
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
