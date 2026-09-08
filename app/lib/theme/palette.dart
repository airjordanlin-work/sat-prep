import 'package:flutter/material.dart';

/// Shared design tokens across screens. Chosen deliberately to avoid the
/// "warm cream + terracotta accent" and "tinted near-black" combinations
/// that read as generic AI-generated defaults — a reading-room palette
/// instead: warm paper, ink, forest green, muted brick for negative states.
class AppPalette {
  AppPalette._();

  static const paper = Color(0xFFF1EFE9);
  static const ink = Color(0xFF1E2420);
  static const inkMuted = Color(0xFF5B645C);
  static const accent = Color(0xFF2C4A3D); // forest green — primary/positive
  static const down = Color(0xFF9C4A3D); // muted brick — negative/incorrect
  static const hairline = Color(0xFFDAD6CC);
}