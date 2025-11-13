import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  User? user;
  Map<String, dynamic>? perfil;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      setState(() => perfil = doc.data());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(
        child: Text('No hay usuario autenticado.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              (perfil?['nombre'] ?? user!.email ?? 'U')
                  .toString()
                  .substring(0, 1)
                  .toUpperCase(),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nombre
          Text(
            perfil?['nombre'] ?? 'Sin nombre',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            user!.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 20),

          // Contenedor estilizado
          _infoCard(
            icon: Icons.phone,
            title: perfil?['telefono'] ?? 'No registrado',
            subtitle: 'Teléfono',
          ),

          const SizedBox(height: 12),

          _infoCard(
            icon: Icons.calendar_today,
            title: perfil?['fechaRegistro'] != null
                ? perfil!['fechaRegistro']
                    .toDate()
                    .toString()
                    .split(' ')
                    .first
                : 'No disponible',
            subtitle: 'Fecha de registro',
          ),

          const SizedBox(height: 12),

          _infoCard(
            icon: Icons.admin_panel_settings,
            title:
                perfil?['admin'] == true ? 'Administrador' : 'Usuario normal',
            subtitle: 'Rol',
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}
