import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'saldos_categorias.dart';

class MovimientosPage extends StatefulWidget {
  final int fincaId;
  final String nombreFinca;
  final String userId;

  MovimientosPage({
    required this.fincaId,
    required this.nombreFinca,
    required this.userId,
  });

  @override
  _MovimientosPageState createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage> {
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  List<Map<String, dynamic>> movimientos = [];
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Set default dates
    _fechaInicioController.text = '01/01/2024';
    _fechaFinController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    try {
      DateTime fechaInicio =
          DateFormat('dd/MM/yyyy').parse(_fechaInicioController.text);
      DateTime fechaFin =
          DateFormat('dd/MM/yyyy').parse(_fechaFinController.text);

      final response = await supabase
          .from('dbmovimientos')
          .select('ffecha, stipomov, catentra, catsale')
          .eq('nfinca', widget.fincaId)
          .gte('ffecha', fechaInicio.toIso8601String())
          .lte('ffecha', fechaFin.toIso8601String());

      setState(() {
        movimientos = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los movimientos: $e')),
      );
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        iconTheme: IconThemeData(
            color: Colors.white), // This makes the back arrow white
        title: Text(
          'Movimientos',
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
                Text(
                  'ID finca - ${widget.fincaId} - ${widget.nombreFinca} - ${widget.userId}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fechaInicioController,
                        decoration: InputDecoration(
                          labelText: 'Fecha de inicio',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        readOnly: true,
                        onTap: () =>
                            _selectDate(context, _fechaInicioController),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _fechaFinController,
                        decoration: InputDecoration(
                          labelText: 'Fecha final',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, _fechaFinController),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cargarMovimientos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1B4D3E),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Ver Movimientos',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Color(0xFFE8F5E9),
                        ),
                        columns: [
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Tipo\nMovimiento')),
                          DataColumn(label: Text('Categoría\nEntra')),
                          DataColumn(label: Text('Categoría\nSale')),
                        ],
                        rows: movimientos.map((movimiento) {
                          return DataRow(cells: [
                            DataCell(Text(DateFormat('dd/MM/yyyy')
                                .format(DateTime.parse(movimiento['ffecha'])))),
                            DataCell(Text(movimiento['stipomov'] ?? '')),
                            DataCell(Text(movimiento['catentra'] ?? '')),
                            DataCell(Text(movimiento['catsale'] ?? '')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          DateTime fechaInicio =
              DateFormat('dd/MM/yyyy').parse(_fechaInicioController.text);
          DateTime fechaFin =
              DateFormat('dd/MM/yyyy').parse(_fechaFinController.text);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SaldosCategoriasPage(
                fincaId: widget.fincaId,
                fechaInicio: fechaInicio,
                fechaFin: fechaFin,
              ),
            ),
          );
        },
        backgroundColor: Color(0xFF1B4D3E),
        label: Row(
          children: [
            Icon(Icons.visibility, color: Colors.white), // Make icon white
            SizedBox(width: 8),
            Text(
              'Ver Saldos',
              style: TextStyle(color: Colors.white), // Make text white
            ),
          ],
        ),
      ),
    );
  }
}
