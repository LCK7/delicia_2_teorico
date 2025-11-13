import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({super.key});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  String? _productoId;
  int _cantidadProducida = 0;
  int _stockActual = 0;

  final TextEditingController _cantidadController = TextEditingController();

  Future<void> _cargarStock(String productoId) async {
    final doc = await FirebaseFirestore.instance.collection('productos').doc(productoId).get();
    if (doc.exists) {
      final stock = doc.data()?['stock'] ?? 0;
      setState(() => _stockActual = stock);
    }
  }

  Future<void> _guardarProduccion() async {
    if (_productoId == null || _cantidadProducida <= 0) {
      _msg("Selecciona un producto y una cantidad válida");
      return;
    }

    final hoy = DateTime.now();
    final fecha = DateTime(hoy.year, hoy.month, hoy.day);

    await FirebaseFirestore.instance.collection('produccion_diaria').add({
      'productoId': _productoId,
      'cantidadProducida': _cantidadProducida,
      'fecha': fecha,
    });

    final productoRef =
        FirebaseFirestore.instance.collection('productos').doc(_productoId);
    final productoSnap = await productoRef.get();

    if (productoSnap.exists) {
      final currentStock = productoSnap.data()?['stock'] ?? 0;
      await productoRef.update({'stock': currentStock + _cantidadProducida});
    }

    _msg("Producción registrada y stock actualizado");

    setState(() {
      _productoId = null;
      _stockActual = 0;
      _cantidadProducida = 0;
      _cantidadController.clear();
    });
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.grey),
    );

    InputDecoration deco(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Contenedor elegante
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Registrar Producción",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Dropdown mejorado
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('productos')
                      .orderBy('nombre')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final productos = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: _productoId,
                      decoration: deco("Producto"),
                      hint: const Text("Selecciona un producto"),
                      borderRadius: BorderRadius.circular(12),
                      items: productos.map((doc) {
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['nombre']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _productoId = val;
                          _stockActual = 0;
                        });
                        if (val != null) _cargarStock(val);
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                if (_productoId != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Stock actual: $_stockActual unidades",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Cantidad
                TextField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: deco("Cantidad producida"),
                  onChanged: (val) =>
                      setState(() => _cantidadProducida = int.tryParse(val) ?? 0),
                ),

                const SizedBox(height: 22),

                // Botón mejorado
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _guardarProduccion,
                    icon: const Icon(Icons.check, size: 22),
                    label: const Text(
                      "Registrar Producción",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
