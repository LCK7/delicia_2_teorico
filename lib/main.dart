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
import 'screens/gestion_pedidos_screen.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.green.shade700,
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade700,
          elevation: 4,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 15,
          selectedItemColor: Colors.green.shade800,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      home: const HomeScreen(),
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
      setState(() {
        _isAdmin = false;
        _loading = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    setState(() {
      _isAdmin = doc.exists && doc.data()?['admin'] == true;
      _loading = false;
    });
  }

  void _onItemTapped(int index) {
    final user = FirebaseAuth.instance.currentUser;

    if (!_isAdmin && index == 2 && user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      return;
    }

    if (_isAdmin) {
      final isProtected = index != 0;
      if (isProtected && user == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
        return;
      }
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    //Pantallas
    final userPages = [
      CatalogoScreen(),
      CarritoScreen(),
      PerfilScreen(),
    ];

    final adminPages = [
      CatalogoScreen(),
      CarritoScreen(),
      CRUDScreen(),
      ProduccionScreen(),
      GestionPedidosScreen(),
      VentasAdminScreen(),
      PerfilScreen(),
    ];

    final pages = _isAdmin ? adminPages : userPages;

    //Navegacion por defecto
    final userNav = const [
      BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Catálogo'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
    ];
    //Navegacion cuando el usuario es admin
    final adminNav = const [
      BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Catálogo'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'CRUD'),
      BottomNavigationBarItem(icon: Icon(Icons.local_cafe), label: 'Producción'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Pedidos'),
      BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
    ];

    final navItems = _isAdmin ? adminNav : userNav;

    // Corrección automática si el index sobrepasa
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panadería Delicia',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (FirebaseAuth.instance.currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  setState(() {
                    _isAdmin = false;
                    _selectedIndex = 0;
                  });
                },
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: navItems,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
