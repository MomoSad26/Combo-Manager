import 'dart:convert';
import 'dart:typed_data';
import 'package:combo_manager/logica/respaldo.dart';
import 'package:flutter_test/flutter_test.dart';
import '../soporte/bd_prueba.dart';

void main() {
  late AppPrueba origen;
  late AppPrueba destino;
  setUp(() async {
    origen = await AppPrueba.crear();
    destino = await AppPrueba.crear();
  });
  tearDown(() async {
    await origen.bd.cerrar();
    await destino.bd.cerrar();
  });

  RespaldoService servicio(AppPrueba app) => RespaldoService(app.bd, app.configuracionRepositorio);

  Future<void> poblarOrigen() async {
    final pan = (await origen.productos.crear(nombre: 'Pan', precioCompra: 1000, precioVenta: 2, precioVentaManual: false))!;
    final leche = (await origen.productos.crear(nombre: 'Leche', precioCompra: 500, precioVenta: 1, precioVentaManual: true))!;
    final combo = (await origen.combos.crear('Desayuno'))!;
    await origen.combos.anadirProducto(combo, pan, 2);
    await origen.combos.anadirProducto(combo, leche, 1);
  }

  Uint8List json(Object contenido) => Uint8List.fromList(utf8.encode(jsonEncode(contenido)));

  test('exportar e importar en una base vacía reproduce productos y combos', () async {
    await poblarOrigen();
    final resultado = await servicio(destino).importar(await servicio(origen).crearRespaldo());
    expect(resultado.productosAgregados, 2);
    expect(resultado.combosAgregados, 1);

    await destino.productos.recargar();
    await destino.combos.recargar();
    expect(destino.productos.productos.map((p) => p.nombre), ['Leche', 'Pan']);
    final combo = destino.combos.combos.single;
    expect(combo.nombre, 'Desayuno');
    expect(combo.items.map((i) => (i.nombreProducto, i.cantidad)), [('Pan', 2), ('Leche', 1)]);
    expect(combo.precioCombo, origen.combos.combos.single.precioCombo);
  });

  test('importar fusiona por nombre sin distinguir mayúsculas', () async {
    await poblarOrigen();
    await destino.productos.crear(nombre: 'PAN', precioCompra: 1, precioVenta: 1, precioVentaManual: false);
    await destino.combos.crear('desayuno');

    final resultado = await servicio(destino).importar(await servicio(origen).crearRespaldo());
    expect(resultado.productosExistentes, 1);
    expect(resultado.productosAgregados, 1);
    expect(resultado.combosExistentes, 1);
    expect(resultado.combosAgregados, 0);
    await destino.productos.recargar();
    await destino.combos.recargar();
    expect(destino.productos.productos.map((p) => p.nombre), ['Leche', 'PAN']);
    final panActual = destino.productos.productos.firstWhere((p) => p.nombre == 'PAN');
    expect(panActual.precioCompra, 1);
    expect(panActual.precioVenta, 1);
    expect(destino.combos.combos.single.items, isEmpty);
  });

  test('un respaldo con un error a mitad no modifica nada', () async {
    final respaldo = {
      'version': 1,
      'configuracion': {'margen': 1.5, 'tasa_referencia': 755},
      'productos': [
        {'nombre': 'Pan', 'precio_compra': 1000, 'precio_venta': 2},
      ],
      'combos': [
        {'nombre': 'Bueno', 'items': [{'producto_nombre': 'Pan', 'cantidad': 1}]},
        {'nombre': 'Malo', 'items': [{'producto_nombre': 'Pan', 'cantidad': 0}]},
      ],
    };
    await expectLater(servicio(destino).importar(json(respaldo)), throwsA(isA<RespaldoInvalido>()));
    await destino.productos.recargar();
    await destino.combos.recargar();
    expect(destino.productos.productos, isEmpty);
    expect(destino.combos.combos, isEmpty);
  });

  test('importar cambia margen y tasa sin alterar registros existentes ni sus precios', () async {
    await origen.configuracion.cambiarMargen(2);
    await origen.configuracion.cambiarTasa(800);
    await poblarOrigen();
    await destino.productos.crear(nombre: 'Queso', precioCompra: 1600, precioVenta: 1, precioVentaManual: true);

    final respaldo = await servicio(origen).crearRespaldo();
    final resultado = await servicio(destino).importar(respaldo);
    expect(resultado.configuracionCambiada, isTrue);
    await destino.configuracion.recargar();
    await destino.productos.recargar();
    await destino.combos.recargar();

    expect(destino.configuracion.configuracion.margen, 2);
    expect(destino.configuracion.configuracion.tasaReferencia, 800);
    final queso = destino.productos.productos.firstWhere((p) => p.nombre == 'Queso');
    expect(queso.precioCompra, 1600);
    expect(queso.precioVenta, 1);
    expect(queso.precioVentaManual, isTrue);

    // El combo nuevo se importa tal cual aparece en el respaldo.
    final comboImportado = destino.combos.combos.single;
    final comboOrigen = origen.combos.combos.single;
    expect(comboImportado.precioCombo, comboOrigen.precioCombo);
    expect(comboImportado.costoProductos, comboOrigen.costoProductos);
    expect(comboImportado.ganancia, comboOrigen.ganancia);
  });

  test('el orden personalizado de los productos se conserva al exportar e importar', () async {
    await poblarOrigen();
    final combo = origen.combos.combos.single;
    final ordenInvertido = combo.items.reversed.map((item) => item.id).toList();
    await origen.combos.reordenarItems(combo.id, ordenInvertido);

    final resultado = await servicio(destino).importar(await servicio(origen).crearRespaldo());
    expect(resultado.combosAgregados, 1);
    await destino.combos.recargar();
    expect(
      destino.combos.combos.single.items.map((item) => item.nombreProducto),
      ['Leche', 'Pan'],
    );
  });

  test('si el respaldo trae el mismo margen y tasa no se marca cambio', () async {
    await poblarOrigen();
    final resultado = await servicio(destino).importar(await servicio(origen).crearRespaldo());
    expect(resultado.configuracionCambiada, isFalse);
  });

  test('rechaza un respaldo con margen o tasa no positivos sin modificar nada', () async {
    final respaldo = {
      'version': 1,
      'configuracion': {'margen': 0, 'tasa_referencia': 755},
      'productos': [{'nombre': 'Pan', 'precio_compra': 1000, 'precio_venta': 2}],
      'combos': [],
    };
    await expectLater(servicio(destino).importar(json(respaldo)), throwsA(isA<RespaldoInvalido>()));
    await destino.productos.recargar();
    expect(destino.productos.productos, isEmpty);
    expect((await destino.configuracionRepositorio.obtener()).margen, 1.5);
  });

  test('rechaza archivos que no son respaldos y versiones más nuevas', () async {
    await expectLater(servicio(destino).importar(Uint8List.fromList(utf8.encode('no es json'))), throwsA(isA<RespaldoInvalido>()));
    await expectLater(
      servicio(destino).importar(json({'version': 99, 'configuracion': {}, 'productos': [], 'combos': []})),
      throwsA(isA<RespaldoVersionNueva>()),
    );
  });
}
