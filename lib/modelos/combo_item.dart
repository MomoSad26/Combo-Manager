class ComboItem {
  const ComboItem({
    required this.id,
    required this.comboId,
    required this.productoId,
    required this.nombreProducto,
    required this.precioCompra,
    required this.precioVenta,
    required this.activo,
    required this.cantidad,
    required this.precioFila,
  });

  final int id;
  final int comboId;
  final int productoId;
  final String nombreProducto;
  final double precioCompra;
  final double precioVenta;
  final bool activo;
  final int? cantidad;
  final double? precioFila;

  factory ComboItem.fromMap(Map<String, Object?> map) => ComboItem(
        id: (map['item_id'] as num).toInt(),
        comboId: (map['combo_id'] as num).toInt(),
        productoId: (map['producto_id'] as num).toInt(),
        nombreProducto: map['nombre'] as String,
        precioCompra: (map['precio_compra'] as num).toDouble(),
        precioVenta: (map['precio_venta'] as num).toDouble(),
        activo: (map['activo'] as num) == 1,
        cantidad: (map['cantidad'] as num?)?.toInt(),
        precioFila: (map['precio_fila'] as num?)?.toDouble(),
      );
}
