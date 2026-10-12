import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BaseDatos {
  BaseDatos._();
  static final BaseDatos instancia = BaseDatos._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final ruta = p.join(await getDatabasesPath(), 'combo_manager.db');
    _database = await openDatabase(
      ruta,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
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
      },
    );
    return _database!;
  }

  Future<void> inicializar() async { await database; }
}
