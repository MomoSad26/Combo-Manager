class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.precioVentaManual,
    required this.activo,
  });

  final int id;
  final String nombre;
  final double precioCompra;
  final double precioVenta;
  final bool precioVentaManual;
  final bool activo;

  factory Producto.fromMap(Map<String, Object?> map) => Producto(
        id: (map['id'] as num).toInt(),
        nombre: map['nombre'] as String,
        precioCompra: (map['precio_compra'] as num).toDouble(),
        precioVenta: (map['precio_venta'] as num).toDouble(),
        precioVentaManual: (map['precio_venta_manual'] as num? ?? 0) == 1,
        activo: (map['activo'] as num? ?? 1) == 1,
      );

  Map<String, Object?> toMap({bool incluirId = true}) => {
        if (incluirId) 'id': id,
        'nombre': nombre,
        'precio_compra': precioCompra,
        'precio_venta': precioVenta,
        'precio_venta_manual': precioVentaManual ? 1 : 0,
        'activo': activo ? 1 : 0,
      };

  Producto copiar({
    int? id,
    String? nombre,
    double? precioCompra,
    double? precioVenta,
    bool? precioVentaManual,
    bool? activo,
  }) =>
      Producto(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        precioCompra: precioCompra ?? this.precioCompra,
        precioVenta: precioVenta ?? this.precioVenta,
        precioVentaManual: precioVentaManual ?? this.precioVentaManual,
        activo: activo ?? this.activo,
      );
}
