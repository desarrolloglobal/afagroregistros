import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'offline_state_manager.dart';
import 'births_mothers.dart';

class BirthsPage extends StatelessWidget {
  final int fincaId;
  final String nombreFinca;

  BirthsPage({
    required this.fincaId,
    required this.nombreFinca,
  });

  String get userId =>
      OfflineStateManager().currentUserId ??
      Supabase.instance.client.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> _fetchBirths() async {
    final response = await Supabase.instance.client
        .from('dbmovimientos')
        .select('iddocum, ffecha, stipomov, nidanimal1')
        .eq('nfinca', fincaId)
        .or('stipomov.eq.NA,stipomov.eq.PTO');

    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        title: Text(
          'Nacimientos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBirths(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final births = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    Color(0xFF1B4D3E).withOpacity(0.1),
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        'Documento',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Fecha',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tipo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'ID Animal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: births
                      .map((birth) => DataRow(
                            cells: [
                              DataCell(Text(birth['iddocum'].toString())),
                              DataCell(Text(DateTime.parse(birth['ffecha'])
                                  .toString()
                                  .split(' ')[0])),
                              DataCell(Text(birth['stipomov'])),
                              DataCell(Text(birth['nidanimal1'].toString())),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BirthsMadresPage(
                fincaId: fincaId,
                nombreFinca: nombreFinca,
                userId: userId,
              ),
            ),
          );
        },
        backgroundColor: Color(0xFF1B4D3E),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Agregar Nacimientos',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
