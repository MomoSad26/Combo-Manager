import 'package:sqflite/sqflite.dart';
import '../base_datos/base_datos.dart';
import '../base_datos/combo_dao.dart';
import '../logica/calculos.dart';
import '../modelos/combo.dart';
import '../modelos/combo_item.dart';
import '../modelos/configuracion.dart';

class ComboRepositorio {
  ComboRepositorio(this.baseDatos);
  final BaseDatos baseDatos;

  Future<List<Combo>> obtenerTodos() async {
    final db = await baseDatos.database;
    final dao = ComboDao(db);
    final filas = await dao.obtenerCombos();
    final salida = <Combo>[];
    for (final fila in filas) {
      final id = (fila['id'] as num).toInt();
      final items = (await dao.obtenerItems(id)).map(ComboItem.fromMap).toList();
      salida.add(Combo.fromMap(fila, items: items));
    }
    return salida;
  }

  Future<Combo?> obtenerPorId(int id) async {
    final db = await baseDatos.database;
    final dao = ComboDao(db);
    final fila = await dao.obtenerComboPorId(id);
    if (fila == null) return null;
    final items = (await dao.obtenerItems(id)).map(ComboItem.fromMap).toList();
    return Combo.fromMap(fila, items: items);
  }

  Future<bool> existeNombre(String nombre, {int? excluirId}) async =>
      (await ComboDao(await baseDatos.database)).existeNombre(nombre.trim(), excluirId: excluirId);

  Future<int> crear(String nombre) async {
    final db = await baseDatos.database;
    return db.insert('combos', {'nombre': nombre.trim(), 'precio_combo': 0, 'costo_productos': 0, 'ganancia': 0});
  }

