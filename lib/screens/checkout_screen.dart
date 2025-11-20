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
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Confirmar Pedido",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            // Dirección
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(
                    labelText: "Dirección de entrega",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Referencia
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _referenciaCtrl,
                  decoration: const InputDecoration(
                    labelText: "Referencia",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Tipo de entrega
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: _tipoEntrega,
                  decoration: const InputDecoration(
                    labelText: "Lugar de entrega",
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: "Domicilio", child: Text("Domicilio")),
                    DropdownMenuItem(
                        value: "Tienda", child: Text("Recoger en tienda")),
                  ],
                  onChanged: (v) => setState(() => _tipoEntrega = v!),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Tipo de pago
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: _tipoPago,
                  decoration: const InputDecoration(
                    labelText: "Tipo de pago",
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(value: "Efectivo", child: Text("Efectivo")),
                    DropdownMenuItem(value: "Yape", child: Text("Yape")),
                    DropdownMenuItem(value: "Plin", child: Text("Plin")),
                    DropdownMenuItem(
                        value: "Tarjeta", child: Text("Tarjeta")),
                  ],
                  onChanged: (v) => setState(() => _tipoPago = v!),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Total
            Center(
              child: Column(
                children: [
                  Text(
                    "Total a pagar:",
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "S/ ${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Botón
            _procesando
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmarPedido,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Confirmar Pedido",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
