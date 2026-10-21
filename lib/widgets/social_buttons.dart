import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'social_icons.dart';

class SocialIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;

  const SocialIconButton({
    super.key,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class SocialLoginRow extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final VoidCallback? onOtherTap;

  const SocialLoginRow({
    super.key,
    this.onGoogleTap,
    this.onAppleTap,
    this.onOtherTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SocialIconButton(
          icon: const GoogleIconWidget(size: 20, color: Color(0xFFE2E8F0)),
          onTap: onGoogleTap,
        ),
        const SizedBox(width: 12),
        SocialIconButton(
          icon: const AppleIconWidget(size: 22, color: Color(0xFFE2E8F0)),
          onTap: onAppleTap,
        ),
        const SizedBox(width: 12),
        SocialIconButton(
          icon: const CrosshairIconWidget(size: 20, color: Color(0xFFE2E8F0)),
          onTap: onOtherTap,
        ),
      ],
    );
  }
}

class WideSocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const WideSocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AppTypography.style(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialSignUpRow extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;

  const SocialSignUpRow({
    super.key,
    this.onGoogleTap,
    this.onAppleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        WideSocialButton(
          icon: const GoogleIconWidget(size: 18, color: Color(0xFFE2E8F0)),
          label: 'Google',
          onTap: onGoogleTap,
        ),
        const SizedBox(width: 12),
        WideSocialButton(
          icon: const AppleIconWidget(size: 20, color: Color(0xFFE2E8F0)),
          label: 'Apple',
          onTap: onAppleTap,
        ),
      ],
    );
  }
}
