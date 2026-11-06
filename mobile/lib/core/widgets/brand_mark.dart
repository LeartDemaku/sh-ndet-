import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Marka e Shëndet+ në një katror me gradient.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 46, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Shëndet+',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: onDark
              ? const LinearGradient(colors: [Colors.white, Color(0xFFCCFBF1)])
              : ShendetGradients.primary,
          borderRadius: BorderRadius.circular(size * 0.32),
          boxShadow: [
            BoxShadow(
              color: ShendetColors.primary.withValues(
                alpha: onDark ? 0.0 : 0.25,
              ),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: size * 0.48,
              color: Colors.white,
            ),
            Positioned(
              right: size * 0.12,
              bottom: size * 0.12,
              child: Container(
                width: size * 0.31,
                height: size * 0.31,
                decoration: BoxDecoration(
                  color: ShendetColors.emergency,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: size * 0.22,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Emri i markës me peshë të fortë.
class BrandName extends StatelessWidget {
  const BrandName({super.key, this.onDark = false, this.fontSize = 22});

  final bool onDark;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
    'Shëndet+',
    style: TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      height: 1.1,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: onDark ? Colors.white : context.palette.ink,
    ),
  );
}
