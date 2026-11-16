import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores extraídas do protótipo Figma do SecureLab.
class AppColors {
  static const navy = Color(0xFF0B1F33); // cabeçalho, textos fortes
  static const blue = Color(0xFF1690C7); // cor da marca
  static const background = Color(0xFFDDDDDD); // fundo das telas
  static const card = Color(0xFFD9D9D9); // cards
  static const tabBar = Color(0xFFD4D4D4); // barra de abas
  static const footer = Color(0xFFFAFAFA); // barra de navegação
  static const gray = Color(0xFF666666); // textos secundários
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFFF4545);
  static const yellowText = Color(0xFFA3931A);
  static const yellow = Color(0xFFD8C42C);

  /// Campos sobre o fundo azul-marinho (rgba(217,217,217,0.1)).
  static const fieldOnNavy = Color(0x1AD9D9D9);
  /// Placeholder sobre o azul-marinho (rgba(221,221,221,0.51)).
  static const hintOnNavy = Color(0x82DDDDDD);
  /// Botão do sino (rgba(221,221,221,0.2)).
  static const bellBox = Color(0x33DDDDDD);

  static const shadow = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 4),
  ];

  /// Fundo translúcido (20%) de uma cor, usado nos chips e ícones dos cards.
  static Color tint(Color c) => c.withAlpha(0x33);

  /// Cores dos avatares (iguais às do protótipo).
  static const avatars = [
    Color(0xFF1690C7),
    Color(0xFF16A34A),
    Color(0xFF36C7BF),
    Color(0xFF173F66),
  ];
  static Color avatarFor(int id) => avatars[id.abs() % avatars.length];
}

class AppText {
  static TextStyle bold(double size, [Color color = AppColors.navy]) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle regular(double size, [Color color = AppColors.navy]) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w400, color: color);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: AppText.bold(18, Colors.white),
      ),
    ),
  );
}

/// Iniciais para avatares: "Ana Oliveira" -> "AO".
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String two(int n) => n.toString().padLeft(2, '0');
String formatHour(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String formatDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
String isoDay(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
