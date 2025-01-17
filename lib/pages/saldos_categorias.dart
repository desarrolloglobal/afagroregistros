import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SaldosCategoriasPage extends StatefulWidget {
  final int fincaId;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  SaldosCategoriasPage({
    required this.fincaId,
    required this.fechaInicio,
    required this.fechaFin,
  });

  @override
  _SaldosCategoriasPageState createState() => _SaldosCategoriasPageState();
}

class _SaldosCategoriasPageState extends State<SaldosCategoriasPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> saldos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarSaldos();
  }

  Future<void> _cargarSaldos() async {
    try {
      // Primero, obtenemos todos los movimientos filtrados por fecha y finca
      final movimientos = await supabase
          .from('dbmovimientos')
          .select('catentra, catsale')
          .eq('nfinca', widget.fincaId)
          .gte('ffecha', widget.fechaInicio.toIso8601String())
          .lte('ffecha', widget.fechaFin.toIso8601String());

      // Obtenemos todas las categorías y sus nombres de ts_tipoanimal
      final categorias =
          await supabase.from('ts_tipoanimal').select('idtipoa, nomtipovacuno');

      // Creamos un mapa para almacenar los nombres de las categorías
      Map<String, String> categoriasMap = {};
      for (var cat in categorias) {
        categoriasMap[cat['idtipoa']] = cat['nomtipovacuno'];
      }

      // Calculamos los saldos
      Map<String, int> saldosMap = {};

      // Procesamos las entradas
      for (var mov in movimientos) {
        if (mov['catentra'] != null && mov['catentra'].toString().isNotEmpty) {
          saldosMap[mov['catentra']] = (saldosMap[mov['catentra']] ?? 0) + 1;
        }
        if (mov['catsale'] != null && mov['catsale'].toString().isNotEmpty) {
          saldosMap[mov['catsale']] = (saldosMap[mov['catsale']] ?? 0) - 1;
        }
      }

      // Convertimos el mapa de saldos a una lista para mostrar
      List<Map<String, dynamic>> saldosList = [];
      saldosMap.forEach((categoria, saldo) {
        saldosList.add({
          'categoria': categoria,
          'nombreCategoria': categoriasMap[categoria] ?? 'Desconocida',
          'saldo': saldo,
        });
      });

      // Ordenamos por categoría
      saldosList.sort((a, b) => a['categoria'].compareTo(b['categoria']));

      setState(() {
        saldos = saldosList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los saldos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        title: Text(
          'Saldos por Categoría',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Período:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Del: ${DateFormat('dd/MM/yyyy').format(widget.fechaInicio)}',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Al: ${DateFormat('dd/MM/yyyy').format(widget.fechaFin)}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : saldos.isEmpty
                          ? Center(
                              child: Text('No hay datos para mostrar'),
                            )
                          : SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  Color(0xFFE8F5E9),
                                ),
                                columns: [
                                  DataColumn(label: Text('Código')),
                                  DataColumn(label: Text('Categoría')),
                                  DataColumn(
                                    label: Text('Saldo'),
                                    numeric: true,
                                  ),
                                ],
                                rows: saldos.map((saldo) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(saldo['categoria'])),
                                      DataCell(Text(saldo['nombreCategoria'])),
                                      DataCell(
                                        Text(
                                          saldo['saldo'].toString(),
                                          style: TextStyle(
                                            color: saldo['saldo'] < 0
                                                ? Colors.red
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
