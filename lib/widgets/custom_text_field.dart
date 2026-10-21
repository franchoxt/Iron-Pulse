import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final Widget? topRightWidget;
  final String? hintText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    this.topRightWidget,
    this.hintText,
    this.controller,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty || topRightWidget != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.style(
                    color: const Color(0xFFD1D5DB),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (topRightWidget != null) ...[
                const SizedBox(width: 8),
                topRightWidget!,
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: AppTypography.style(
              color: AppColors.textWhite,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppColors.primaryNeon,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: AppTypography.style(
                color: const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon:
                  prefixWidget ??
                  (prefixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 14, right: 10),
                          child: Icon(
                            prefixIcon,
                            color: const Color(0xFF94A3B8),
                            size: 20,
                          ),
                        )
                      : null),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 20,
              ),
              suffixIcon: suffixWidget != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: suffixWidget,
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
