import 'package:flutter/material.dart';
import 'colores.dart';

ThemeData crearTemaClaro() {
  final esquema = ColorScheme.fromSeed(seedColor: ColoresApp.naranjaClaro, brightness: Brightness.light).copyWith(
    primary: ColoresApp.naranjaClaro,
    secondary: ColoresApp.rojoClaro,
    surface: ColoresApp.tarjetaClara,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: ColoresApp.fondoClaro,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColoresApp.fondoClaro,
      foregroundColor: ColoresApp.textoClaro,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: ColoresApp.textoClaro),
    ),
    cardTheme: CardThemeData(color: ColoresApp.tarjetaClara, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dividerColor: ColoresApp.separadorClaro,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ColoresApp.naranjaClaro, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 50), backgroundColor: ColoresApp.naranjaClaro, foregroundColor: ColoresApp.tarjetaClara)),
  );
}
