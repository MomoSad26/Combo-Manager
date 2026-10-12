import 'dart:io';
import 'package:combo_manager/base_datos/base_datos.dart';
import 'package:combo_manager/providers/combo_provider.dart';
import 'package:combo_manager/providers/configuracion_provider.dart';
import 'package:combo_manager/providers/producto_provider.dart';
import 'package:combo_manager/repositorios/combo_repositorio.dart';
import 'package:combo_manager/repositorios/configuracion_repositorio.dart';
import 'package:combo_manager/repositorios/producto_repositorio.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Crea una base SQLite real en un archivo temporal, aislada para cada prueba.
Future<BaseDatos> crearBaseDatosPrueba({int version = BaseDatos.versionActual, Map<int, Migracion>? migraciones, String? ruta}) async {
  sqfliteFfiInit();
  final destino = ruta ?? p.join((await Directory.systemTemp.createTemp('combo_manager_')).path, 'prueba.db');
  final bd = BaseDatos(fabrica: databaseFactoryFfiNoIsolate, ruta: destino, version: version, migraciones: migraciones);
  await bd.inicializar();
  return bd;
}

/// Monta los providers igual que `main.dart`, pero sobre la base de prueba.
class AppPrueba {
  AppPrueba(this.bd)
      : productoRepositorio = ProductoRepositorio(bd),
        comboRepositorio = ComboRepositorio(bd),
        configuracionRepositorio = ConfiguracionRepositorio(bd) {
    combos = ComboProvider(comboRepositorio, configuracionRepositorio);
    productos = ProductoProvider(productoRepositorio, comboRepositorio, configuracionRepositorio, alCambiarCombos: combos.recargar);
    configuracion = ConfiguracionProvider(configuracionRepositorio, productoRepositorio, comboRepositorio,
        alCambiarProductos: productos.recargar, alCambiarCombos: combos.recargar);
  }

  final BaseDatos bd;
  final ProductoRepositorio productoRepositorio;
  final ComboRepositorio comboRepositorio;
  final ConfiguracionRepositorio configuracionRepositorio;
  late final ComboProvider combos;
  late final ProductoProvider productos;
  late final ConfiguracionProvider configuracion;

  static Future<AppPrueba> crear() async {
    final app = AppPrueba(await crearBaseDatosPrueba());
    await app.configuracion.recargar();
    return app;
  }
}
