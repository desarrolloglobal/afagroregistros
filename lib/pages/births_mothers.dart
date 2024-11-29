import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BirthsMadresPage extends StatelessWidget {
  final int fincaId;
  final String nombreFinca;
  final String userId;

  const BirthsMadresPage({
    required this.fincaId,
    required this.nombreFinca,
    required this.userId,
  });

  Future<List<Map<String, dynamic>>> _fetchMothers() async {
    final response = await Supabase.instance.client
        .from('dbanimal')
        .select('sid_animal, snom_animal, scategoria')
        .eq('n_finca', fincaId)
        .or('scategoria.eq.HS,scategoria.eq.HV');

    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        title: Text(
          'Seleccionar Madre',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMothers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final mothers = snapshot.data ?? [];

          return Padding(
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
                      'ID Animal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Nombre',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Categoría',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Escoger Madre',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: mothers
                    .map((mother) => DataRow(
                          cells: [
                            DataCell(Text(mother['sid_animal'])),
                            DataCell(Text(mother['snom_animal'])),
                            DataCell(Text(mother['scategoria'])),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/register_birth',
                                    arguments: {
                                      'motherId': mother['sid_animal'],
                                      'fincaId': fincaId,
                                      'nombreFinca': nombreFinca,
                                      'userId': userId,
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1B4D3E),
                                ),
                                child: Text(
                                  'Escoger',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
