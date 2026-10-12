import 'package:flutter/material.dart';
import 'colores.dart';

ThemeData crearTemaOscuro() {
  final esquema = ColorScheme.fromSeed(seedColor: ColoresApp.naranjaOscuro, brightness: Brightness.dark).copyWith(
    primary: ColoresApp.naranjaOscuro,
    secondary: ColoresApp.rojoOscuro,
    surface: ColoresApp.tarjetaOscura,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: ColoresApp.fondoOscuro,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColoresApp.fondoOscuro,
      foregroundColor: ColoresApp.textoOscuro,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: ColoresApp.textoOscuro),
    ),
    cardTheme: CardThemeData(color: ColoresApp.tarjetaOscura, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dividerColor: ColoresApp.separadorOscuro,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColoresApp.naranjaOscuro, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 50), backgroundColor: ColoresApp.naranjaOscuro, foregroundColor: ColoresApp.fondoOscuro)),
  );
}
