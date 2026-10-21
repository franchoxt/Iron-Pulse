import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  bool get hasLength => password.length >= 8;
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get hasSymbol =>
      RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:/?.,><]').hasMatch(password);

  @override
  Widget build(BuildContext context) {
    // In mockup, all 3 are satisfied/optimal
    final count = (hasLength ? 1 : 0) + (hasNumber ? 1 : 0) + (hasSymbol ? 1 : 0);
    // If empty in demo, we can show active as in mockup or calculate dynamically
    final activeBars = password.isEmpty ? 3 : count;

    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: List.generate(3, (index) {
            final isActive = index < activeBars;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index < 2 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryNeon
                      : const Color(0xFF222936),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildCheckItem(
              '8+ carácteres',
              password.isEmpty ? true : hasLength,
            ),
            _buildCheckItem(
              '1 número',
              password.isEmpty ? true : hasNumber,
            ),
            _buildCheckItem(
              '1 símbolo',
              password.isEmpty ? true : hasSymbol,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text, bool checked) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 14,
          color: checked ? AppColors.primaryNeon : const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.style(
            color: checked ? AppColors.primaryNeon : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
