import 'package:flutter_test/flutter_test.dart';
import '../soporte/bd_prueba.dart';

void main() {
  late AppPrueba app;
  setUp(() async => app = await AppPrueba.crear());
  tearDown(() => app.bd.cerrar());

  Future<int?> crearProducto(String nombre) =>
      app.productos.crear(nombre: nombre, precioCompra: 100, precioVenta: 1, precioVentaManual: false);

  test('no se crean dos combos que solo difieren en mayúsculas o espacios', () async {
    expect(await app.combos.crear('Combo Familiar'), isNotNull);
    expect(await app.combos.crear('combo familiar'), isNull);
    expect(await app.combos.crear('  COMBO FAMILIAR '), isNull);
    expect(await app.combos.crear('Combo Ñoño'), isNotNull);
    expect(await app.combos.crear('combo ñoño'), isNull);
  });

  test('renombrar un combo a su mismo nombre con otras mayúsculas está permitido', () async {
    final id = (await app.combos.crear('Combo'))!;
    expect(await app.combos.renombrar(id, 'COMBO'), isTrue);
    final otro = (await app.combos.crear('Otro'))!;
    expect(await app.combos.renombrar(otro, 'combo'), isFalse);
  });

  test('no se crean dos productos con el mismo nombre', () async {
    expect(await crearProducto('Pan'), isNotNull);
    expect(await crearProducto('pan'), isNull);
    expect(app.productos.productos, hasLength(1));
  });

  test('normaliza acentos, ñ y espacios internos al detectar duplicados', () async {
    expect(await crearProducto('Azúcar'), isNotNull);
    expect(await crearProducto('a z u c a r'), isNull);
    expect(await crearProducto('Piña'), isNotNull);
    expect(await crearProducto('pina'), isNull);
    expect(await crearProducto('Hamburguesa Grande'), isNotNull);
    expect(await crearProducto('Hamburguesa'), isNotNull);
    expect(await crearProducto('Hamburguesa2'), isNotNull);
  });

  test('editar un producto con el nombre de otro se rechaza sin guardar', () async {
    await crearProducto('Pan');
    await crearProducto('Leche');
    final leche = app.productos.productos.firstWhere((p) => p.nombre == 'Leche');
    final guardado = await app.productos.guardarEdicion(
      original: leche, nombre: 'PAN', precioCompra: 100, precioVenta: 1, precioVentaManual: false);
    expect(guardado, isFalse);
    expect(app.productos.productos.map((p) => p.nombre), containsAll(['Pan', 'Leche']));
  });

  test('un duplicado anterior a la validación se puede seguir editando', () async {
    final db = await app.bd.database;
    await db.insert('productos', {'nombre': 'Pan', 'precio_compra': 100, 'precio_venta': 1});
    await db.insert('productos', {'nombre': 'pan', 'precio_compra': 100, 'precio_venta': 1});
    await app.productos.recargar();
    final pan = app.productos.productos.firstWhere((p) => p.nombre == 'pan');
    final guardado = await app.productos.guardarEdicion(
      original: pan, nombre: 'pan', precioCompra: 300, precioVenta: 1, precioVentaManual: true);
    expect(guardado, isTrue);
    await app.productos.recargar();
    expect(app.productos.productos.firstWhere((p) => p.nombre == 'pan').precioCompra, 300);
  });

  test('editar un producto conservando su nombre funciona', () async {
    await crearProducto('Pan');
    final pan = app.productos.productos.single;
    final guardado = await app.productos.guardarEdicion(
      original: pan, nombre: 'Pan', precioCompra: 200, precioVenta: 1, precioVentaManual: true);
    expect(guardado, isTrue);
    expect(app.productos.productos.single.precioCompra, 200);
  });
}
