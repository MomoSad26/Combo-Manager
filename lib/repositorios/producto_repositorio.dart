import '../base_datos/base_datos.dart';
import '../base_datos/producto_dao.dart';
import '../logica/calculos.dart';
import '../modelos/configuracion.dart';
import '../modelos/producto.dart';

class ProductoRepositorio {
  ProductoRepositorio(this.baseDatos);
  final BaseDatos baseDatos;

  Future<ProductoDao> _dao() async => ProductoDao(await baseDatos.database);
  Future<List<Producto>> obtenerTodos() async => (await _dao()).obtenerTodos();
  Future<Producto?> obtenerPorId(int id) async => (await _dao()).obtenerPorId(id);

  Future<bool> existeNombre(String nombre, {int? excluirId}) async =>
      (await _dao()).existeNombre(nombre, excluirId: excluirId);

  Future<int> crear({
    required String nombre,
    required double precioCompra,
    required double precioVenta,
    required bool precioVentaManual,
  }) async {
    final dao = await _dao();
    final id = await dao.db.insert('productos', {
      'nombre': nombre.trim(),
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'precio_venta_manual': precioVentaManual ? 1 : 0,
      'activo': 1,
    });
    return id;
  }

  Future<void> actualizar(Producto producto) async => (await _dao()).actualizar(producto);

  Future<void> actualizarEstado(int id, bool activo) async {
    final db = await baseDatos.database;
    await db.update('productos', {'activo': activo ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> eliminar(int id) async => (await _dao()).eliminar(id);

  Future<void> recalcularTodosLosPrecios(Configuracion configuracion) async {
    final db = await baseDatos.database;
    await db.transaction((txn) async {
      await ProductoDao(db).recalcularVentas(configuracion.margen, configuracion.tasaReferencia, executor: txn);
    });
  }

  double calcularPrecioVenta(double compra, Configuracion configuracion) =>
      Calculos.precioVentaProducto(compra, configuracion.margen, configuracion.tasaReferencia);
}
