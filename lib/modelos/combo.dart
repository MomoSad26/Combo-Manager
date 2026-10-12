import 'combo_item.dart';

class Combo {
  const Combo({
    required this.id,
    required this.nombre,
    required this.precioCombo,
    required this.costoProductos,
    required this.ganancia,
    required this.precioManual,
    required this.costoManual,
    required this.gananciaManual,
    required this.items,
  });

  final int id;
  final String nombre;
  final double precioCombo;
  final double costoProductos;
  final double ganancia;
  final bool precioManual;
  final bool costoManual;
  final bool gananciaManual;
  final List<ComboItem> items;

  factory Combo.fromMap(Map<String, Object?> map, {List<ComboItem> items = const []}) => Combo(
        id: (map['id'] as num).toInt(),
        nombre: map['nombre'] as String,
        precioCombo: (map['precio_combo'] as num? ?? 0).toDouble(),
        costoProductos: (map['costo_productos'] as num? ?? 0).toDouble(),
        ganancia: (map['ganancia'] as num? ?? 0).toDouble(),
        precioManual: (map['precio_manual'] as num? ?? 0) == 1,
        costoManual: (map['costo_manual'] as num? ?? 0) == 1,
        gananciaManual: (map['ganancia_manual'] as num? ?? 0) == 1,
        items: items,
      );
}
