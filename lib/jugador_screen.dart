import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'tienda_screen.dart';
import 'competir_screen.dart';
import 'logs_screen.dart';
import 'database_service.dart';
import 'perfil_screen.dart';

class JugadoresScreen extends StatefulWidget {
  @override
  _JugadoresScreenState createState() => _JugadoresScreenState();
}

class _JugadoresScreenState extends State<JugadoresScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  int _coins = 0;
  String _teamName = '';
  String _username = '';
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    if (_user != null) {
      _getUserData();
    }
  }

  Future<void> _getUserData() async {
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('usuarios').doc(_user.uid).get();
      if (userData.exists) {
        setState(() {
          _username = userData['username'];
          _coins = userData['coins'];
          _teamName = userData['team'] ?? '';
          _profileImageUrl = userData['profileImageUrl'] ?? '';
        });
      }
    } catch (e) {
      print('Error getting user data: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error obteniendo los datos del usuario: $e');
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _sellPlayer(String playerId, int playerPrice) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar venta'),
          content: Text('¿Estás seguro de que quieres vender este jugador?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _confirmSell(playerId, playerPrice);
                Navigator.pop(context);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmSell(String playerId, int playerPrice) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_user.uid).update({
        'coins': _coins + playerPrice,
      });

      await FirebaseFirestore.instance.collection('jugadores').doc(playerId).update({
        'enTienda': true,
      });

      setState(() {
        _coins += playerPrice;
      });

      await ServicioBaseDeDatos().insertarRegistro('Venta', 'Jugador $playerId vendido por $playerPrice monedas.');
    } catch (e) {
      print('Error al vender jugador: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error al vender jugador: $e');
    }
  }

  Future<void> _improvePlayerSkill(String playerId, int currentSkill) async {
    try {
      int newSkill = currentSkill + 1;
      int improvementCost = newSkill <= 80 ? 2000 : 3000;
      if (newSkill > 99) {
        return; 
      }
      int newPrice = newSkill * 10; 
      if (_coins < improvementCost) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('No tienes suficientes monedas para mejorar la habilidad del jugador.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Aceptar'),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirmar mejora'),
              content: Text('¿Estás seguro de que quieres mejorar la habilidad del jugador por $improvementCost monedas?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmImprovement(playerId, newSkill, newPrice, improvementCost);
                  },
                  child: Text('Sí'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancelar'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error al mejorar la habilidad del jugador: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error al mejorar la habilidad del jugador: $e');
    }
  }

  Future<void> _confirmImprovement(String playerId, int newSkill, int newPrice, int improvementCost) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_user.uid).update({
        'coins': _coins - improvementCost,
      });

      await FirebaseFirestore.instance.collection('jugadores').doc(playerId).update({
        'habilidad': newSkill,
        'precio': newPrice,
      });

      setState(() {
        _coins -= improvementCost;
      });

      await ServicioBaseDeDatos().insertarRegistro('Mejora', 'Jugador $playerId mejorado a habilidad $newSkill por $improvementCost monedas.');
    } catch (e) {
      print('Error al confirmar la mejora del jugador: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error al confirmar la mejora del jugador: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Jugadores'),
        actions: [
           IconButton(
            icon: Icon(Icons.arrow_back_sharp),
            onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row( children: [
                  Text('Equipo: $_teamName  '),
                   CircleAvatar(
                    radius: 20,
                    backgroundImage: _profileImageUrl.isNotEmpty ? NetworkImage(_profileImageUrl) : null,
                    child: _profileImageUrl.isEmpty ? Icon(Icons.person, size: 50) : null,
                  ),
                  ]
                  ),
                  SizedBox(height: 5),
                  Text('Entrenador: $_username '),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.monetization_on),
                      SizedBox(width: 10),
                      Text('Monedas: $_coins'),
                      
                    ],
                  ),
                 
                  
                 
                ],
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: Icon(Icons.store),
              title: Text('Tienda de Jugadores'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TiendaScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_soccer),
              title: Text('Competir'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CompetenciaScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.running_with_errors),
              title: Text('Logs'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jugadores')
            .where('userId', isEqualTo: _user.uid)
            .where('enTienda', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay jugadores en el equipo'));
          }

          final jugadores = snapshot.data!.docs;

          return ListView.builder(
            itemCount: jugadores.length,
            itemBuilder: (context, index) {
              final jugador = jugadores[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(jugador['nombre']),
                subtitle: Text('Posición: ${jugador['posicion']} - Habilidad: ${jugador['habilidad']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Precio: ${jugador['precio']}'),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.attach_money),
                          onPressed: () {
                            _sellPlayer(jugadores[index].id, jugador['precio']);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_upward),
                          onPressed: () {
                            _improvePlayerSkill(jugadores[index].id, jugador['habilidad']);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
