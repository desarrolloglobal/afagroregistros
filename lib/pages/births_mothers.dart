import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './births_create.dart';

class BirthsMadresPage extends StatefulWidget {
  final int fincaId;
  final String nombreFinca;
  final String userId;

  const BirthsMadresPage({
    Key? key,
    required this.fincaId,
    required this.nombreFinca,
    required this.userId,
  }) : super(key: key);

  @override
  State<BirthsMadresPage> createState() => _BirthsMadresPageState();
}

class _BirthsMadresPageState extends State<BirthsMadresPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allMothers = [];
  List<Map<String, dynamic>> _filteredMothers = [];

  @override
  void initState() {
    super.initState();
    _fetchMothers();
  }

  Future<void> _fetchMothers() async {
    final response = await Supabase.instance.client
        .from('dbanimal')
        .select('sid_animal, snom_animal, scategoria')
        .eq('n_finca', widget.fincaId)
        .or('scategoria.eq.HS,scategoria.eq.HV');

    setState(() {
      _allMothers = (response as List).cast<Map<String, dynamic>>();
      _filteredMothers = _allMothers;
    });
  }

  void _filterMothers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredMothers = _allMothers);
      return;
    }

    setState(() {
      _filteredMothers = _allMothers.where((mother) {
        final searchString =
            '${mother['sid_animal']}-${mother['snom_animal']}-${mother['scategoria']}'
                .toLowerCase();
        return searchString.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4D3E),
        title: const Text(
          'Seleccionar Madre',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMothers,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredMothers.length,
              itemBuilder: (context, index) {
                final mother = _filteredMothers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      '${mother['sid_animal']} - ${mother['snom_animal']} - ${mother['scategoria']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BirthsRegistrationPage(
                              arguments: {
                                'motherId': mother['sid_animal'],
                                'snom_animal': mother['snom_animal'],
                                'scategoria': mother['scategoria'],
                                'fincaId': widget.fincaId,
                                'nombreFinca': widget.nombreFinca,
                                'userId': widget.userId,
                              },
                            ),
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4D3E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
