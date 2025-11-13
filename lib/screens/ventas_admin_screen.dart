import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VentasAdminScreen extends StatefulWidget {
  const VentasAdminScreen({super.key});

  @override
  State<VentasAdminScreen> createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends State<VentasAdminScreen> {
  DateTime? fechaInicio;
  DateTime? fechaFin;

  final DateFormat dateFormat = DateFormat("dd/MM/yyyy");

  Future<void> _exportarPDF(List<QueryDocumentSnapshot> ventas) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text("Reporte de Ventas",
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          pw.Text(
            "Rango: ${fechaInicio != null ? dateFormat.format(fechaInicio!) : "-"}  "
            "→  ${fechaFin != null ? dateFormat.format(fechaFin!) : "-"}",
          ),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: ["Fecha", "Producto", "Cantidad", "Precio", "Total"],
            data: ventas.expand((v) {
              final data = v.data() as Map<String, dynamic>;
              final fecha = (data["fecha"] as Timestamp?)?.toDate();
              final productos = List<Map<String, dynamic>>.from(data["productos"]);

              return productos.map((p) {
                return [
                  fecha != null ? dateFormat.format(fecha) : "-",
                  p["nombre"],
                  "${p["cantidad"]}",
                  "S/ ${p["precio"]}",
                  "S/ ${(p["cantidad"] * p["precio"]).toStringAsFixed(2)}",
                ];
              });
            }).toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
          )
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (format) async => pdf.save());
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          fechaInicio = picked;
        } else {
          fechaFin = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Panel de Ventas"),
        backgroundColor: Colors.green.shade700,
        elevation: 3,
      ),
      body: Column(
        children: [
          // 🔵 FILTRO DE FECHAS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    blurRadius: 4,
                    color: Colors.black12,
                    offset: Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fecha inicio
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Desde:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(
                          fechaInicio != null
                              ? dateFormat.format(fechaInicio!)
                              : "-",
                          style: const TextStyle(fontSize: 16),
                        ),
                        TextButton.icon(
                          onPressed: () => _selectDate(context, true),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text("Elegir fecha"),
                        ),
                      ],
                    ),

                    // Fecha fin
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Hasta:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(
                          fechaFin != null
                              ? dateFormat.format(fechaFin!)
                              : "-",
                          style: const TextStyle(fontSize: 16),
                        ),
                        TextButton.icon(
                          onPressed: () => _selectDate(context, false),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text("Elegir fecha"),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.filter_alt),
                  label: const Text("Aplicar Filtro"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700),
                )
              ],
            ),
          ),

          // 🔵 CONTENIDO
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ventas')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final ventas = snapshot.data!.docs;

                // FILTRAR POR FECHA
                final ventasFiltradas = ventas.where((v) {
                  final data = v.data() as Map<String, dynamic>;
                  final fecha = (data["fecha"] as Timestamp?)?.toDate();

                  if (fecha == null) return false;

                  if (fechaInicio != null && fecha.isBefore(fechaInicio!)) {
                    return false;
                  }
                  if (fechaFin != null && fecha.isAfter(fechaFin!)) {
                    return false;
                  }

                  return true;
                }).toList();

                return Column(
                  children: [
                    // 📄 BOTÓN PDF
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton.icon(
                        onPressed: ventasFiltradas.isEmpty
                            ? null
                            : () => _exportarPDF(ventasFiltradas),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Exportar PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                        ),
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: ventasFiltradas.length,
                        itemBuilder: (context, index) {
                          final data = ventasFiltradas[index].data()
                              as Map<String, dynamic>;
                          final fecha =
                              (data["fecha"] as Timestamp?)?.toDate();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fecha != null
                                        ? dateFormat.format(fecha)
                                        : "Sin fecha",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green.shade700),
                                  ),

                                  const SizedBox(height: 6),

                                  ...List<Map<String, dynamic>>.from(
                                          data['productos'])
                                      .map((p) => Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 2),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  p["nombre"],
                                                  style: const TextStyle(
                                                      fontSize: 15),
                                                ),
                                                Text(
                                                  "x${p["cantidad"]}",
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey[700]),
                                                ),
                                                Text(
                                                  "S/ ${(p["precio"] * p["cantidad"]).toStringAsFixed(2)}",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                )
                                              ],
                                            ),
                                          ))
                                      .toList(),

                                  const Divider(),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Total:",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.bold)),
                                      Text(
                                        "S/ ${data["total"].toStringAsFixed(2)}",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
