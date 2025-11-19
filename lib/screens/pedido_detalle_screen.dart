// CÓDIGO COMPLETO DE pedido_detalle_screen.dart (ACTUALIZADO)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoDetalleScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const PedidoDetalleScreen({
    required this.id,
    required this.data,
    super.key,
  });

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

String convertirEnlaceDriveADirecto(String url) {
  if (url.contains("drive.google.com")) {
    final regex = RegExp(r"[-\w]{25,}");
    final match = regex.firstMatch(url);
    if (match != null) {
      final id = match.group(0);
      return "https://drive.google.com/uc?export=view&id=$id";
    }
  }
  return url;
}


class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  bool _procesando = false;

  List<Map<String, dynamic>> _parseItems(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Future<void> _aprobar() async {
    if (_procesando) return;
    setState(() => _procesando = true);

    try {
      final items = _parseItems(widget.data['items']);

      final batch = FirebaseFirestore.instance.batch();

      // Actualizar stock
      for (var it in items) {
        final ref = FirebaseFirestore.instance.collection('productos').doc(it['id']);
        final snap = await ref.get();

        if (!snap.exists) throw Exception("Producto no existe: ${it['nombre']}");

        final actual = (snap['stock'] ?? 0) as int;
        final nuevo = actual - (it['cantidad'] ?? 0);

        if (nuevo < 0) throw Exception("Stock insuficiente: ${it['nombre']}");

        batch.update(ref, {"stock": nuevo});
      }

      // Crear VENTA correcta para tu pantalla admin
      final ventaRef = FirebaseFirestore.instance.collection('ventas').doc();
      batch.set(ventaRef, {
        "usuarioId": widget.data['usuarioId'],
        "fecha": FieldValue.serverTimestamp(),
        "productos": items,       // <--- NOMBRE CORRECTO
        "total": widget.data['total'],
      });

      // Actualizar pedido
      final pedidoRef = FirebaseFirestore.instance.collection('pedidos').doc(widget.id);
      batch.update(pedidoRef, {
        "estado": "aprobado",
        "fecha_aprobado": FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ERROR: $e")),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _rechazar() async {
    if (_procesando) return;
    setState(() => _procesando = true);

    try {
      final ref = FirebaseFirestore.instance.collection('pedidos').doc(widget.id);
      await ref.update({
        "estado": "rechazado",
        "fecha_rechazo": FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ERROR: $e")),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final items = _parseItems(data['items']);
    final estado = data['estado'] ?? 'sin estado';
    final direccion = data['direccion'] ?? '';
    final total = data['total'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Pedido ${widget.id}"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info("Estado", estado),
            _info("Dirección", direccion),

            const SizedBox(height: 12),
            const Text(
              "Productos del pedido",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        "Este pedido no tiene productos (datos corruptos).",
                        style: TextStyle(fontSize: 15, color: Colors.red),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      padding: const EdgeInsets.only(top: 8),
                      itemBuilder: (_, i) {
                        final it = items[i];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: it['imagen'] != null
                                  ? Image.network(
                                      convertirEnlaceDriveADirecto(it['imagen']),
                                      width: 55,
                                      height: 55,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_not_supported),
                                    )
                                  : const Icon(Icons.image),
                            ),
                            title: Text(it['nombre'] ?? ''),
                            subtitle: Text("Cantidad: ${it['cantidad']}"),
                            trailing: Text(
                              "S/ ${(it['subtotal'] ?? 0).toString()}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            Text(
              "Total: S/ $total",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 14),

            _procesando
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: estado == "pendiente" ? _aprobar : null,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("Aprobar"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: estado == "pendiente" ? _rechazar : null,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("Rechazar"),
                        ),
                      ),
                    ],
                  )
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
