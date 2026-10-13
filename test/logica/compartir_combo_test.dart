import 'package:combo_manager/logica/compartir_combo.dart';
import 'package:combo_manager/modelos/combo.dart';
import 'package:combo_manager/modelos/combo_item.dart';
import 'package:flutter_test/flutter_test.dart';

ComboItem item(String nombre, {int? cantidad, bool activo = true}) => ComboItem(
      id: nombre.hashCode, comboId: 1, productoId: nombre.hashCode, nombreProducto: nombre,
      precioCompra: 100, precioVenta: 1, activo: activo, cantidad: cantidad, precioFila: cantidad?.toDouble(),
    );

Combo combo(List<ComboItem> items) => Combo(
      id: 1, nombre: 'Desayuno', precioCombo: 3.5, costoProductos: 0, ganancia: 0,
      precioManual: false, costoManual: false, gananciaManual: false, items: items,
    );

void main() {
  test('el mensaje lista los productos con cantidad y el precio', () {
    final c = combo([item('Pan', cantidad: 2), item('Leche', cantidad: 1), item('Sin cantidad')]);
    expect(CompartirCombo.crearMensaje(c), 'DESAYUNO\n\n2 Pan\n1 Leche\n\nPrecio: 3.5');
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
