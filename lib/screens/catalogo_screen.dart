import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'carrito_screen.dart';

String convertirEnlaceDriveADirecto(String enlaceDrive) {
  final regExp1 = RegExp(r'/d/([a-zA-Z0-9_-]+)');
  final match1 = regExp1.firstMatch(enlaceDrive);

  final regExp2 = RegExp(r'id=([a-zA-Z0-9_-]+)');
  final match2 = regExp2.firstMatch(enlaceDrive);

  String? id;
  if (match1 != null) {
    id = match1.group(1);
  } else if (match2 != null) {
    id = match2.group(1);
  }

  if (id != null) {
    return 'https://drive.google.com/uc?export=view&id=$id';
  }
  return enlaceDrive;
}

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  _CatalogoScreenState createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  // Controlador de búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filtros de categoría
  String? categoriaSeleccionada;
  final List<String> categorias = [
    'Pan',
    'Torta',
    'Bebida',
    'Postre',
    'Bocadito',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _agregarAlCarrito(BuildContext context, Map<String, dynamic> producto) {
    if (producto['stock'] == null || producto['stock'] <= 0) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No hay stock disponible para este producto'),
            duration: Duration(seconds: 1),
          ),
        );
      return;
    }

    SimpleCart.instance.addItem(producto);

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Producto agregado al carrito'),
          duration: Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categorias.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                // Chip de "Todos"
                if (index == 0) {
                  return ChoiceChip(
                    label: const Text('Todos'),
                    selected: categoriaSeleccionada == null,
                    onSelected: (_) {
                      setState(() => categoriaSeleccionada = null);
                    },
                  );
                }

                final categoria = categorias[index - 1];

                return ChoiceChip(
                  label: Text(categoria),
                  selected: categoriaSeleccionada == categoria,
                  onSelected: (_) {
                    setState(() => categoriaSeleccionada = categoria);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('productos')
                  .orderBy('nombre')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No hay productos disponibles.'),
                  );
                }

                // Filtro general
                final filteredDocs = docs.where((p) {
                  final producto = p.data() as Map<String, dynamic>;

                  final nombre = producto['nombre'].toString().toLowerCase();
                  final descripcion =
                      (producto['descripcion'] ?? '').toLowerCase();

                  final coincideBusqueda = nombre.contains(_searchQuery) ||
                      descripcion.contains(_searchQuery);

                  final coincideCategoria = categoriaSeleccionada == null
                      ? true
                      : descripcion ==
                          categoriaSeleccionada!.toLowerCase();

                  return coincideBusqueda && coincideCategoria;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No se encontraron productos.'),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredDocs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final p = filteredDocs[index];
                    final producto = {
                      'id': p.id,
                      'nombre': p['nombre'],
                      'descripcion': p['descripcion'],
                      'precio': (p['precio'] is int)
                          ? (p['precio'] as int).toDouble()
                          : (p['precio'] as num).toDouble(),
                      'imagen': p['imagen'] ?? '',
                      'stock': p['stock'] ?? 0,
                    };

                    final urlImagen =
                        convertirEnlaceDriveADirecto(producto['imagen']);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                urlImagen,
                                height: 70,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 40),
                              ),
                            ),

                            const SizedBox(height: 9),

                            Text(
                              producto['nombre'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              producto['descripcion'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'S/ ${producto['precio'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Stock: ${producto['stock']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: producto['stock'] == 0
                                    ? Colors.red
                                    : (producto['stock'] < 10
                                        ? Colors.orange
                                        : Colors.green),
                              ),
                            ),

                            const Spacer(),

                            ElevatedButton(
                              onPressed: () =>
                                  _agregarAlCarrito(context, producto),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size.fromHeight(36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Agregar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
