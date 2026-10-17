import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Paso de migración que lleva el esquema a la versión indicada por su clave.
typedef Migracion = Future<void> Function(DatabaseExecutor db);

/// Migraciones de la app. Para cambiar el esquema:
/// 1. Sube [BaseDatos.versionActual] (por ejemplo, a 2).
/// 2. Agrega aquí la entrada `2: (db) async { ... }` con los ALTER TABLE necesarios.
/// Nunca modifiques una migración ya publicada ni el esquema de `_crearEsquemaV1`:
/// los teléfonos que ya tienen la app solo ejecutan los pasos que les faltan.
final Map<int, Migracion> migracionesApp = {
  2: (db) async {
    // Conserva el orden actual (id de inserción) de cada combo antes de
    // habilitar el reordenamiento persistente.
    await db.execute('ALTER TABLE combo_items ADD COLUMN orden INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE configuracion ADD COLUMN detalle_combo_compacto INTEGER NOT NULL DEFAULT 1');
    final items = await db.query('combo_items', columns: ['id', 'combo_id'], orderBy: 'combo_id, id');
    final siguienteOrden = <int, int>{};
    for (final item in items) {
      final comboId = (item['combo_id'] as num).toInt();
      final orden = siguienteOrden[comboId] ?? 0;
      await db.update('combo_items', {'orden': orden}, where: 'id = ?', whereArgs: [item['id']]);
      siguienteOrden[comboId] = orden + 1;
    }
  },
};

class BaseDatos {
  BaseDatos({
    DatabaseFactory? fabrica,
    String? ruta,
    this.version = versionActual,
    Map<int, Migracion>? migraciones,
  })  : _fabrica = fabrica,
        _ruta = ruta,
        _migraciones = migraciones ?? migracionesApp;

  static final BaseDatos instancia = BaseDatos();
  static const int versionActual = 2;

  final DatabaseFactory? _fabrica;
  final String? _ruta;
  final int version;
  final Map<int, Migracion> _migraciones;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final fabrica = _fabrica ?? databaseFactory;
    final ruta = _ruta ?? p.join(await fabrica.getDatabasesPath(), 'combo_manager.db');
    _database = await fabrica.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await _crearEsquemaV1(db);
          await _migrar(db, 1, version);
        },
        onUpgrade: (db, anterior, nueva) => _migrar(db, anterior, nueva),
      ),
    );
    return _database!;
  }

  Future<void> inicializar() async { await database; }

  Future<void> cerrar() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _migrar(DatabaseExecutor db, int desde, int hasta) async {
    for (var v = desde + 1; v <= hasta; v++) {
      final migracion = _migraciones[v];
      if (migracion == null) throw StateError('Falta la migración de la base de datos a la versión $v.');
      await migracion(db);
    }
  }

  static Future<void> _crearEsquemaV1(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE productos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      precio_compra REAL NOT NULL DEFAULT 0,
      precio_venta REAL NOT NULL DEFAULT 0,
      precio_venta_manual INTEGER NOT NULL DEFAULT 0,
      activo INTEGER NOT NULL DEFAULT 1
    )''');
    await db.execute('''CREATE TABLE combos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL COLLATE BINARY UNIQUE,
      precio_combo REAL NOT NULL DEFAULT 0,
      costo_productos REAL NOT NULL DEFAULT 0,
      ganancia REAL NOT NULL DEFAULT 0,
      precio_manual INTEGER NOT NULL DEFAULT 0,
      costo_manual INTEGER NOT NULL DEFAULT 0,
      ganancia_manual INTEGER NOT NULL DEFAULT 0
    )''');
    await db.execute('''CREATE TABLE combo_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      combo_id INTEGER NOT NULL,
      producto_id INTEGER NOT NULL,
      cantidad INTEGER NULL,
      precio_fila REAL NULL,
      FOREIGN KEY (combo_id) REFERENCES combos(id) ON DELETE CASCADE,
      FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
      UNIQUE(combo_id, producto_id)
    )''');
    await db.execute('''CREATE TABLE configuracion (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      margen REAL NOT NULL DEFAULT 1.5,
      tasa_referencia REAL NOT NULL DEFAULT 755,
      modo_oscuro INTEGER NOT NULL DEFAULT 0
    )''');
    await db.insert('configuracion', {
      'id': 1, 'margen': 1.5, 'tasa_referencia': 755, 'modo_oscuro': 0,
    });
  }
}
