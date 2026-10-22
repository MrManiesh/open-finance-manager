import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkCanvas : const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          // Ambient Glow Orb 1 (Top Right - Indigo / Violet)
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppColors.accent : AppColors.accentLight)
                        .withOpacity(isDark ? 0.28 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Ambient Glow Orb 2 (Middle Left - Teal / Emerald)
          Positioned(
            top: 240,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppColors.primary : AppColors.primaryLight)
                        .withOpacity(isDark ? 0.22 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Ambient Glow Orb 3 (Bottom Right - Cyan / Teal)
          Positioned(
            bottom: 40,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyanAccent.withOpacity(isDark ? 0.18 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          child,
        ],
      ),
    );
  }
}
