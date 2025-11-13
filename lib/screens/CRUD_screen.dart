import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CRUDScreen extends StatefulWidget {
  const CRUDScreen({super.key});
  @override
  State<CRUDScreen> createState() => _CRUDScreenState();
}

class _CRUDScreenState extends State<CRUDScreen> {
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _descripcion = TextEditingController();
  final TextEditingController _precio = TextEditingController();
  final TextEditingController _imagen = TextEditingController();
  final TextEditingController _stock = TextEditingController();

  String? _idSeleccionado;

  Future<void> createProducto() async {
    if (!_validarCampos()) return;
    final datos = {
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'precio': double.tryParse(_precio.text) ?? 0.0,
      'imagen': _imagen.text.trim(),
      'stock': int.tryParse(_stock.text) ?? 0,
    };
    await FirebaseFirestore.instance.collection('productos').add(datos);
    limpiarFormulario();
  }

  Future<void> updateProducto(String id) async {
    if (!_validarCampos()) return;
    final datos = {
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'precio': double.tryParse(_precio.text) ?? 0.0,
      'imagen': _imagen.text.trim(),
      'stock': int.tryParse(_stock.text) ?? 0,
    };
    await FirebaseFirestore.instance.collection('productos').doc(id).update(datos);
    limpiarFormulario();
  }

  Future<void> deleteProducto(String id) async {
    await FirebaseFirestore.instance.collection('productos').doc(id).delete();
    limpiarFormulario();
  }

  void limpiarFormulario() {
    setState(() {
      _nombre.clear();
      _descripcion.clear();
      _precio.clear();
      _imagen.clear();
      _stock.clear();
      _idSeleccionado = null;
    });
  }

  bool _validarCampos() {
    if (_nombre.text.isEmpty ||
        _descripcion.text.isEmpty ||
        _precio.text.isEmpty ||
        _imagen.text.isEmpty) {
      _msg("Por favor completa todos los campos");
      return false;
    }

    if (_stock.text.isEmpty || int.tryParse(_stock.text) == null) {
      _msg("El stock debe ser un número válido");
      return false;
    }

    final precio = double.tryParse(_precio.text);
    if (precio == null || precio <= 0) {
      _msg("Ingresa un precio válido mayor que 0");
      return false;
    }

    if (!_imagen.text.contains('drive.google.com')) {
      _msg("Ingresa un enlace válido de Google Drive");
      return false;
    }

    return true;
  }

  void _msg(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.grey),
    );

    InputDecoration deco(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        filled: true,
        fillColor: Colors.white,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.blue, width: 1.4),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gestión de Productos",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),

          // FORM
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              children: [
                TextField(controller: _nombre, decoration: deco("Nombre del producto", Icons.category)),
                const SizedBox(height: 12),
                TextField(controller: _descripcion, decoration: deco("Descripción", Icons.description)),
                const SizedBox(height: 12),
                TextField(
                  controller: _precio,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: deco("Precio (S/.)", Icons.monetization_on),
                ),
                const SizedBox(height: 12),
                TextField(controller: _imagen, decoration: deco("Enlace de imagen (Drive)", Icons.image)),
                const SizedBox(height: 12),
                TextField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: deco("Stock", Icons.storage),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_idSeleccionado == null) {
                        createProducto();
                      } else {
                        updateProducto(_idSeleccionado!);
                      }
                    },
                    icon: Icon(_idSeleccionado == null ? Icons.add : Icons.save),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _idSeleccionado == null ? Colors.green : Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    label: Text(
                      _idSeleccionado == null ? 'Agregar Producto' : 'Guardar Cambios',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "Lista de Productos",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('productos').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No hay productos registrados."),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final p = docs[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.shopping_bag, size: 30, color: Colors.brown),
                      title: Text(
                        p['nombre'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['descripcion']),
                          Text("Precio: S/. ${p['precio']}"),
                          Text("Stock: ${p['stock']}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                _idSeleccionado = p.id;
                                _nombre.text = p['nombre'];
                                _descripcion.text = p['descripcion'];
                                _precio.text = p['precio'].toString();
                                _imagen.text = p['imagen'];
                                _stock.text = p['stock'].toString();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteProducto(p.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }
}
