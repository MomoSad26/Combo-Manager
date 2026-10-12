/// Fórmulas de negocio centralizadas. Los valores nunca se redondean aquí.
class Calculos {
  static double precioVentaProducto(double precioCompra, double margen, double tasa) {
    if (tasa <= 0) return 0;
    return precioCompra * margen / tasa;
  }

  static double precioFila(double precioVentaProducto, int? cantidad) {
    if (cantidad == null || cantidad < 1) return 0;
    return precioVentaProducto * cantidad;
  }

  static double costoFila(double precioCompraProducto, int? cantidad) {
    if (cantidad == null || cantidad < 1) return 0;
    return precioCompraProducto * cantidad;
  }

  static double gananciaCombo(double precioCombo, double costoProductos, double tasa) =>
      precioCombo * tasa - costoProductos;
}
