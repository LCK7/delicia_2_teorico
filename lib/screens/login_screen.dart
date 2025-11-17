import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _direccion = TextEditingController();

  bool _registrando = false;
  bool _cargando = false;

  Future<void> _login() async {
    setState(() => _cargando = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error login: ${e.message}')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _register() async {
    if (_nombre.text.trim().isEmpty ||
        _telefono.text.trim().isEmpty ||
        _direccion.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos de registro')));
      return;
    }
    setState(() => _cargando = true);
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      final user = result.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'nombre': _nombre.text.trim(),
          'telefono': _telefono.text.trim(),
          'direccion': _direccion.text.trim(),
          'admin': false,
          'fechaRegistro': FieldValue.serverTimestamp()
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro exitoso')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error registro: ${e.message}')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nombre.dispose();
    _telefono.dispose();
    _direccion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delicia - Login / Registro'),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [_registrando == false, _registrando == true],
              onPressed: (i) {
                setState(() {
                  _registrando = i == 1;
                });
              },
              children: const [
                Padding(padding: EdgeInsets.all(8), child: Text('Login')),
                Padding(padding: EdgeInsets.all(8), child: Text('Registro'))
              ],
            ),
            const SizedBox(height: 16),
            if (_registrando) ...[
              TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 10),
              TextField(controller: _telefono, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 10),
              TextField(controller: _direccion, decoration: const InputDecoration(labelText: 'Dirección')),
              const SizedBox(height: 10),
            ],
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
            const SizedBox(height: 16),
            _cargando
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _registrando ? _register : _login,
                    icon: Icon(_registrando ? Icons.app_registration : Icons.login),
                    label: Text(_registrando ? 'Registrarme' : 'Iniciar sesión'),
                    style: ElevatedButton.styleFrom(backgroundColor: _registrando ? Colors.blue : Colors.green),
                  ),
            const SizedBox(height: 16),
            const Text('Delicia - Panadería', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
