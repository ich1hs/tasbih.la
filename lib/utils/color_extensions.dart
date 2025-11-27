import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// Creates a new color with the given alpha value (0.0 to 1.0)
  /// Replacement for deprecated withOpacity
  Color withAlpha2(double opacity) {
    return withValues(alpha: opacity);
  }
}
