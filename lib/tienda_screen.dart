import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'jugador_screen.dart';
import 'database_service.dart'; 
import 'perfil_screen.dart';

class TiendaScreen extends StatefulWidget {
  @override
  _TiendaScreenState createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('usuarios').doc(_user.uid).get();
      setState(() {
        _coins = userData['coins'];
      });
    } catch (e) {
      print('Error loading user data: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error cargando datos del usuario: $e');
    }
  }

  Future<void> _buyPlayer(String playerId, int playerPrice) async {
    if (_coins < playerPrice) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Saldo insuficiente'),
            content: Text('No tienes suficientes monedas para comprar este jugador.'),
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
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar compra'),
          content: Text('¿Estás seguro de que quieres comprar este jugador?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _confirmBuy(playerId, playerPrice);
                Navigator.pop(context);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmBuy(String playerId, int playerPrice) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_user.uid).update({
        'coins': _coins - playerPrice,
      });

      await FirebaseFirestore.instance.collection('jugadores').doc(playerId).update({
        'enTienda': false,
        'userId': _user.uid,
      });

      setState(() {
        _coins -= playerPrice;
      });

      await ServicioBaseDeDatos().insertarRegistro('Compra', 'Jugador $playerId comprado por $playerPrice monedas.');
    } catch (e) {
      print('Error al comprar jugador: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error al comprar jugador: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tienda de Jugadores'),
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
              child: Row(
                children: [
                  Icon(Icons.monetization_on),
                  SizedBox(width: 10),
                  Text('Monedas: $_coins'),
                ],
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Mis Jugadores'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => JugadoresScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jugadores')
            .where('enTienda', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay jugadores disponibles en la tienda'));
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
                    IconButton(
                      icon: Icon(Icons.attach_money),
                      onPressed: () {
                        _buyPlayer(jugadores[index].id, jugador['precio']);
                      },
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
