import 'dart:convert';
import 'dart:typed_data';
import '../base_datos/base_datos.dart';
import '../modelos/resultado_importacion.dart';
import '../repositorios/configuracion_repositorio.dart';
import 'calculos.dart';
import 'nombres.dart';

class RespaldoVersionNueva implements Exception {
  const RespaldoVersionNueva();
  @override
  String toString() => 'El respaldo es de una versión más nueva.';
}

class RespaldoInvalido implements Exception {
  const RespaldoInvalido();
  @override
  String toString() => 'El archivo no es un respaldo válido.';
}

class RespaldoService {
  RespaldoService(this._baseDatos, this._configuracionRepositorio);
  final BaseDatos _baseDatos;
  final ConfiguracionRepositorio _configuracionRepositorio;
  static const int versionActual = 1;

  Future<Uint8List> crearRespaldo() async {
    final db = await _baseDatos.database;
    final config = await _configuracionRepositorio.obtener();
    final productos = await db.query('productos', orderBy: 'nombre COLLATE NOCASE, nombre COLLATE BINARY, id');
    final combos = await db.query('combos', orderBy: 'nombre COLLATE NOCASE, nombre COLLATE BINARY, id');
    final combosExportados = <Map<String, Object?>>[];
    for (final combo in combos) {
      final comboId = (combo['id'] as num).toInt();
      final items = await db.rawQuery('''SELECT ci.cantidad, ci.precio_fila, p.nombre AS producto_nombre,
          p.precio_compra AS producto_precio_compra, p.precio_venta AS producto_precio_venta,
          p.precio_venta_manual AS producto_precio_venta_manual, p.activo AS producto_activo
          FROM combo_items ci INNER JOIN productos p ON p.id = ci.producto_id
          WHERE ci.combo_id = ? ORDER BY ci.id''', [comboId]);
      combosExportados.add({
        'nombre': combo['nombre'],
        'precio_combo': combo['precio_combo'],
        'costo_productos': combo['costo_productos'],
        'ganancia': combo['ganancia'],
        'precio_manual': combo['precio_manual'],
        'costo_manual': combo['costo_manual'],
        'ganancia_manual': combo['ganancia_manual'],
        'items': items.map((item) => <String, Object?>{
          'producto_nombre': item['producto_nombre'],
          'cantidad': item['cantidad'],
          'precio_fila': item['precio_fila'],
          'producto_precio_compra': item['producto_precio_compra'],
          'producto_precio_venta': item['producto_precio_venta'],
          'producto_precio_venta_manual': item['producto_precio_venta_manual'],
          'producto_activo': item['producto_activo'],
        }).toList(),
      });
    }

    final fecha = DateTime.now().toIso8601String();
    final contenido = <String, Object?>{
      'version': versionActual,
      'fecha_exportacion': fecha,
      'configuracion': {
        'margen': config.margen,
        'tasa_referencia': config.tasaReferencia,
      },
      'productos': productos.map((p) => <String, Object?>{
        'nombre': p['nombre'],
        'precio_compra': p['precio_compra'],
        'precio_venta': p['precio_venta'],
        'precio_venta_manual': (p['precio_venta_manual'] as num? ?? 0) == 1,
        'activo': (p['activo'] as num? ?? 1) == 1,
      }).toList(),
      'combos': combosExportados,
    };
    return Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(contenido)));
  }

  Future<ResultadoImportacion> importar(Uint8List bytes) async {
    dynamic decodificado;
    try {
      decodificado = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const RespaldoInvalido();
    }
    if (decodificado is! Map<String, dynamic>) throw const RespaldoInvalido();
    final root = decodificado;
    if (root['version'] == null || root['productos'] is! List || root['combos'] is! List || root['configuracion'] is! Map) {
      throw const RespaldoInvalido();
    }
    final version = _entero(root['version']);
    if (version > versionActual) throw const RespaldoVersionNueva();
    if (version < 1) throw const RespaldoInvalido();
    final productosBackup = (root['productos'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final combosBackup = (root['combos'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (productosBackup.length != (root['productos'] as List).length || combosBackup.length != (root['combos'] as List).length) {
      throw const RespaldoInvalido();
    }
    for (final p in productosBackup) {
      if (p['nombre'] is! String || (p['nombre'] as String).trim().isEmpty || p['precio_compra'] is! num || p['precio_venta'] is! num) {
        throw const RespaldoInvalido();
      }
      if (_numero(p['precio_compra']) < 0 || _numero(p['precio_venta']) < 0) throw const RespaldoInvalido();
    }
    final configuracionBackup = root['configuracion'] as Map;
    if (configuracionBackup['margen'] is! num || configuracionBackup['tasa_referencia'] is! num) {
      throw const RespaldoInvalido();
    }
    final margenBackup = _numero(configuracionBackup['margen']);
    final tasaBackup = _numero(configuracionBackup['tasa_referencia']);
    if (!margenBackup.isFinite || margenBackup <= 0 || !tasaBackup.isFinite || tasaBackup <= 0) {
      throw const RespaldoInvalido();
    }
    for (final c in combosBackup) {
      if (c['nombre'] is! String || (c['nombre'] as String).trim().isEmpty || c['items'] is! List) {
        throw const RespaldoInvalido();
      }
      for (final campo in ['precio_combo', 'costo_productos', 'ganancia']) {
        if (c[campo] != null && c[campo] is! num) throw const RespaldoInvalido();
      }
    }

    final db = await _baseDatos.database;
    final configuracionActual = await _configuracionRepositorio.obtener();
    var productosAgregados = 0;
    var combosAgregados = 0;
    var productosExistentes = 0;
    var combosExistentes = 0;
    final configuracionCambiada = (configuracionActual.margen - margenBackup).abs() > 1e-12 ||
        (configuracionActual.tasaReferencia - tasaBackup).abs() > 1e-12;

    await db.transaction((txn) async {
      if (configuracionCambiada) {
        await txn.update('configuracion', {'margen': margenBackup, 'tasa_referencia': tasaBackup}, where: 'id = 1');
      }
      final mapaProductos = <String, int>{};
      final productosActuales = await txn.query('productos', columns: ['id', 'nombre'], orderBy: 'id');
      for (final p in productosActuales) {
        mapaProductos.putIfAbsent(normalizarNombre(p['nombre'] as String), () => (p['id'] as num).toInt());
      }

      for (final p in productosBackup) {
        final nombre = (p['nombre'] as String).trim();
        if (mapaProductos.containsKey(normalizarNombre(nombre))) {
          productosExistentes++;
          continue;
        }
        final id = await txn.insert('productos', {
          'nombre': nombre,
          'precio_compra': _numero(p['precio_compra']),
          'precio_venta': _numero(p['precio_venta']),
          'precio_venta_manual': _booleano(p['precio_venta_manual']) ? 1 : 0,
          'activo': p.containsKey('activo') && !_booleano(p['activo']) ? 0 : 1,
        });
        mapaProductos[normalizarNombre(nombre)] = id;
        productosAgregados++;
      }

      final nombresCombosActuales = (await txn.query('combos', columns: ['nombre'])).map((r) => normalizarNombre(r['nombre'] as String)).toSet();
      for (final c in combosBackup) {
        final nombreCombo = (c['nombre'] as String).trim();
        if (nombresCombosActuales.contains(normalizarNombre(nombreCombo))) {
          combosExistentes++;
          continue;
        }

        final elementos = (c['items'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        if (elementos.length != (c['items'] as List).length) throw const RespaldoInvalido();
        final itemsPreparados = <Map<String, Object?>>[];
        for (final item in elementos) {
          final nombreProducto = item['producto_nombre'];
          if (nombreProducto is! String || nombreProducto.trim().isEmpty) throw const RespaldoInvalido();
          final nombre = nombreProducto.trim();
          var productoId = mapaProductos[normalizarNombre(nombre)];
          if (productoId == null) {
            final compra = _numero(item['producto_precio_compra']);
            final venta = _numero(item['producto_precio_venta']);
            productoId = await txn.insert('productos', {
              'nombre': nombre,
              'precio_compra': compra,
              'precio_venta': venta,
              'precio_venta_manual': _booleano(item['producto_precio_venta_manual']) ? 1 : 0,
              'activo': item.containsKey('producto_activo') && !_booleano(item['producto_activo']) ? 0 : 1,
            });
            mapaProductos[normalizarNombre(nombre)] = productoId;
            productosAgregados++;
          }
          final cantidadRaw = item['cantidad'];
          final cantidad = cantidadRaw == null ? null : _entero(cantidadRaw);
          if (cantidad != null && cantidad < 1) throw const RespaldoInvalido();
          final producto = await txn.query('productos', where: 'id = ?', whereArgs: [productoId], limit: 1);
          if (producto.isEmpty) throw const RespaldoInvalido();
          final precioVenta = _numero(producto.first['precio_venta']);
          final precioFila = item.containsKey('precio_fila')
              ? (item['precio_fila'] == null ? null : _numero(item['precio_fila']))
              : (cantidad == null ? null : Calculos.precioFila(precioVenta, cantidad));
          itemsPreparados.add({
            'producto_id': productoId,
            'cantidad': cantidad,
            'precio_fila': precioFila,
            'precio_compra': _numero(producto.first['precio_compra']),
          });
        }

        final idCombo = await txn.insert('combos', {
          'nombre': nombreCombo,
          'precio_combo': c['precio_combo'] == null ? 0 : _numero(c['precio_combo']),
          'costo_productos': c['costo_productos'] == null ? 0 : _numero(c['costo_productos']),
          'ganancia': c['ganancia'] == null ? 0 : _numero(c['ganancia']),
          'precio_manual': _booleano(c['precio_manual']) ? 1 : 0,
          'costo_manual': _booleano(c['costo_manual']) ? 1 : 0,
          'ganancia_manual': _booleano(c['ganancia_manual']) ? 1 : 0,
        });
        for (final item in itemsPreparados) {
          await txn.insert('combo_items', {
            'combo_id': idCombo,
            'producto_id': item['producto_id'],
            'cantidad': item['cantidad'],
            'precio_fila': item['precio_fila'],
          });
        }

        // Si los tres valores no vienen en el respaldo (o son null), se crean en modo automático.
        if (c['precio_combo'] == null || c['costo_productos'] == null || c['ganancia'] == null) {
          double precio = 0;
          double costo = 0;
          for (final item in itemsPreparados) {
            precio += (item['precio_fila'] as num?)?.toDouble() ?? 0;
            costo += Calculos.costoFila((item['precio_compra'] as num).toDouble(), (item['cantidad'] as num?)?.toInt());
          }
          await txn.update('combos', {
            'precio_combo': precio,
            'costo_productos': costo,
            'ganancia': Calculos.gananciaCombo(precio, costo, configuracionActual.tasaReferencia),
            'precio_manual': 0,
            'costo_manual': 0,
            'ganancia_manual': 0,
          }, where: 'id = ?', whereArgs: [idCombo]);
        }
        nombresCombosActuales.add(normalizarNombre(nombreCombo));
        combosAgregados++;
      }
    });

    return ResultadoImportacion(
      productosAgregados: productosAgregados,
      combosAgregados: combosAgregados,
      productosExistentes: productosExistentes,
      combosExistentes: combosExistentes,
      configuracionCambiada: configuracionCambiada,
    );
  }

  int _entero(dynamic valor) => valor is num ? valor.toInt() : int.tryParse('$valor') ?? -1;
  double _numero(dynamic valor) => valor is num ? valor.toDouble() : double.tryParse('$valor') ?? 0;
  bool _booleano(dynamic valor) => valor == true || valor == 1 || valor == '1';
}
