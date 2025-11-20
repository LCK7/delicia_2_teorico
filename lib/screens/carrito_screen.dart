import 'package:flutter/material.dart';
import 'checkout_screen.dart';

class SimpleCart {
  SimpleCart._private();
  static final SimpleCart instance = SimpleCart._private();

  final Map<String, Map<String, dynamic>> raw = {};

  List<Map<String, dynamic>> get items => raw.values.toList();

  double get total {
    double t = 0;
    for (var it in raw.values) {
      t += (it['precio'] as num) * (it['cantidad'] as int);
    }
    return t;
  }

  void addItem(Map<String, dynamic> item) {
    final id = item['id'];
    if (raw.containsKey(id)) {
      raw[id]!['cantidad']++;
    } else {
      raw[id] = {...item, 'cantidad': 1};
    }
  }

  void increment(String id) {
    raw[id]!['cantidad']++;
  }

  void decrement(String id) {
    if (raw[id]!['cantidad'] > 1) {
      raw[id]!['cantidad']--;
    } else {
      raw.remove(id);
    }
  }

  void removeItem(String id) {
    raw.remove(id);
  }

  void clear() {
    raw.clear();
  }
}

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});
  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {

  // 👉 FUNCIÓN PARA CONVERTIR LINK DE DRIVE A DIRECTO
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

  @override
  Widget build(BuildContext context) {
    final items = SimpleCart.instance.items;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu Carrito',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Revisa tus productos antes de confirmar',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 75, color: Colors.grey.shade500),
                        const SizedBox(height: 14),
                        Text(
                          'No hay productos en el carrito',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final it = items[i];

                      // 👉 Convertir enlace de Drive aquí
                      final imgUrl =
                          convertirEnlaceDriveADirecto(it['imagen']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x0D000000),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imgUrl,
                                width: 75,
                                height: 75,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.bakery_dining, size: 40),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it['nombre'],
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      _contadorBtn(
                                        icon: Icons.remove,
                                        onTap: () {
                                          setState(() =>
                                              SimpleCart.instance.decrement(it['id']));
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${it['cantidad']}',
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 10),
                                      _contadorBtn(
                                        icon: Icons.add,
                                        onTap: () {
                                          final item =
                                              SimpleCart.instance.raw[it['id']]!;
                                          if (item['cantidad'] >= item['stock']) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Stock máximo alcanzado para ${item['nombre']}'),
                                                duration: Duration(milliseconds: 700),
                                              ),
                                            );
                                            return;
                                          }
                                          setState(() =>
                                              SimpleCart.instance.increment(it['id']));
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'S/ ${(it['precio'] * it['cantidad']).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() =>
                                        SimpleCart.instance.removeItem(it['id']));
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

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(
                'S/ ${SimpleCart.instance.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _botonesFooter(items),
        ],
      ),
    );
  }

  Widget _contadorBtn({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }

  Widget _botonesFooter(List items) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: items.isEmpty
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    );
                    setState(() {});
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              "Ir al Checkout",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => setState(() => SimpleCart.instance.clear()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade500,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Vaciar'),
        ),
      ],
    );
  }
}
