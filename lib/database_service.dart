import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ServicioBaseDeDatos {
  static final ServicioBaseDeDatos _instance = ServicioBaseDeDatos._internal();
  factory ServicioBaseDeDatos() => _instance;

  ServicioBaseDeDatos._internal();

  Database? _baseDeDatos;

  Future<Database> get baseDeDatos async {
    if (_baseDeDatos != null) return _baseDeDatos!;
    _baseDeDatos = await _inicializarBaseDeDatos();
    return _baseDeDatos!;
  }

  Future<Database> _inicializarBaseDeDatos() async {
    String path = join(await getDatabasesPath(), 'db1.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _crearBaseDeDatos,
    );
  }

  Future<void> _crearBaseDeDatos(Database db, int version) async {
    await db.execute('''
      CREATE TABLE registros(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT,
        mensaje TEXT,
        fecha_hora TEXT
      )
    ''');
  }

  Future<void> insertarRegistro(String tipo, String mensaje) async {
    final db = await baseDeDatos;
    await db.insert('registros', {
      'tipo': tipo,
      'mensaje': mensaje,
      'fecha_hora': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> obtenerRegistros() async {
    final db = await baseDeDatos;
    return await db.query('registros', orderBy: 'fecha_hora DESC');
  }

    Future<void> eliminarTodosLosRegistros() async {

    final db = await baseDeDatos;
    await db.delete('registros');
  }
}
