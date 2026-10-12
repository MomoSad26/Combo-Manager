import 'package:sqflite/sqflite.dart';
import '../modelos/configuracion.dart';

class ConfiguracionDao {
  ConfiguracionDao(this.db);
  final Database db;

  Future<Configuracion> obtener({DatabaseExecutor? executor}) async {
    final rows = await (executor ?? db).query('configuracion', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      await (executor ?? db).insert('configuracion', {'id': 1, 'margen': 1.5, 'tasa_referencia': 755, 'modo_oscuro': 0});
      return const Configuracion(margen: 1.5, tasaReferencia: 755, modoOscuro: false);
    }
    return Configuracion.fromMap(rows.first);
  }

  Future<void> actualizar({double? margen, double? tasaReferencia, bool? modoOscuro, DatabaseExecutor? executor}) async {
    final values = <String, Object?>{};
    if (margen != null) values['margen'] = margen;
    if (tasaReferencia != null) values['tasa_referencia'] = tasaReferencia;
    if (modoOscuro != null) values['modo_oscuro'] = modoOscuro ? 1 : 0;
    if (values.isNotEmpty) await (executor ?? db).update('configuracion', values, where: 'id = 1');
  }
}
