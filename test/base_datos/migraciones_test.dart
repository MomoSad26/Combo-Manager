import 'package:combo_manager/base_datos/base_datos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../soporte/bd_prueba.dart';

void main() {
  test('una base nueva crea el esquema y la configuración inicial', () async {
    final bd = await crearBaseDatosPrueba();
    final db = await bd.database;
    expect(await db.getVersion(), BaseDatos.versionActual);
    final config = await db.query('configuracion');
    expect(config.single['margen'], 1.5);
    expect(config.single['tasa_referencia'], 755);
    expect(config.single['detalle_combo_compacto'], 1);
    final columnasItems = await db.rawQuery('PRAGMA table_info(combo_items)');
    expect(columnasItems.map((c) => c['name']), contains('orden'));
    await bd.cerrar();
  });

  test('al subir de versión se aplican las migraciones sin perder datos', () async {
    final v1 = await crearBaseDatosPrueba(version: 1, migraciones: {});
    final ruta = (await v1.database).path;
    await (await v1.database).insert('productos', {'nombre': 'Pan', 'precio_compra': 100, 'precio_venta': 0.2});
    await v1.cerrar();

    final v2 = await crearBaseDatosPrueba(ruta: ruta, version: 2, migraciones: {
      2: (db) => db.execute('ALTER TABLE productos ADD COLUMN notas TEXT'),
    });
    final db = await v2.database;
    expect(await db.getVersion(), 2);
    final fila = (await db.query('productos')).single;
    expect(fila['nombre'], 'Pan');
    expect(fila.containsKey('notas'), isTrue);
    await v2.cerrar();
  });

  test('una base nueva en versión 2 también ejecuta las migraciones', () async {
    final bd = await crearBaseDatosPrueba(version: 2, migraciones: {
      2: (db) => db.execute('ALTER TABLE productos ADD COLUMN notas TEXT'),
    });
    final columnas = await (await bd.database).rawQuery('PRAGMA table_info(productos)');
    expect(columnas.map((c) => c['name']), contains('notas'));
    await bd.cerrar();
  });

  test('la migración real conserva el orden de inserción y activa el modo compacto', () async {
    final v1 = await crearBaseDatosPrueba(version: 1, migraciones: {});
    final ruta = (await v1.database).path;
    final db1 = await v1.database;
    final producto1 = await db1.insert('productos', {'nombre': 'Primero', 'precio_compra': 1, 'precio_venta': 2});
    final producto2 = await db1.insert('productos', {'nombre': 'Segundo', 'precio_compra': 1, 'precio_venta': 2});
    final combo = await db1.insert('combos', {'nombre': 'Combo'});
    await db1.insert('combo_items', {'combo_id': combo, 'producto_id': producto1, 'cantidad': 1, 'precio_fila': 2});
    await db1.insert('combo_items', {'combo_id': combo, 'producto_id': producto2, 'cantidad': 1, 'precio_fila': 2});
    await v1.cerrar();

    final actualizada = await crearBaseDatosPrueba(ruta: ruta);
    final db2 = await actualizada.database;
    final filas = await db2.query('combo_items', orderBy: 'orden, id');
    expect(filas.map((f) => f['orden']), [0, 1]);
    final config = (await db2.query('configuracion')).single;
    expect(config['detalle_combo_compacto'], 1);
    await actualizada.cerrar();
  });

  test('si falta una migración, la apertura falla en vez de dejar el esquema a medias', () async {
    final v1 = await crearBaseDatosPrueba(version: 1, migraciones: {});
    final ruta = (await v1.database).path;
    await v1.cerrar();
    await expectLater(crearBaseDatosPrueba(ruta: ruta, version: 2, migraciones: {}), throwsA(isA<StateError>()));
    final db = await databaseFactoryFfiNoIsolate.openDatabase(ruta);
    expect(await db.getVersion(), 1);
    await db.close();
  });
}