  Future<void> renombrar(int id, String nombre) async {
    final db = await baseDatos.database;
    await db.update('combos', {'nombre': nombre.trim()}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> eliminar(int id) async {
    final db = await baseDatos.database;
    await db.delete('combos', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> anadirProducto(int comboId, int productoId, int cantidad, Configuracion configuracion) async {
    if (cantidad < 1) return false;
    final db = await baseDatos.database;
    final yaExiste = await db.query('combo_items', columns: ['id'], where: 'combo_id = ? AND producto_id = ?', whereArgs: [comboId, productoId], limit: 1);
    if (yaExiste.isNotEmpty) return false;
    final p = await db.query('productos', where: 'id = ?', whereArgs: [productoId], limit: 1);
    if (p.isEmpty) return false;
    final venta = (p.first['precio_venta'] as num).toDouble();
    await db.transaction((txn) async {
      await txn.insert('combo_items', {
        'combo_id': comboId,
        'producto_id': productoId,
        'cantidad': cantidad,
        'precio_fila': Calculos.precioFila(venta, cantidad),
      });
      await _recalcularCombo(txn, comboId, configuracion, recalcularFilas: false);
    });
    return true;
  }

  Future<void> actualizarCantidad(int itemId, int cantidad, Configuracion configuracion) async {
    if (cantidad < 1) throw ArgumentError('La cantidad debe ser un entero positivo.');
    final db = await baseDatos.database;
    await db.transaction((txn) async {
      final item = await _obtenerItemPorId(txn, itemId);
      if (item == null) return;
      await txn.update('combo_items', {
        'cantidad': cantidad,
        'precio_fila': Calculos.precioFila(item.precioVenta, cantidad),
      }, where: 'id = ?', whereArgs: [itemId]);
      await _recalcularCombo(txn, item.comboId, configuracion, recalcularFilas: false);
    });
  }

  Future<void> actualizarPrecioFila(int itemId, double precio, Configuracion configuracion) async {
    final db = await baseDatos.database;
    await db.transaction((txn) async {
      final item = await _obtenerItemPorId(txn, itemId);
      if (item == null) return;
      await txn.update('combo_items', {'precio_fila': precio}, where: 'id = ?', whereArgs: [itemId]);
      await _recalcularCombo(txn, item.comboId, configuracion, recalcularFilas: false);
    });
  }

  Future<void> limpiarFila(int itemId, Configuracion configuracion) async {
    final db = await baseDatos.database;
    await db.transaction((txn) async {
      final item = await _obtenerItemPorId(txn, itemId);
      if (item == null) return;
      await txn.update('combo_items', {'cantidad': null, 'precio_fila': null}, where: 'id = ?', whereArgs: [itemId]);
      await _recalcularCombo(txn, item.comboId, configuracion, recalcularFilas: false);
    });
  }

  Future<void> eliminarItem(int itemId, Configuracion configuracion) async {
    final db = await baseDatos.database;
    await db.transaction((txn) async {
      final item = await _obtenerItemPorId(txn, itemId);
      if (item == null) return;
      await txn.delete('combo_items', where: 'id = ?', whereArgs: [itemId]);
      await _recalcularCombo(txn, item.comboId, configuracion, recalcularFilas: false);
    });
  }

  Future<void> editarPrecioCombo(int comboId, double precio, Configuracion configuracion) async {
    final db = await baseDatos.database;
    final row = await ComboDao(db).obtenerComboPorId(comboId);
    if (row == null) return;
    final costo = (row['costo_productos'] as num? ?? 0).toDouble();
    await db.update('combos', {
      'precio_combo': precio,
      'precio_manual': 1,
      'ganancia': Calculos.gananciaCombo(precio, costo, configuracion.tasaReferencia),
      'ganancia_manual': 0,
    }, where: 'id = ?', whereArgs: [comboId]);
  }

  Future<void> editarCostoCombo(int comboId, double costo, Configuracion configuracion) async {
    final db = await baseDatos.database;
    final row = await ComboDao(db).obtenerComboPorId(comboId);
    if (row == null) return;
    final precio = (row['precio_combo'] as num? ?? 0).toDouble();
    await db.update('combos', {
      'costo_productos': costo,
      'costo_manual': 1,
      'ganancia': Calculos.gananciaCombo(precio, costo, configuracion.tasaReferencia),
      'ganancia_manual': 0,
    }, where: 'id = ?', whereArgs: [comboId]);
  }

  Future<void> editarGananciaCombo(int comboId, double ganancia) async {
    final db = await baseDatos.database;
    await db.update('combos', {'ganancia': ganancia, 'ganancia_manual': 1}, where: 'id = ?', whereArgs: [comboId]);
  }

  Future<void> recalcularTodosLosCombos(Configuracion configuracion, {bool recalcularFilas = true}) async {
    final db = await baseDatos.database;
    await db.transaction((txn) async {
      final combos = await txn.query('combos', columns: ['id']);
      for (final row in combos) {
        await _recalcularCombo(txn, (row['id'] as num).toInt(), configuracion, recalcularFilas: recalcularFilas);
      }
    });
  }

  Future<void> recalcularCombosQueContienenProducto(int productoId, Configuracion configuracion, {bool recalcularFilas = true}) async {
    final db = await baseDatos.database;
    await db.transaction((txn) async {
      final ids = await ComboDao(db).combosQueContienenProducto(productoId, executor: txn);
      for (final id in ids) {
        await _recalcularCombo(txn, id, configuracion, recalcularFilas: recalcularFilas);
      }
    });
  }

  Future<void> eliminarProductoDelCatalogo(int productoId, Configuracion configuracion) async {
    final db = await baseDatos.database;
    await db.transaction((txn) async {
      final ids = await ComboDao(db).combosQueContienenProducto(productoId, executor: txn);
      await txn.delete('productos', where: 'id = ?', whereArgs: [productoId]);
      for (final id in ids) {
        await _recalcularCombo(txn, id, configuracion, recalcularFilas: true);
      }
    });
  }

  Future<void> _recalcularCombo(DatabaseExecutor executor, int comboId, Configuracion configuracion, {required bool recalcularFilas}) async {
    final filas = await ComboDao(await baseDatos.database).obtenerItems(comboId, executor: executor);
    double precioCombo = 0;
    double costoProductos = 0;
    for (final fila in filas) {
      final cantidad = (fila['cantidad'] as num?)?.toInt();
      final compra = (fila['precio_compra'] as num).toDouble();
      final venta = (fila['precio_venta'] as num).toDouble();
      if (recalcularFilas) {
        final subtotal = cantidad == null || cantidad < 1 ? null : Calculos.precioFila(venta, cantidad);
        await executor.update('combo_items', {'precio_fila': subtotal}, where: 'id = ?', whereArgs: [fila['item_id']]);
        if (subtotal != null) precioCombo += subtotal;
      } else {
        precioCombo += (fila['precio_fila'] as num?)?.toDouble() ?? 0;
      }
      costoProductos += Calculos.costoFila(compra, cantidad);
    }
    final ganancia = Calculos.gananciaCombo(precioCombo, costoProductos, configuracion.tasaReferencia);
    await executor.update('combos', {
      'precio_combo': precioCombo,
      'costo_productos': costoProductos,
      'ganancia': ganancia,
      'precio_manual': 0,
      'costo_manual': 0,
      'ganancia_manual': 0,
    }, where: 'id = ?', whereArgs: [comboId]);
  }

  Future<ComboItem?> _obtenerItemPorId(DatabaseExecutor executor, int itemId) async {
    final rows = await executor.rawQuery('''SELECT ci.id AS item_id, ci.combo_id, ci.producto_id,
      ci.cantidad, ci.precio_fila, p.nombre, p.precio_compra, p.precio_venta, p.activo
      FROM combo_items ci INNER JOIN productos p ON p.id = ci.producto_id WHERE ci.id = ? LIMIT 1''', [itemId]);
    return rows.isEmpty ? null : ComboItem.fromMap(rows.first);
  }
}
