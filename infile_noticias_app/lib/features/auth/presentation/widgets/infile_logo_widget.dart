import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget del logo de Infile.
///
/// Intenta cargar el asset 'assets/images/infile_logo.png'.
/// Si no está disponible, muestra un placeholder corporativo con el nombre.
///
/// USO:
///   InfileLogoWidget(height: 64)
///   InfileLogoWidget(height: 80, showTagline: true)
class InfileLogoWidget extends StatelessWidget {
  /// Altura del logo. El ancho se ajusta proporcionalmente.
  final double height;

  /// Si mostrar la tagline debajo del logo.
  final bool showTagline;

  const InfileLogoWidget({
    super.key,
    this.height = 56,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Intentar cargar el logo real; mostrar placeholder si no existe.
        _LogoAsset(height: height),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Información que transforma',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mediumGray,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoAsset extends StatelessWidget {
  final double height;
  const _LogoAsset({required this.height});

  @override
  Widget build(BuildContext context) {
    // Intentar cargar el logo real del asset.
    // Si el archivo no existe, se muestra el fallback corporativo.
    return Image.asset(
      'assets/images/infile_logo.png',
      height: height,
      errorBuilder: (_, __, ___) => _LogoFallback(height: height),
    );
  }
}

/// Placeholder corporativo del logo de Infile.
/// Se elimina cuando se integre el logo real.
class _LogoFallback extends StatelessWidget {
  final double height;
  const _LogoFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.infileBlueLight,
        borderRadius: BorderRadius.circular(height * 0.2),
      ),
      child: Center(
        child: Text(
          'INFILE',
          style: TextStyle(
            fontSize: height * 0.5,
            fontWeight: FontWeight.w900,
            color: AppColors.infileBlue,
            letterSpacing: height * 0.12,
          ),
        ),
      ),
    );
  }
}
