import '../base_datos/base_datos.dart';
import '../base_datos/configuracion_dao.dart';
import '../modelos/configuracion.dart';

class ConfiguracionRepositorio {
  ConfiguracionRepositorio(this.baseDatos);
  final BaseDatos baseDatos;

  Future<ConfiguracionDao> _dao() async => ConfiguracionDao(await baseDatos.database);
  Future<Configuracion> obtener() async => (await _dao()).obtener();

  Future<void> actualizarMargen(double margen) async {
    if (margen <= 0) throw ArgumentError('El margen debe ser mayor que cero.');
    await (await _dao()).actualizar(margen: margen);
  }

  Future<void> actualizarTasa(double tasa) async {
    if (tasa <= 0) throw ArgumentError('La tasa debe ser mayor que cero.');
    await (await _dao()).actualizar(tasaReferencia: tasa);
  }

  Future<void> actualizarModoOscuro(bool valor) async => (await _dao()).actualizar(modoOscuro: valor);

  Future<void> actualizarDetalleComboCompacto(bool valor) async =>
      (await _dao()).actualizar(detalleComboCompacto: valor);
}
