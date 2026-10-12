import 'package:sqflite/sqflite.dart';
import '../modelos/producto.dart';

class ProductoDao {
  ProductoDao(this.db);

  final Database db;

  Future<List<Producto>> obtenerTodos() async {
    final rows = await db.query(
      'productos',
      orderBy: 'nombre COLLATE NOCASE, nombre COLLATE BINARY, id',
    );

    return rows.map(Producto.fromMap).toList();
  }

  Future<Producto?> obtenerPorId(int id) async {
    final rows = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isEmpty ? null : Producto.fromMap(rows.first);
  }

  Future<List<Map<String, Object?>>> obtenerFilas() {
    return db.query(
      'productos',
      orderBy: 'nombre COLLATE NOCASE, nombre COLLATE BINARY, id',
    );
  }

  Future<int> insertar(
    Producto producto, {
    DatabaseExecutor? executor,
  }) {
    return (executor ?? db).insert(
      'productos',
      producto.toMap(incluirId: false),
    );
  }

  Future<int> actualizar(
    Producto producto, {
    DatabaseExecutor? executor,
  }) {
    return (executor ?? db).update(
      'productos',
      producto.toMap(incluirId: false),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> eliminar(
    int id, {
    DatabaseExecutor? executor,
  }) {
    return (executor ?? db).delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int?> buscarIdPorNombreExacto(
    String nombre, {
    DatabaseExecutor? executor,
  }) async {
    final rows = await (executor ?? db).query(
      'productos',
      columns: ['id'],
      where: 'nombre = ?',
      whereArgs: [nombre],
      orderBy: 'id',
      limit: 1,
    );

    return rows.isEmpty ? null : (rows.first['id'] as num).toInt();
  }

  Future<void> recalcularVentas(
    double margen,
    double tasa, {
    DatabaseExecutor? executor,
  }) async {
    final e = executor ?? db;

    final rows = await e.query(
      'productos',
      columns: ['id', 'precio_compra'],
    );

    final batch = e is Database ? e.batch() : null;

    for (final row in rows) {
      final compra = (row['precio_compra'] as num).toDouble();
      final venta = tasa <= 0 ? 0.0 : compra * margen / tasa;

      if (batch != null) {
        batch.update(
          'productos',
          {
            'precio_venta': venta,
            'precio_venta_manual': 0,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      } else {
        await e.update(
          'productos',
          {
            'precio_venta': venta,
            'precio_venta_manual': 0,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }

    if (batch != null) {
      await batch.commit(noResult: true);
    }
  }
}
