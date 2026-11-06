/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:ui';

import 'package:flutter/material.dart';

/// Design tokens shared by the glass UI.
abstract class Glass {
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double blurSigma = 28;

  static const Color accent = Color(0xFF0A84FF);
  static const Color green = Color(0xFF30D158);
  static const Color red = Color(0xFFFF453A);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color scaffold = Color(0xFF0B0F17);

  static Color fill([double opacity = 0.10]) => Colors.white.withOpacity(opacity);

  static Color stroke([double opacity = 0.18]) => Colors.white.withOpacity(opacity);

  static final List<BoxShadow> restShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static final List<BoxShadow> focusShadow = [
    BoxShadow(color: Colors.white.withOpacity(0.22), blurRadius: 28, spreadRadius: 1),
    BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 24, offset: Offset(0, 12)),
  ];

  static TextStyle sectionTitle(BuildContext context) => Theme.of(context).textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        shadows: [Shadow(color: Colors.black.withOpacity(0.6), offset: Offset(0, 1), blurRadius: 10)],
      );
}

/// Top-edge specular highlight, the "liquid" sheen of glass surfaces.
/// Cheap alternative to per-card BackdropFilter: pure gradient, animatable
/// opacity for focus states. Always wrapped in IgnorePointer.
class SpecularHighlight extends StatelessWidget {
  final BorderRadius borderRadius;
  final double opacity;
  final Duration duration;

  const SpecularHighlight({
    Key? key,
    required this.borderRadius,
    this.opacity = 1,
    this.duration = Duration.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedOpacity(
          duration: duration,
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment(0, 0.6),
                colors: [Glass.fill(0.18), Glass.fill(0.04), Glass.fill(0)],
                stops: [0, 0.35, 1],
              ),
            ),
          ),
        ),
      );
}

/// Frosted, translucent surface with a hairline border. One [BackdropFilter]
/// per instance: keep the count low on TV hardware.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GlassContainer({
    Key? key,
    required this.child,
    this.radius = Glass.radiusMedium,
    this.padding = EdgeInsets.zero,
    this.blur = Glass.blurSigma,
    this.opacity = 0.10,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shape = borderRadius ?? BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: shape,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Glass.fill(opacity + 0.08), Glass.fill(opacity)],
            ),
            border: Border.all(color: Glass.stroke(), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
