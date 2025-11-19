import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'carrito_screen.dart';
import 'login_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _procesando = false;
  String _direccion = "";
  String _referencia = "";
  String _tipoEntrega = "Domicilio";
  String _tipoPago = "Efectivo";

  final _direccionCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDireccion();
  }

  Future<void> _cargarDireccion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()!.containsKey('direccion')) {
      _direccion = doc['direccion'];
      _direccionCtrl.text = _direccion;
      setState(() {});
    }
  }

  Future<void> _confirmarPedido() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      return;
    }

    final items = SimpleCart.instance.items;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tu carrito está vacío")),
      );
      return;
    }

    if (_direccionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes ingresar una dirección")),
      );
      return;
    }

    setState(() => _procesando = true);

    try {
      final pedido = {
        'usuarioId': user.uid,
        'email': user.email,
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'pendiente',

        // NUEVOS CAMPOS
        'direccion': _direccionCtrl.text.trim(),
        'referencia': _referenciaCtrl.text.trim(),
        'tipoEntrega': _tipoEntrega,
        'tipoPago': _tipoPago,

        'items': items.map((it) => {
              'id': it['id'],
              'nombre': it['nombre'],
              'precio': it['precio'],
              'cantidad': it['cantidad'],
              'subtotal': (it['precio'] as num) * (it['cantidad'] as int),
              'imagen': it['imagen'],
            }).toList(),

        'total': SimpleCart.instance.total,
      };

      await FirebaseFirestore.instance.collection('pedidos').add(pedido);

      SimpleCart.instance.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido registrado")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = SimpleCart.instance.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Confirmar Pedido",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Dirección
            TextField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(
                labelText: "Dirección de entrega",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Referencia
            TextField(
              controller: _referenciaCtrl,
              decoration: const InputDecoration(
                labelText: "Referencia",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Tipo de entrega
            const Text("Lugar de entrega"),
            DropdownButton<String>(
              value: _tipoEntrega,
              items: const [
                DropdownMenuItem(value: "Domicilio", child: Text("Domicilio")),
                DropdownMenuItem(value: "Tienda", child: Text("Recoger en tienda")),
              ],
              onChanged: (v) => setState(() => _tipoEntrega = v!),
            ),

            const SizedBox(height: 20),

            // Tipo de pago
            const Text("Tipo de pago"),
            DropdownButton<String>(
              value: _tipoPago,
              items: const [
                DropdownMenuItem(value: "Efectivo", child: Text("Efectivo")),
                DropdownMenuItem(value: "Yape", child: Text("Yape")),
                DropdownMenuItem(value: "Plin", child: Text("Plin")),
                DropdownMenuItem(value: "Tarjeta", child: Text("Tarjeta")),
              ],
              onChanged: (v) => setState(() => _tipoPago = v!),
            ),

            const SizedBox(height: 25),

            Text(
              "Total a pagar:",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            Text(
              "S/ ${total.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),

            const Spacer(),

            _procesando
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmarPedido,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Confirmar Pedido",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
