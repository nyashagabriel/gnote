import 'package:flutter/material.dart';

class GColors {
  GColors._();

  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceHigh = Color(0xFF242424);
  static const Color border = Color(0xFF2A2A2A);

  static const Color orange = Color(0xFFF0A500);
  static const Color orangeDim = Color(0x33F0A500);
  static const Color azure = Color(0xFF3FA9F5);
  static const Color azureDim = Color(0x333FA9F5);

  static const Color success = Color(0xFF52E0A0);
  static const Color successDim = Color(0x2252E0A0);
  static const Color danger = Color(0xFFE05252);
  static const Color dangerDim = Color(0x22E05252);
  static const Color warning = Color(0xFFF0C040);
  static const Color warningDim = Color(0x22F0C040);

  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textMuted = Color(0xFF9A9A9A);
  static const Color textDisabled = Color(0xFF6A6A6A);

  static const Map<String, Color> category = {
    'career': azure,
    'project': orange,
    'learning': success,
    'personal': Color(0xFFC05CE0),
    'other': Color(0xFF888888),
  };
}

class GSpacing {
  GSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double pagePadding = 20.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 10.0;
  static const double inputRadius = 10.0;
}

class GText {
  GText._();

  static const String fontFamily = 'monospace';

  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: GColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: GColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: GColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: GColors.textMuted,
    letterSpacing: 1.5,
  );

  static const TextStyle muted = TextStyle(
    fontSize: 13,
    color: GColors.textMuted,
    height: 1.5,
  );

  static const TextStyle accent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: GColors.orange,
  );

  static const TextStyle danger = TextStyle(
    fontSize: 13,
    color: GColors.danger,
  );
}
