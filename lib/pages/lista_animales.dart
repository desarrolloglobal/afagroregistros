import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListaAnimalesPage extends StatefulWidget {
  final int fincaId;
  final String nombreFinca;

  const ListaAnimalesPage({
    Key? key,
    required this.fincaId,
    required this.nombreFinca,
  }) : super(key: key);

  @override
  State<ListaAnimalesPage> createState() => _ListaAnimalesPageState();
}

class _ListaAnimalesPageState extends State<ListaAnimalesPage> {
  final supabase = Supabase.instance.client;
  Map<String, List<Map<String, dynamic>>> animalesPorCategoria = {};
  Map<String, String> nombresCategoria = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarAnimales();
  }

  Future<void> cargarAnimales() async {
    try {
      // Primero obtenemos los nombres de las categorías
      final tiposResponse =
          await supabase.from('ts_tipoanimal').select('idtipoa, nomtipovacuno');

      // Creamos un mapa de ID a nombre de categoría
      nombresCategoria = Map.fromEntries((tiposResponse as List).map((tipo) =>
          MapEntry(
              tipo['idtipoa'].toString(), tipo['nomtipovacuno'].toString())));

      // Luego cargamos los animales
      final response = await supabase
          .from('dbanimal')
          .select('sid_animal, snom_animal, scategoria')
          .eq('n_finca', widget.fincaId);

      final List<Map<String, dynamic>> animales =
          List<Map<String, dynamic>>.from(response);

      // Organizar animales por categoría
      final Map<String, List<Map<String, dynamic>>> tempMap = {};
      for (var animal in animales) {
        final categoria = animal['scategoria'] as String;
        if (!tempMap.containsKey(categoria)) {
          tempMap[categoria] = [];
        }
        tempMap[categoria]!.add(animal);
      }

      // Ordenar cada lista por ID
      tempMap.forEach((key, value) {
        value.sort((a, b) =>
            a['sid_animal'].toString().compareTo(b['sid_animal'].toString()));
      });

      setState(() {
        animalesPorCategoria = Map.fromEntries(
            tempMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los animales: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCategoriaSection(
      String categoriaId, List<Map<String, dynamic>> animales) {
    final nombreCategoria =
        nombresCategoria[categoriaId] ?? 'Categoría Desconocida';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Color(0xFF1B4D3E).withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreCategoria,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                    Text(
                      'Código: $categoriaId',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1B4D3E).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF1B4D3E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${animales.length} animales',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: animales.length,
          itemBuilder: (context, index) => _buildAnimalCard(animales[index]),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Color(0xFF1B4D3E),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Navegación a detalles del animal
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '${animal['sid_animal']}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${animal['snom_animal']}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int get totalAnimales =>
      animalesPorCategoria.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        title: Text(
          'ANIMALES DE LA FINCA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finca: ${widget.fincaId} ${widget.nombreFinca}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Total de animales: $totalAnimales',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : animalesPorCategoria.isEmpty
                          ? Center(
                              child: Text(
                                'No hay animales registrados',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView(
                              children:
                                  animalesPorCategoria.entries.map((entry) {
                                return _buildCategoriaSection(
                                  entry.key,
                                  entry.value,
                                );
                              }).toList(),
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
