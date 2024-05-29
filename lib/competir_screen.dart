import 'dart:math';
import 'jugador_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class CompetenciaScreen extends StatefulWidget {
  @override
  _CompetenciaScreenState createState() => _CompetenciaScreenState();
}

class _CompetenciaScreenState extends State<CompetenciaScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  double _habilidadPromedio = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _calcularHabilidadPromedio();
  }

  Future<void> _calcularHabilidadPromedio() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('jugadores')
          .where('userId', isEqualTo: _user.uid)
          .orderBy('habilidad', descending: true)
          .limit(11)
          .get();

      if (snapshot.docs.isNotEmpty) {
        double totalHabilidad = 0;
        for (var doc in snapshot.docs) {
          totalHabilidad += doc['habilidad'];
        }
        setState(() {
          _habilidadPromedio = totalHabilidad / snapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error al calcular el promedio de habilidad: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error al calcular el promedio de habilidad: $e');
    }
  }

  Future<int> _obtenerMonedasUsuario() async {
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_user.uid)
          .get();
      if (userData.exists) {
        return userData['coins'];
      }
    } catch (e) {
      print('Error obteniendo las monedas del usuario: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error obteniendo las monedas del usuario: $e');
    }
    return 0;
  }

  Future<void> _actualizarMonedasUsuario(int nuevasMonedas) async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_user.uid)
          .update({'coins': nuevasMonedas});
    } catch (e) {
      print('Error actualizando las monedas del usuario: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error actualizando las monedas del usuario: $e');
    }
  }

  Future<void> _simularPartido(Map<String, dynamic> equipo) async {
    final int dificultadEquipo = equipo['dificultad'];
    final int recompensaEquipo = equipo['recompensa'];
    final int monedasUsuario = await _obtenerMonedasUsuario();

    double probabilidadGanar = _habilidadPromedio - dificultadEquipo;
    Random random = Random();
    int golesUsuario = random.nextInt(5);
    int golesOponente = random.nextInt(5);

    String mensajeResultado;
    int monedasGanadas;
    if (golesUsuario > golesOponente) {
      mensajeResultado = '¡Felicidades! Has ganado el partido.';
      monedasGanadas = recompensaEquipo;
    } else if (golesUsuario == golesOponente) {
      mensajeResultado = 'El partido ha terminado en empate.';
      monedasGanadas = recompensaEquipo ~/ 2;
    } else {
      mensajeResultado = 'Lo siento, has perdido el partido.';
      monedasGanadas = 0;
    }

    int nuevasMonedas = monedasUsuario + monedasGanadas;
    await _actualizarMonedasUsuario(nuevasMonedas);

    await ServicioBaseDeDatos().insertarRegistro('Partido', 'Partido jugado: $mensajeResultado. Goles: $golesUsuario-$golesOponente. Monedas ganadas: $monedasGanadas');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resultado del Partido'),
          content: Text('$mensajeResultado\nGoles anotados por ti: $golesUsuario\nGoles anotados por el oponente: $golesOponente\nMonedas ganadas: $monedasGanadas'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Competir'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back_sharp),
            onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => JugadoresScreen()),
                );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Promedio de Habilidad de los Mejores 11 Jugadores: ${_habilidadPromedio.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('equipos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No hay equipos disponibles para competir.'));
                }

                final equipos = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: equipos.length,
                  itemBuilder: (context, index) {
                    final equipo = equipos[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        leading: Image.network(
                          equipo['escudoUrl'],
                          width: 50,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            );
                          },
                        ),
                        title: Text(equipo['nombre']),
                        subtitle: Text('Dificultad: ${equipo['dificultad']}, Recompensa: ${equipo['recompensa']}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            _simularPartido(equipo);
                          },
                          child: Text('Jugar Partido'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
