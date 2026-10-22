import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final Color? borderColor;
  final Color? color;
  final Color? tintColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.12,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.border,
    this.borderColor,
    this.color,
    this.tintColor,
    this.gradient,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveColor = color ??
        (tintColor != null
            ? tintColor!.withOpacity(opacity)
            : (isDark
                ? Colors.white.withOpacity(opacity)
                : Colors.white.withOpacity(0.75)));

    final effectiveBorder = border ??
        Border.all(
          color: borderColor ??
              (tintColor != null
                  ? tintColor!.withOpacity(0.35)
                  : (isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.white.withOpacity(0.65))),
          width: 1.2,
        );

    final effectiveShadow = boxShadow ??
        [
          BoxShadow(
            color: isDark ? AppColors.glassDarkShadow : AppColors.glassLightShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ];

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: effectiveBorder,
              gradient: gradient ??
                  (tintColor != null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tintColor!.withOpacity(opacity * 1.5),
                            tintColor!.withOpacity(opacity * 0.6),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(opacity * 1.5),
                                  Colors.white.withOpacity(opacity * 0.6),
                                ]
                              : [
                                  Colors.white.withOpacity(0.85),
                                  Colors.white.withOpacity(0.60),
                                ],
                        )),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
