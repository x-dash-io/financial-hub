import 'package:flutter/material.dart';

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x1A0F1C2C), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0D0F1C2C), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x120F1C2C), blurRadius: 14, offset: Offset(0, 6)),
  ];
}
