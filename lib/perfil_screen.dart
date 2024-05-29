import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'login_screen.dart';
import 'jugador_screen.dart';
import 'database_service.dart'; 
import 'image_service.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _email = '';
  String _username = '';
  int _coins = 0;
  String _teamName = '';
String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _getUserData();
    _getUserData2();
  }

Future<void> _updateProfileImage(File image) async {
    try {
      String downloadUrl = await ImageService().uploadImage(image, _user!.uid);
      await FirebaseFirestore.instance.collection('usuarios').doc(_user!.uid).update({'profileImageUrl': downloadUrl});
      setState(() {
        _profileImageUrl = downloadUrl;
      });
    } catch (e) {
      print('Error uploading profile image: $e');
    }
  }

  void _pickAndUploadImage() async {
    File? image = await ImageService().pickImage();
    if (image != null) {
      await _updateProfileImage(image);
    }
  }
Future<void> _getUserData2() async {
    try {
      _user = _auth.currentUser;
      if (_user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance.collection('usuarios').doc(_user!.uid).get();
        if (userData.exists) {
          setState(() {
            _email = _user!.email!;
            _username = userData['username'];
            _coins = userData['coins'];
            _teamName = userData['team'] ?? '';
            _profileImageUrl = userData['profileImageUrl'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
  }

  Future<void> _getUserData() async {
    try {
      _user = _auth.currentUser;
      if (_user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance.collection('usuarios').doc(_user!.uid).get();
        if (userData.exists) {
          setState(() {
            _email = _user!.email!;
            _username = userData['username'];
            _coins = userData['coins'];
            _teamName = userData['team'] ?? '';
          });
        }
      }

      

    } catch (e) {
      print('Error getting user data: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error cargando datos del usuario: $e');
    }
  }

  Future<void> _createInitialPlayers() async {
    final positions = [
      'DC', 'MCD', 'PO', 'MC', 'DFC', 'DFD', 'DFI', 'ED', 'EI'
    ];

    List<Map<String, dynamic>> initialPlayers = [];
    final random = Random();

    for (int i = 0; i < 15; i++) {
      String nombre = generarNombre();
      String posicion = positions[random.nextInt(positions.length)];
      int habilidad = 60 + random.nextInt(21); // Habilidad entre 60 y 80
      int precio = habilidad * 10; // Precio basado en la habilidad

      initialPlayers.add({
        'nombre': nombre,
        'posicion': posicion,
        'habilidad': habilidad,
        'precio': precio,
        'enTienda': false,
        'userId': _user!.uid
      });
    }

    WriteBatch batch = FirebaseFirestore.instance.batch();
    CollectionReference jugadoresCollection = FirebaseFirestore.instance.collection('jugadores');

    for (var player in initialPlayers) {
      DocumentReference playerRef = jugadoresCollection.doc();
      batch.set(playerRef, player);
    }

    try {
      await batch.commit();
      print('Initial players created successfully.');
    } catch (e) {
      print('Error creating initial players: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error creando jugadores iniciales: $e');
    }
  }

  Future<void> _checkAndCreateInitialPlayers() async {
    if (_user == null) return;

    final jugadoresSnapshot = await FirebaseFirestore.instance
        .collection('jugadores')
        .where('userId', isEqualTo: _user!.uid)
        .get();

    if (jugadoresSnapshot.docs.isEmpty) {
      await _createInitialPlayers();
    } else {
      print('El usuario ya tiene jugadores.');
    }
  }

  String generarNombre() {
    final nombres = [
      'Carlos', 'Miguel', 'Juan', 'Pedro', 'Luis', 'Jorge', 'Raúl', 'Andrés', 'Fernando', 'Diego',
      'Roberto', 'Sergio', 'Alejandro', 'Daniel', 'José', 'Ricardo', 'Manuel', 'Francisco', 'Héctor', 'Iván',
      'Akira', 'Hiroshi', 'Takashi', 'Yuki', 'Haruto', 'Akihiko', 'Masato', 'Keiko', 'Sakura', 'Aoi',
      'Mohammed', 'Ali', 'Omar', 'Ahmed', 'Youssef', 'Fusto', 'Aisha', 'Layla', 'Nadia', 'Rania',
      'Chen', 'Li', 'Wang', 'Zhang', 'Liu', 'Huang', 'Xu', 'Lin', 'Wu', 'Yang',
      'Matteo', 'Luca', 'Giovanni', 'Marco', 'Antonio', 'Alessandro', 'Giuseppe', 'Fabio', 'Stefano', 'Riccardo',
      'Gabriel', 'Lucas', 'Rafael', 'Mateo', 'Leonardo', 'Diego', 'Julio', 'Antonio', 'Javier', 'Cristian',
      'Martin', 'Eduardo', 'Emilio', 'Mario', 'Pablo', 'Santiago', 'Federico', 'Adrián', 'Enrique', 'Hugo'
    ];

    final apellidos = [
      'García', 'Martínez', 'Rodríguez', 'López', 'González', 'Pérez', 'Sánchez', 'Ramírez', 'Cruz', 'Ortiz',
      'Morales', 'Reyes', 'Jiménez', 'Díaz', 'Vargas', 'Romero', 'Herrera', 'Flores', 'Castro', 'Torres',
      'Alvarez', 'Vega', 'Mendoza', 'Chávez', 'Ramos', 'Gutiérrez', 'Castillo', 'Vásquez', 'Guzmán', 'Muñoz',
      'Navarro', 'Rojas', 'Ortega', 'Rivera', 'Silva', 'Aguilar', 'Delgado', 'Pineda', 'Suárez', 'Campos',
      'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
      'Martin', 'Bernard', 'Dubois', 'Thomas', 'Robert', 'Richard', 'Petit', 'Durand', 'Leroy', 'Moreau',
      'Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner', 'Becker', 'Schulz', 'Hoffmann',
      'Rossi', 'Russo', 'Ferrari', 'Esposito', 'Bianchi', 'Romano', 'Colombo', 'Ricci', 'Marino', 'Greco',
      'Silva', 'Santos', 'Oliveira', 'Pereira', 'Costa', 'Rodrigues', 'Martins', 'Jesus', 'Sousa', 'Fernandes'
    ];

    final random = Random();
    final nombre = nombres[random.nextInt(nombres.length)];
    final apellido = apellidos[random.nextInt(apellidos.length)];

    return '$nombre $apellido';
  }

  void _showCreatePlayersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Crear Jugadores Iniciales'),
          content: Text('¿Estás seguro de que deseas crear los jugadores iniciales para tu equipo?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _checkAndCreateInitialPlayers();
                Navigator.of(context).pop();
                _navigateToJugadoresScreen(); //Navegar .a la pantalla de jugadores
              },
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToJugadoresScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JugadoresScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil de Usuario'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _user == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl.isNotEmpty ? NetworkImage(_profileImageUrl) : null,
                    child: _profileImageUrl.isEmpty ? Icon(Icons.person, size: 50) : null,
                  ),
                  ElevatedButton(
                    onPressed: (){ _pickAndUploadImage(); _getUserData2();},
                    child: Text('Cambiar imagen de equipo'),
                  ),
                  Card(
                    child: ListTile(
                      title: Text(
                        'Correo electrónico',
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        _email,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text(
                        'Nombre de usuario',
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            _username,
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: _showEditUsernameBottomSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text(
                        'Monedas',
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            '$_coins',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.monetization_on),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text(
                        'Nombre del equipo',
                        style: TextStyle(fontSize: 18),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            _teamName,
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: _showEditTeamNameBottomSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_user == null) return;

          final jugadoresSnapshot = await FirebaseFirestore.instance
              .collection('jugadores')
              .where('userId', isEqualTo: _user!.uid)
              .get();

          if (jugadoresSnapshot.docs.isEmpty) {
            _showCreatePlayersDialog();
          } else {
            _navigateToJugadoresScreen();
          }
        },
        child: Icon(Icons.sports_soccer),
      ),
    );
  }

  void _showEditUsernameBottomSheet() {
    TextEditingController _newUsernameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Actualizar nombre de usuario',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _newUsernameController,
                decoration: InputDecoration(labelText: 'Nuevo nombre de usuario'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  String newUsername = _newUsernameController.text;
                  _updateUsername(newUsername);
                  Navigator.pop(context);
                },
                child: Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTeamNameBottomSheet() {
    TextEditingController _newTeamNameController = TextEditingController(text: _teamName);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Actualizar nombre del equipo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _newTeamNameController,
                decoration: InputDecoration(labelText: 'Nuevo nombre del equipo'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  String newTeamName = _newTeamNameController.text;
                  _updateTeamName(newTeamName);
                  Navigator.pop(context);
                },
                child: Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateUsername(String newUsername) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_user!.uid).update({'username': newUsername});
      setState(() {
        _username = newUsername;
      });
      await ServicioBaseDeDatos().insertarRegistro('Cambio de nombre de usuario', 'Nombre de usuario actualizado a $newUsername');
    } catch (e) {
      print('Error updating username: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error actualizando nombre de usuario: $e');
    }
  }

  Future<void> _updateTeamName(String newTeamName) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(_user!.uid).update({'team': newTeamName});
      setState(() {
        _teamName = newTeamName;
      });
      await ServicioBaseDeDatos().insertarRegistro('Cambio de nombre del equipo', 'Nombre del equipo actualizado a $newTeamName');
    } catch (e) {
      print('Error updating team name: $e');
      await ServicioBaseDeDatos().insertarRegistro('Error', 'Error actualizando nombre del equipo: $e');
    }
  }
}
