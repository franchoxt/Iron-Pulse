import 'package:flutter/material.dart';
import 'class_listing_screen.dart';

export 'class_listing_screen.dart';

/// Vista de Horarios y Sesiones (Schedule / Class Listing) para IRON PULSE.
///
/// Implementa el diseño moderno de lista de clases ordenadas cronológicamente
/// desde la fecha más cercana a la más lejana, con selector de días y categorías.
class ScheduleView extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBack;

  const ScheduleView({
    super.key,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ClassListingScreen(
      showBackButton: showBackButton,
      onBack: onBack,
    );
  }
}
