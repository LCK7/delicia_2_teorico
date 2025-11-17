import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pedido_detalle_screen.dart';

class GestionPedidosScreen extends StatelessWidget {
  const GestionPedidosScreen({super.key});

  Color estadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text("Gestión de Pedidos"),
        elevation: 2,
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay pedidos aún",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final pedidos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final doc = pedidos[index];
              final data = doc.data() as Map<String, dynamic>;
              final estado = data['estado'];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PedidoDetalleScreen(
                          id: doc.id,
                          data: data,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: estadoColor(estado).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            estado.toUpperCase(),
                            style: TextStyle(
                              color: estadoColor(estado),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pedido ${doc.id}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Total: S/ ${data['total']}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data['fecha'].toDate().toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
