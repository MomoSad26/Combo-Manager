import 'package:flutter_test/flutter_test.dart';
import '../soporte/bd_prueba.dart';

void main() {
  late AppPrueba app;
  setUp(() async => app = await AppPrueba.crear());
  tearDown(() => app.bd.cerrar());

  Future<int> crearComboConPan() async {
    final config = app.configuracion.configuracion;
    final pan = (await app.productos.crear(
      nombre: 'Pan', precioCompra: 1000,
      precioVenta: app.productos.precioVentaCalculado(1000, config), precioVentaManual: false,
    ))!;
    final combo = (await app.combos.crear('Desayuno'))!;
    expect(await app.combos.anadirProducto(combo, pan, 2), isTrue);
    return combo;
  }

  test('cambiar el margen recalcula productos y combos', () async {
    final comboId = await crearComboConPan();
    await app.configuracion.cambiarMargen(2);

    final pan = app.productos.productos.single;
    expect(pan.precioVenta, closeTo(1000 * 2 / 755, 1e-12));
    final combo = app.combos.porId(comboId)!;
    expect(combo.precioCombo, closeTo(2 * 1000 * 2 / 755, 1e-12));
    expect(combo.costoProductos, 2000);
    expect(combo.ganancia, closeTo(combo.precioCombo * 755 - 2000, 1e-8));
  });

  test('pulsaciones rápidas de "+" en el margen no se pierden', () async {
    await crearComboConPan();
    await Future.wait([for (var i = 0; i < 5; i++) app.configuracion.ajustarMargen(0.1)]);
    expect(app.configuracion.configuracion.margen, closeTo(2.0, 1e-9));
    expect(app.productos.productos.single.precioVenta, closeTo(1000 * 2.0 / 755, 1e-9));
  });

  test('pulsaciones rápidas de "+" en la tasa no se pierden', () async {
    await Future.wait([for (var i = 0; i < 4; i++) app.configuracion.ajustarTasa(5)]);
    expect(app.configuracion.configuracion.tasaReferencia, 775);
  });

  test('restar no deja el margen en cero ni negativo', () async {
    await app.configuracion.cambiarMargen(0.1);
    await app.configuracion.ajustarMargen(-0.1);
    expect(app.configuracion.configuracion.margen, closeTo(0.1, 1e-12));
  });

  test('un error en un cambio no bloquea los siguientes', () async {
    await expectLater(app.configuracion.cambiarTasa(0), throwsArgumentError);
    await app.configuracion.ajustarTasa(5);
    expect(app.configuracion.configuracion.tasaReferencia, 760);
  });
}
