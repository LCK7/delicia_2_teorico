import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class SimpleCart {

  String convertirEnlaceDriveADirecto(String url) {
    if (url.isEmpty) return url;

    // Caso 1: URL formato https://drive.google.com/file/d/ID/view?usp=sharing
    if (url.contains("drive.google.com")) {
      final regExp = RegExp(r'd/([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(url);
      if (match != null) {
        final fileId = match.group(1);
        return "https://drive.google.com/uc?export=view&id=$fileId";
      }
    }

    // Caso 2: URL con ?id=XXXXXXXX
    if (url.contains("?id=")) {
      final id = url.split("?id=").last;
      return "https://drive.google.com/uc?export=view&id=$id";
    }

    // Si no es de Drive, devolver normal
    return url;
  }

  SimpleCart._privateConstructor();
  static final SimpleCart instance = SimpleCart._privateConstructor();

  final Map<String, Map<String, dynamic>> _items = {};

  List<Map<String, dynamic>> get items => _items.values.toList();

  void addItem(Map<String, dynamic> producto) {
    final id = producto['id'] ?? producto['nombre'];
    final imagen = convertirEnlaceDriveADirecto(producto['imagen'] ?? '');
    if (_items.containsKey(id)) {
      _items[id]!['cantidad']++;
    } else {
      _items[id] = {
        'id': id,
        'nombre': producto['nombre'],
        'precio': producto['precio'],
        'cantidad': 1,
        'stock': producto['stock'],
        'imagen': imagen,
      };
    }
  }

  void increment(String id) {
    if (_items.containsKey(id)) {
      final item = _items[id]!;
      if (item['cantidad'] < item['stock']) {
        item['cantidad']++;
      }
    }
  }

  void decrement(String id) {
    if (_items.containsKey(id)) {
      if (_items[id]!['cantidad'] > 1) {
        _items[id]!['cantidad']--;
      } else {
        _items.remove(id);
      }
    }
  }

  void removeItem(String id) => _items.remove(id);

  void clear() => _items.clear();

  double get total {
    double t = 0;
    for (var it in _items.values) {
      t += (it['precio'] as num) * (it['cantidad'] as int);
    }
    return t;
  }
}

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});
  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  bool _procesando = false;

  Future<void> _finalizarCompra() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      return;
    }

    final items = SimpleCart.instance.items;

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carrito vacío')),
      );
      return;
    }

    setState(() => _procesando = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var item in items) {
        final docRef =
            FirebaseFirestore.instance.collection('productos').doc(item['id']);
        final snap = await docRef.get();

        if (!snap.exists) {
          throw Exception(
              'El producto ${item['nombre']} ya no está disponible.');
        }

        final stockActual = snap['stock'] ?? 0;
        final nuevoStock = stockActual - item['cantidad'];

        if (nuevoStock < 0) {
          throw Exception('Stock insuficiente para ${item['nombre']}');
        }

        batch.update(docRef, {'stock': nuevoStock});
      }

      final venta = {
        'email': user.email,
        'fecha': FieldValue.serverTimestamp(),
        'productos': items
            .map((it) => {
                  'cantidad': it['cantidad'],
                  'nombre': it['nombre'],
                  'precio': it['precio'],
                })
            .toList(),
        'total': SimpleCart.instance.total,
        'uid': user.uid,
      };

      batch.set(
          FirebaseFirestore.instance.collection('ventas').doc(), venta);

      await batch.commit();

      SimpleCart.instance.clear();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra realizada con éxito')));

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = SimpleCart.instance.items;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITULO PRINCIPAL
          const Text(
            'Tu Carrito',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Revisa tus productos antes de confirmar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // LISTA DE PRODUCTOS
          Expanded(
            child: items.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_shopping_cart,
                          size: 60, color: Colors.grey.shade500),
                      const SizedBox(height: 10),
                      Text(
                        'No hay productos en el carrito',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final it = items[i];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // IMAGEN
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                it['imagen'],
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.bakery_dining, size: 40),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // NOMBRE Y CONTROLES
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it['nombre'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // CONTROLES DE CANTIDAD
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            SimpleCart.instance
                                                .decrement(it['id']);
                                          });
                                        },
                                      ),
                                      Text(
                                        '${it['cantidad']}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          final item = SimpleCart
                                              .instance._items[it['id']]!;
                                          if (item['cantidad'] >=
                                              item['stock']) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Stock máximo alcanzado para ${item['nombre']}'),
                                              duration:
                                                  const Duration(milliseconds: 600),
                                            ));
                                            return;
                                          }
                                          setState(() {
                                            SimpleCart.instance
                                                .increment(it['id']);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // PRECIO + ELIMINAR
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'S/ ${(it['precio'] * it['cantidad']).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      SimpleCart.instance.removeItem(it['id']);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // TOTAL + BOTONES
          const SizedBox(height: 10),
          Text(
            'Total: S/ ${SimpleCart.instance.total.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 14),

          _procesando
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: items.isEmpty ? null : _finalizarCompra,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Finalizar compra',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => SimpleCart.instance.clear());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Vaciar'),
                    ),
                  ],
                )
        ],
      ),
    );
  }
}
