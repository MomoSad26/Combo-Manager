import 'package:flutter/foundation.dart';
import '../modelos/combo.dart';
import '../repositorios/combo_repositorio.dart';
import '../repositorios/configuracion_repositorio.dart';

class ComboProvider extends ChangeNotifier {
  ComboProvider(this._repositorio, this._configuracionRepositorio);

  final ComboRepositorio _repositorio;
  final ConfiguracionRepositorio _configuracionRepositorio;
  List<Combo> _combos = [];
  bool _cargando = false;
  List<Combo> get combos => List.unmodifiable(_combos);
  bool get cargando => _cargando;

  Future<void> recargar() async {
    _cargando = true;
    try {
      _combos = await _repositorio.obtenerTodos();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Combo? porId(int id) {
    for (final combo in _combos) {
      if (combo.id == id) return combo;
    }
    return null;
  }

  Future<bool> existeNombre(String nombre, {int? excluirId}) =>
      _repositorio.existeNombre(nombre, excluirId: excluirId);

  Future<int?> crear(String nombre) async {
    if (await _repositorio.existeNombre(nombre)) return null;
    final id = await _repositorio.crear(nombre);
    await recargar();
    return id;
  }

  Future<bool> renombrar(int id, String nombre) async {
    if (await _repositorio.existeNombre(nombre, excluirId: id)) return false;
    await _repositorio.renombrar(id, nombre);
    await recargar();
    return true;
  }

  Future<void> eliminar(int id) async {
    await _repositorio.eliminar(id);
    await recargar();
  }

  Future<bool> añadirProducto(int comboId, int productoId, int cantidad) async {
    final configuracion = await _configuracionRepositorio.obtener();
    final agregado = await _repositorio.añadirProducto(comboId, productoId, cantidad, configuracion);
    if (agregado) await recargar();
    return agregado;
  }

  Future<void> actualizarCantidad(int itemId, int cantidad) async {
    await _repositorio.actualizarCantidad(itemId, cantidad, await _configuracionRepositorio.obtener());
    await recargar();
  }

  Future<void> actualizarPrecioFila(int itemId, double precio) async {
    await _repositorio.actualizarPrecioFila(itemId, precio, await _configuracionRepositorio.obtener());
    await recargar();
  }

  Future<void> limpiarFila(int itemId) async {
    await _repositorio.limpiarFila(itemId, await _configuracionRepositorio.obtener());
    await recargar();
  }

  Future<void> eliminarItem(int itemId) async {
    await _repositorio.eliminarItem(itemId, await _configuracionRepositorio.obtener());
    await recargar();
  }

  Future<void> editarPrecio(int comboId, double precio) async {
    await _repositorio.editarPrecioCombo(comboId, precio, await _configuracionRepositorio.obtener());
    await recargar();
  }

  Future<void> editarCosto(int comboId, double costo) async {
    await _repositorio.editarCostoCombo(comboId, costo, await _configuracionRepositorio.obtener());
    await recargar();
  }

  Future<void> editarGanancia(int comboId, double ganancia) async {
    await _repositorio.editarGananciaCombo(comboId, ganancia);
    await recargar();
  }

  Future<bool> yaContieneProducto(int comboId, int productoId) async {
    final combo = await _repositorio.obtenerPorId(comboId);
    return combo?.items.any((item) => item.productoId == productoId) ?? false;
  }
}
