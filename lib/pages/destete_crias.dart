import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './destete_create.dart';

class DesteteCriasPage extends StatefulWidget {
  final int fincaId;
  final String nombreFinca;
  final String userId;

  const DesteteCriasPage({
    Key? key,
    required this.fincaId,
    required this.nombreFinca,
    required this.userId,
  }) : super(key: key);

  @override
  State<DesteteCriasPage> createState() => _DesteteCriasPageState();
}

class _DesteteCriasPageState extends State<DesteteCriasPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allCrias = [];
  List<Map<String, dynamic>> _filteredCrias = [];

  @override
  void initState() {
    super.initState();
    _fetchCrias();
  }

  Future<void> _fetchCrias() async {
    final response = await Supabase.instance.client
        .from('dbanimal')
        .select('sid_animal, snom_animal, scategoria, sid_madre')
        .eq('n_finca', widget.fincaId)
        .or('scategoria.eq.CH,scategoria.eq.CM');

    setState(() {
      _allCrias = (response as List).cast<Map<String, dynamic>>();
      _filteredCrias = _allCrias;
    });
  }

  void _filterCrias(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCrias = _allCrias);
      return;
    }

    setState(() {
      _filteredCrias = _allCrias.where((Cria) {
        final searchString =
            '${Cria['sid_animal']}-${Cria['snom_animal']}-${Cria['scategoria']}-${Cria['sid_madre']}'
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
          'Seleccionar Cría',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCrias,
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
              itemCount: _filteredCrias.length,
              itemBuilder: (context, index) {
                final Cria = _filteredCrias[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      '${Cria['sid_animal']} - ${Cria['snom_animal']} - ${Cria['scategoria']} - ${Cria['sid_madre']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DesteteCreatePage(
                              arguments: {
                                'CriaId': Cria['sid_animal'],
                                'snom_animal': Cria['snom_animal'],
                                'scategoria': Cria['scategoria'],
                                'madreId': Cria['sid_madre'],
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
