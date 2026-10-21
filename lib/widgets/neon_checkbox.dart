import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeonCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const NeonCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: value ? AppColors.primaryNeon : const Color(0xFF1A1F29),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppColors.primaryNeon : const Color(0xFF2E384A),
            width: 1.5,
          ),
        ),
        child: value
            ? const Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.textDark,
                ),
              )
            : null,
      ),
    );
  }
}
