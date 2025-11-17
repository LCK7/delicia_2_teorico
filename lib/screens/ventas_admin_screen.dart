import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VentasAdminScreen extends StatefulWidget {
  @override
  _VentasAdminScreenState createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends State<VentasAdminScreen> {
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  DateTime? fechaInicio;
  DateTime? fechaFin;

  Future<void> _seleccionarFecha(BuildContext context, bool inicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (inicio) {
          fechaInicio = picked;
        } else {
          fechaFin = picked.add(Duration(hours: 23, minutes: 59));
        }
      });
    }
  }

  Stream<QuerySnapshot> _streamVentas() {
    CollectionReference ref = FirebaseFirestore.instance.collection("ventas");

    if (fechaInicio != null && fechaFin != null) {
      return ref
          .where("fecha", isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio!))
          .where("fecha", isLessThanOrEqualTo: Timestamp.fromDate(fechaFin!))
          .orderBy("fecha", descending: true)
          .snapshots();
    }

    return ref.orderBy("fecha", descending: true).snapshots();
  }

  Future<void> _exportarPDF(List<QueryDocumentSnapshot> ventas) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text("Reporte de Ventas", style: pw.TextStyle(fontSize: 22)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ["Fecha", "Producto", "Cant.", "Precio", "Total"],
              data: ventas.expand((v) {
                final data = v.data() as Map<String, dynamic>;
                final fecha = (data["fecha"] as Timestamp?)?.toDate();
                final productos = (data["productos"] as List<dynamic>? ?? [])
                    .map((e) => Map<String, dynamic>.from(e));
                return productos.map((p) {
                  final cant = p["cantidad"] ?? 0;
                  final precio = p["precio"] ?? 0;
                  return [
                    fecha != null ? dateFormat.format(fecha) : "-",
                    p["nombre"] ?? "-",
                    "$cant",
                    "S/ $precio",
                    "S/ ${(cant * precio).toStringAsFixed(2)}"
                  ];
                });
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ventas"),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _streamVentas(),
            builder: (_, snap) {
              if (!snap.hasData) return SizedBox();
              return IconButton(
                icon: Icon(Icons.picture_as_pdf),
                onPressed: () => _exportarPDF(snap.data!.docs),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text("Inicio", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    TextButton(
                      onPressed: () => _seleccionarFecha(context, true),
                      child: Text(
                        fechaInicio != null ? DateFormat('dd/MM/yy').format(fechaInicio!) : "Elegir",
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text("Fin", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    TextButton(
                      onPressed: () => _seleccionarFecha(context, false),
                      child: Text(
                        fechaFin != null ? DateFormat('dd/MM/yy').format(fechaFin!) : "Elegir",
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      fechaInicio = null;
                      fechaFin = null;
                    });
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamVentas(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No hay ventas registradas"));
                }

                final ventas = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: ventas.length,
                  itemBuilder: (_, index) {
                    final data = ventas[index].data() as Map<String, dynamic>;
                    final productos = (data["productos"] as List<dynamic>? ?? [])
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList();
                    final fecha = (data["fecha"] as Timestamp?)?.toDate();
                    final total = productos.fold<double>(
                      0,
                      (sum, p) =>
                          sum + ((p["precio"] ?? 0) * (p["cantidad"] ?? 0)),
                    );

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fecha != null ? dateFormat.format(fecha) : "-",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Column(
                              children: productos.map((p) {
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(p["nombre"] ?? "-", maxLines: 1)),
                                      Text("x${p["cantidad"] ?? 0}"),
                                      Text(
                                        "S/ ${((p["precio"] ?? 0) * (p["cantidad"] ?? 0)).toStringAsFixed(2)}",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Total:", style: TextStyle(fontSize: 16)),
                                Text(
                                  "S/ ${total.toStringAsFixed(2)}",
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                )
                              ],
                            )
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
