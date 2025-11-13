import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'catalogo_screen.dart';

class SimpleCart {
  SimpleCart._privateConstructor();
  static final SimpleCart instance = SimpleCart._privateConstructor();


  final Map<String, Map<String, dynamic>> _items = {};

  List<Map<String, dynamic>> get items => _items.values.toList();

  void addItem(Map<String, dynamic> producto) {
    final id = producto['id'] ?? producto['nombre'];
    final imagen = convertirEnlaceDriveADirecto(producto['imagen'] ?? '');
    if (_items.containsKey(id)) {
      _items[id]!['cantidad'] = _items[id]!['cantidad'] + 1;
    } else {
      _items[id] = {
        'id': id,
        'nombre': producto['nombre'],
        'precio': producto['precio'],
        'cantidad': 1,
        'stock':producto['stock'],
        'imagen': imagen,
      };
    }
  }
  void increment(String id) {
    if (_items.containsKey(id)) {
      final item = _items[id]!;
      final stock = item['stock'] ?? 99999;
      if (item['cantidad'] < stock) {
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
  void removeItem(String id) {
    _items.remove(id);
  }

  void clear() {
    _items.clear();
  }

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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      return;
    }
    final items = SimpleCart.instance.items;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrito vacío')));
      return;
    }

    setState(() => _procesando = true);
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var item in items) {
        final docRef = FirebaseFirestore.instance.collection('productos').doc(item['id']);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          throw Exception('El producto ${item['nombre']} no existe.');
        }

        final currentStock = docSnap['stock'] ?? 0;
        final newStock = currentStock - item['cantidad'];

        if (newStock < 0) {
          throw Exception('Stock insuficiente para el producto ${item['nombre']}');
        }

        batch.update(docRef, {'stock': newStock});
      }

      final venta = {
        'email': user.email,
        'fecha': FieldValue.serverTimestamp(),
        'productos': items.map((it) => {
              'cantidad': it['cantidad'],
              'nombre': it['nombre'],
              'precio': it['precio'],
            }).toList(),
        'total': SimpleCart.instance.total,
        'uid': user.uid,
      };

      final ventasRef = FirebaseFirestore.instance.collection('ventas');
      batch.set(ventasRef.doc(), venta);


      await batch.commit();

      SimpleCart.instance.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compra realizada con éxito')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al procesar compra: $e')));
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
        children: [
          const Text('Tu Carrito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No hay productos en el carrito.'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final it = items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: it['imagen'] != null && it['imagen'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    it['imagen'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                                  ),
                                )
                              : const Icon(Icons.shopping_bag),
                          title: Text(it['nombre']),
                          subtitle: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    SimpleCart.instance.decrement(it['id']);
                                  });
                                },
                              ),
                              Text('${it['cantidad']}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  final item = SimpleCart.instance._items[it['id']]!;
                                  if (item['cantidad'] >= item['stock']) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Stock máximo alcanzado para ${item['nombre']}'),
                                        duration: Duration(milliseconds: 500),),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    SimpleCart.instance.increment(it['id']);
                                  });
},
                              ),
                              const SizedBox(width: 10),
                              Text('S/ ${(it['precio'] * it['cantidad']).toStringAsFixed(2)}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                SimpleCart.instance.removeItem(it['id']);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Text('Total: S/ ${SimpleCart.instance.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _procesando ? const CircularProgressIndicator() : Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: SimpleCart.instance.items.isEmpty ? null : _finalizarCompra,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Finalizar compra'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    SimpleCart.instance.clear();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: const Text('Vaciar'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
