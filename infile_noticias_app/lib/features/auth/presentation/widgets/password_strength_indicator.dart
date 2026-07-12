import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Indicador visual de fortaleza de contraseña.
///
/// Muestra una barra segmentada en 4 niveles:
/// 🔴 Muy débil → 🟠 Débil → 🟡 Regular → 🟢 Fuerte
///
/// Se actualiza en tiempo real mientras el usuario escribe.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _calculateStrength(password);
    final (label, color) = _getLabelAndColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Barra segmentada
        Row(
          children: List.generate(4, (index) {
            final isFilled = index < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isFilled ? color : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Etiqueta de fortaleza
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(label),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Calcula el nivel de fortaleza (1–4) basado en los criterios de la política.
  int _calculateStrength(String pwd) {
    int score = 0;
    if (pwd.length >= 13) score++;
    if (pwd.contains(RegExp(r'[A-Z]'))) score++;
    if (pwd.contains(RegExp(r'[0-9]'))) score++;
    if (pwd.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  (String label, Color color) _getLabelAndColor(int strength) {
    return switch (strength) {
      1 => ('Muy débil', AppColors.error),
      2 => ('Débil', const Color(0xFFF59E0B)),
      3 => ('Regular', const Color(0xFF3B82F6)),
      4 => ('Fuerte ✓', AppColors.success),
      _ => ('', AppColors.border),
    };
  }
}
