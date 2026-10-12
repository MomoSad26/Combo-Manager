import 'package:flutter/foundation.dart';
import '../logica/nombres.dart';
import '../modelos/configuracion.dart';
import '../modelos/producto.dart';
import '../repositorios/combo_repositorio.dart';
import '../repositorios/configuracion_repositorio.dart';
import '../repositorios/producto_repositorio.dart';

class ProductoProvider extends ChangeNotifier {
  ProductoProvider(
    this._repositorio,
    this._comboRepositorio,
    this._configuracionRepositorio, {
    required Future<void> Function() alCambiarCombos,
  }) : _alCambiarCombos = alCambiarCombos;

  final ProductoRepositorio _repositorio;
  final ComboRepositorio _comboRepositorio;
  final ConfiguracionRepositorio _configuracionRepositorio;
  final Future<void> Function() _alCambiarCombos;
  List<Producto> _productos = [];
  bool _cargando = false;
  List<Producto> get productos => List.unmodifiable(_productos);
  bool get cargando => _cargando;

  Future<void> recargar() async {
    _cargando = true;
    try {
      _productos = await _repositorio.obtenerTodos();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Producto? porId(int id) {
    for (final producto in _productos) {
      if (producto.id == id) return producto;
    }
    return null;
  }

  double precioVentaCalculado(double compra, Configuracion configuracion) =>
      _repositorio.calcularPrecioVenta(compra, configuracion);

  Future<int?> crear({required String nombre, required double precioCompra, required double precioVenta, required bool precioVentaManual}) async {
    if (await _repositorio.existeNombre(nombre)) return null;
    final id = await _repositorio.crear(
      nombre: nombre,
      precioCompra: precioCompra,
      precioVenta: precioVenta,
      precioVentaManual: precioVentaManual,
    );
    await recargar();
    return id;
  }

  Future<bool> guardarEdicion({
    required Producto original,
    required String nombre,
    required double precioCompra,
    required double precioVenta,
    required bool precioVentaManual,
  }) async {
    // Solo se comprueba si el nombre cambió: así los duplicados creados antes de
    // esta validación se pueden seguir editando sin obligar a renombrarlos.
    final nombreCambio = normalizarNombre(nombre) != normalizarNombre(original.nombre);
    if (nombreCambio && await _repositorio.existeNombre(nombre, excluirId: original.id)) return false;
    final config = await _configuracionRepositorio.obtener();
    final compraCambio = (original.precioCompra - precioCompra).abs() > 1e-10;
    // La pantalla ya recalcula el precio en cuanto cambia la compra. Respetamos
    // si, después de ese recálculo, el usuario volvió a editar manualmente la venta.
    final venta = precioVentaManual
        ? precioVenta
        : _repositorio.calcularPrecioVenta(precioCompra, config);
    final productoNuevo = Producto(
      id: original.id,
      nombre: nombre.trim(),
      precioCompra: precioCompra,
      precioVenta: venta,
      precioVentaManual: precioVentaManual,
      activo: original.activo,
    );
    await _repositorio.actualizar(productoNuevo);
    final preciosCambiaron = compraCambio || (original.precioVenta - venta).abs() > 1e-10;
    if (preciosCambiaron) {
      await _comboRepositorio.recalcularCombosQueContienenProducto(original.id, config, recalcularFilas: true);
      await _alCambiarCombos();
    } else if (original.nombre != nombre.trim()) {
      await _alCambiarCombos();
    }
    await recargar();
    return true;
  }

  Future<void> cambiarEstado(Producto producto) async {
    await _repositorio.actualizarEstado(producto.id, !producto.activo);
    await recargar();
    await _alCambiarCombos();
  }

  Future<void> eliminar(Producto producto) async {
    final config = await _configuracionRepositorio.obtener();
    await _comboRepositorio.eliminarProductoDelCatalogo(producto.id, config);
    await recargar();
    await _alCambiarCombos();
  }
}
