import 'package:flutter/material.dart';
import 'database_service.dart';

class LogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registros'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              // eliminar todos los registros
              await ServicioBaseDeDatos().eliminarTodosLosRegistros();
              //  mensaje de éxito 
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Todos los registros han sido eliminados.'))
              );
              // Refrescar
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LogsScreen())
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ServicioBaseDeDatos().obtenerRegistros(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay registros.'));
          }

          final registros = snapshot.data!;

          return ListView.builder(
            itemCount: registros.length,
            itemBuilder: (context, index) {
              final registro = registros[index];
              return ListTile(
                title: Text('${registro['tipo']} - ${registro['fecha_hora']}'),
                subtitle: Text(registro['mensaje']),
              );
            },
          );
        },
      ),
    );
  }
}
