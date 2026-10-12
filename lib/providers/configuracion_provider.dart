import 'package:flutter/foundation.dart';
import '../modelos/configuracion.dart';
import '../repositorios/combo_repositorio.dart';
import '../repositorios/configuracion_repositorio.dart';
import '../repositorios/producto_repositorio.dart';

class ConfiguracionProvider extends ChangeNotifier {
  ConfiguracionProvider(
    this._repositorio,
    this._productoRepositorio,
    this._comboRepositorio, {
    required Future<void> Function() alCambiarProductos,
    required Future<void> Function() alCambiarCombos,
  })  : _alCambiarProductos = alCambiarProductos,
        _alCambiarCombos = alCambiarCombos;

  final ConfiguracionRepositorio _repositorio;
  final ProductoRepositorio _productoRepositorio;
  final ComboRepositorio _comboRepositorio;
  final Future<void> Function() _alCambiarProductos;
  final Future<void> Function() _alCambiarCombos;
  Configuracion _configuracion = const Configuracion(margen: 1.5, tasaReferencia: 755, modoOscuro: false);
  Configuracion get configuracion => _configuracion;
  bool get modoOscuro => _configuracion.modoOscuro;

  Future<void> recargar() async {
    _configuracion = await _repositorio.obtener();
    notifyListeners();
  }

  Future<void> cambiarMargen(double valor) async {
    if (valor <= 0) throw ArgumentError('El margen debe ser mayor que cero.');
    await _repositorio.actualizarMargen(valor);
    await _aplicarCascada();
  }

  Future<void> cambiarTasa(double valor) async {
    if (valor <= 0) throw ArgumentError('La tasa debe ser mayor que cero.');
    await _repositorio.actualizarTasa(valor);
    await _aplicarCascada();
  }

  Future<void> _aplicarCascada() async {
    _configuracion = await _repositorio.obtener();
    await _productoRepositorio.recalcularTodosLosPrecios(_configuracion);
    await _comboRepositorio.recalcularTodosLosCombos(_configuracion, recalcularFilas: true);
    await _alCambiarProductos();
    await _alCambiarCombos();
    notifyListeners();
  }

  Future<void> cambiarModoOscuro(bool valor) async {
    await _repositorio.actualizarModoOscuro(valor);
    _configuracion = await _repositorio.obtener();
    notifyListeners();
  }
}
