import 'package:sqflite/sqflite.dart';
import '../logica/nombres.dart';

class ComboDao {
  ComboDao(this.db);
  final Database db;

  Future<List<Map<String, Object?>>> obtenerCombos() =>
      db.query('combos', orderBy: 'nombre COLLATE NOCASE, nombre COLLATE BINARY, id');

  Future<Map<String, Object?>?> obtenerComboPorId(int id, {DatabaseExecutor? executor}) async {
    final rows = await (executor ?? db).query('combos', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> obtenerItems(int comboId, {DatabaseExecutor? executor}) =>
      (executor ?? db).rawQuery('''SELECT ci.id AS item_id, ci.combo_id, ci.producto_id,
        ci.cantidad, ci.precio_fila, p.nombre, p.precio_compra, p.precio_venta, p.activo
        FROM combo_items ci INNER JOIN productos p ON p.id = ci.producto_id
        WHERE ci.combo_id = ? ORDER BY ci.id''', [comboId]);

  Future<List<int>> combosQueContienenProducto(int productoId, {DatabaseExecutor? executor}) async {
    final rows = await (executor ?? db).query('combo_items', columns: ['combo_id'], where: 'producto_id = ?', whereArgs: [productoId]);
    return rows.map((r) => (r['combo_id'] as num).toInt()).toSet().toList();
  }

  Future<bool> existeNombre(String nombre, {int? excluirId, DatabaseExecutor? executor}) async {
    final buscado = normalizarNombre(nombre);
    final rows = await (executor ?? db).query('combos', columns: ['id', 'nombre']);
    return rows.any((r) => (r['id'] as num).toInt() != excluirId && normalizarNombre(r['nombre'] as String) == buscado);
  }
}
