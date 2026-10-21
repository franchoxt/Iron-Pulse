import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AuthTab { login, register }

class AuthSegmentedSwitch extends StatelessWidget {
  final AuthTab currentTab;
  final ValueChanged<AuthTab> onTabChanged;

  const AuthSegmentedSwitch({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = currentTab == AuthTab.login;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1E2532),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Login Tab
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTabChanged(AuthTab.login),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isLogin ? const Color(0xFF1C222E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isLogin
                      ? Border.all(
                          color: const Color(0xFF2C374A),
                          width: 1.2,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLogin) ...[
                      const Icon(
                        Icons.login_rounded,
                        color: AppColors.primaryNeon,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Iniciar Sesión',
                      style: AppTypography.style(
                        color: isLogin
                            ? AppColors.primaryNeon
                            : const Color(0xFF94A3B8),
                        fontSize: 13.5,
                        fontWeight:
                            isLogin ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Register Tab
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTabChanged(AuthTab.register),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isLogin
                      ? AppColors.primaryNeon
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLogin) ...[
                      const Icon(
                        Icons.person_add_alt_outlined,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Crear Cuenta',
                      style: AppTypography.style(
                        color: !isLogin
                            ? AppColors.textDark
                            : const Color(0xFF94A3B8),
                        fontSize: 13.5,
                        fontWeight:
                            !isLogin ? FontWeight.w800 : FontWeight.w500,
                      ),
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
