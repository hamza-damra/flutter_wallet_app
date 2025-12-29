import 'package:flutter/material.dart';

class AppShadows {
  static final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withAlpha(13), // 0.05 * 255 = ~13
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> button = [
    BoxShadow(
      color: const Color(0xFF8B5A2B).withAlpha(51), // 0.2 * 255 = ~51
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static final List<BoxShadow> floating = [
    BoxShadow(
      color: Colors.black.withAlpha(26), // 0.1 * 255 = ~26
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];
}
