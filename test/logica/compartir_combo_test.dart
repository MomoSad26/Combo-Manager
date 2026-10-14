import 'package:combo_manager/logica/compartir_combo.dart';
import 'package:combo_manager/modelos/combo.dart';
import 'package:combo_manager/modelos/combo_item.dart';
import 'package:flutter_test/flutter_test.dart';

ComboItem item(String nombre, {int? cantidad, bool activo = true, double precioVenta = 1}) => ComboItem(
      id: nombre.hashCode, comboId: 1, productoId: nombre.hashCode, nombreProducto: nombre,
      precioCompra: 100, precioVenta: precioVenta, activo: activo, cantidad: cantidad,
      precioFila: cantidad == null ? null : precioVenta * cantidad,
    );

Combo combo(List<ComboItem> items, {String nombre = 'Desayuno', double precio = 3.5}) => Combo(
      id: 1, nombre: nombre, precioCombo: precio, costoProductos: 0, ganancia: 0,
      precioManual: false, costoManual: false, gananciaManual: false, items: items,
    );

void main() {
  test('cada línea lleva el precio de venta por la cantidad; los productos sin cantidad no salen', () {
    final c = combo([
      item('Pan', cantidad: 2, precioVenta: 1.5),
      item('Leche', cantidad: 1, precioVenta: 0.25),
      item('Sin cantidad'),
    ]);
    expect(CompartirCombo.crearMensaje(c), 'DESAYUNO\n\n2 Pan - 3\n1 Leche - 0.25\n\nPrecio: 3.5');
  });

  // Ejemplos de la especificación (4.1 a 4.4).
  test('ejemplo con un solo producto', () {
    final c = combo([item('Paquete de pollo 🐔 10 Lb', cantidad: 1, precioVenta: 13)], nombre: 'Combo 1', precio: 13);
    expect(CompartirCombo.crearMensaje(c), 'COMBO 1\n\n1 Paquete de pollo 🐔 10 Lb - 13\n\nPrecio: 13');
  });

  test('ejemplo con dos productos y caracteres especiales', () {
    final c = combo([
      item('Paquete de pollo 🐔 10 Lb', cantidad: 1, precioVenta: 13),
      item('Cerveza Cristal/Bucanero (24u)', cantidad: 1, precioVenta: 30),
    ], nombre: 'Combo', precio: 43);
    expect(CompartirCombo.crearMensaje(c),
        'COMBO\n\n1 Paquete de pollo 🐔 10 Lb - 13\n1 Cerveza Cristal/Bucanero (24u) - 30\n\nPrecio: 43');
  });

  test('ejemplo con cantidades mayores a 1', () {
    final c = combo([
      item('Hamburguesas', cantidad: 2, precioVenta: 1.98),
      item('Refrescos', cantidad: 2, precioVenta: 0.99),
      item('Papas', cantidad: 1, precioVenta: 0.6),
    ], nombre: 'Combo Familiar', precio: 6.54);
    expect(CompartirCombo.crearMensaje(c),
        'COMBO FAMILIAR\n\n2 Hamburguesas - 3.96\n2 Refrescos - 1.98\n1 Papas - 0.6\n\nPrecio: 6.54');
  });

  test('ejemplo con mezcla de cantidades', () {
    final c = combo([
      item('Cerveza', cantidad: 3, precioVenta: 2.5),
      item('Papas', cantidad: 2, precioVenta: 0.6),
      item('Refresco', cantidad: 1, precioVenta: 0.99),
    ], nombre: 'Combo Mixto', precio: 9.69);
    expect(CompartirCombo.crearMensaje(c),
        'COMBO MIXTO\n\n3 Cerveza - 7.5\n2 Papas - 1.2\n1 Refresco - 0.99\n\nPrecio: 9.69');
  });

  test('el precio final es el del detalle aunque se haya editado a mano', () {
    final c = combo([item('Pan', cantidad: 2, precioVenta: 1)], precio: 5);
    expect(CompartirCombo.crearMensaje(c), 'DESAYUNO\n\n2 Pan - 2\n\nPrecio: 5');
  });

  test('detecta productos inactivos para bloquear el envío', () {
    final c = combo([item('Pan', cantidad: 2), item('Leche', cantidad: 1, activo: false)]);
    expect(CompartirCombo.productosInactivos(c).map((i) => i.nombreProducto), ['Leche']);
    expect(CompartirCombo.tieneProductosCompartibles(c), isTrue);
  });

  test('sin productos con cantidad no hay nada que compartir', () {
    expect(CompartirCombo.tieneProductosCompartibles(combo([item('Pan')])), isFalse);
  });
}
