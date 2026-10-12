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

  // Los cambios se aplican de uno en uno: si se pulsa "+" varias veces seguidas,
  // cada pulsación parte del valor que dejó la anterior y ninguna se pierde.
  Future<void> _cola = Future.value();

  Future<void> _enCola(Future<void> Function() operacion) {
    final resultado = _cola.then((_) => operacion());
    _cola = resultado.catchError((_) {});
    return resultado;
  }

  Future<void> cambiarMargen(double valor) async {
    if (valor <= 0) throw ArgumentError('El margen debe ser mayor que cero.');
    await _enCola(() async {
      await _repositorio.actualizarMargen(valor);
      await _aplicarCascada();
    });
  }

  Future<void> cambiarTasa(double valor) async {
    if (valor <= 0) throw ArgumentError('La tasa debe ser mayor que cero.');
    await _enCola(() async {
      await _repositorio.actualizarTasa(valor);
      await _aplicarCascada();
    });
  }

  /// Suma [delta] al margen guardado en el momento de aplicarse. Si el resultado
  /// no es positivo, no hace nada.
  Future<void> ajustarMargen(double delta) => _enCola(() async {
        final actual = await _repositorio.obtener();
        final nuevo = double.parse((actual.margen + delta).toStringAsFixed(8));
        if (nuevo <= 0) return;
        await _repositorio.actualizarMargen(nuevo);
        await _aplicarCascada();
      });

  /// Suma [delta] a la tasa guardada en el momento de aplicarse. Si el resultado
  /// no es positivo, no hace nada.
  Future<void> ajustarTasa(double delta) => _enCola(() async {
        final actual = await _repositorio.obtener();
        final nuevo = double.parse((actual.tasaReferencia + delta).toStringAsFixed(8));
        if (nuevo <= 0) return;
        await _repositorio.actualizarTasa(nuevo);
        await _aplicarCascada();
      });

  Future<void> _aplicarCascada() async {
    _configuracion = await _repositorio.obtener();
    await _productoRepositorio.recalcularTodosLosPrecios(_configuracion);
    await _comboRepositorio.recalcularTodosLosCombos(_configuracion, recalcularFilas: true);
    await _alCambiarProductos();
    await _alCambiarCombos();
    notifyListeners();
  }

  Future<void> cambiarModoOscuro(bool valor) => _enCola(() async {
        await _repositorio.actualizarModoOscuro(valor);
        _configuracion = await _repositorio.obtener();
        notifyListeners();
      });
}
