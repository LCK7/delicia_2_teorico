import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/login_screen.dart';
import 'screens/catalogo_screen.dart';
import 'screens/carrito_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/CRUD_screen.dart';
import 'screens/produccion_screen.dart';
import 'screens/ventas_admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DeliciaApp());
}

class DeliciaApp extends StatelessWidget {
  const DeliciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delicia',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarRolUsuario();
  }

  Future<void> _cargarRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _isAdmin = false;
      _loading = false;
      setState(() {});
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    _isAdmin = doc.exists && doc.data()?['admin'] == true;
    _loading = false;
    setState(() {});
  }

  // 📌 VALIDACIÓN CORRECTA AHORA
  void _onItemTapped(int index) {
    final user = FirebaseAuth.instance.currentUser;

    // Para USUARIOS NORMALES
    if (!_isAdmin) {
      // 0 = catálogo, 1 = carrito, 2 = perfil
      if (index == 2 && user == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
        return;
      }
    }

    // Para ADMIN
    if (_isAdmin) {
      // 0=catalogo 1=carrito 2=CRUD 3=producción 4=perfil
      final isProtected = index == 2 || index == 3 || index == 4;

      if (isProtected && user == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 👑 PÁGINAS SEGÚN ROL
    final List<Widget> pages = _isAdmin
        ? [
            CatalogoScreen(),
            CarritoScreen(),
            CRUDScreen(),
            ProduccionScreen(),
            VentasAdminScreen(),
            PerfilScreen(),
          ]
        : [
            CatalogoScreen(),
            CarritoScreen(),
            PerfilScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = _isAdmin
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Catálogo'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'CRUD'),
            BottomNavigationBarItem(icon: Icon(Icons.production_quantity_limits), label: 'Producción'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Catálogo'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ];

    // Evita errores si cambia el rol o se recarga
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delicia - Panadería'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                setState(() {
                  _isAdmin = false;
                  _selectedIndex = 0;
                });
              },
            )
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
