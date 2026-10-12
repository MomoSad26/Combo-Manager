import 'package:flutter_test/flutter_test.dart';
import 'package:combo_manager/logica/calculos.dart';
import 'package:combo_manager/logica/formato_numeros.dart';

void main() {
  group('Fórmulas de Combo Manager', () {
    test('calcula el precio de venta usando margen y tasa', () {
      expect(
        Calculos.precioVentaProducto(1000, 1.5, 755),
        closeTo(1.9867549668874172, 1e-12),
      );
    });

    test('calcula ganancia de combo en escala grande', () {
      expect(
        Calculos.gananciaCombo(7.350993377483443, 3700, 755),
        closeTo(1850, 1e-8),
      );
    });

    test('formatea truncando a dos decimales y elimina ceros finales', () {
      expect(FormatoNumeros.moneda(1.98675497), '1.98');
      expect(FormatoNumeros.moneda(1.90), '1.9');
      expect(FormatoNumeros.moneda(2.00), '2');
      expect(FormatoNumeros.moneda(0.60), '0.6');
      expect(FormatoNumeros.moneda(755.00), '755');
    });

    test('una tasa no positiva no produce división por cero', () {
      expect(Calculos.precioVentaProducto(1000, 1.5, 0), 0);
    });
  });
}