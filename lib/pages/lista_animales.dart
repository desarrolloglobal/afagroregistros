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
  List<Map<String, dynamic>> animales = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarAnimales();
  }

  Future<void> cargarAnimales() async {
    try {
      final response = await supabase
          .from('dbanimal')
          .select('sid_animal, snom_animal, scategoria')
          .eq('n_finca', widget.fincaId);

      setState(() {
        animales = List<Map<String, dynamic>>.from(response);
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

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Color(0xFF1B4D3E),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Aquí irá la navegación a la página de detalles del animal
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${animal['snom_animal']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${animal['scategoria']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
                    child: Text(
                      'Finca: ${widget.fincaId} ${widget.nombreFinca}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Encabezados de columnas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'ID',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'NOMBRE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'CATEGORÍA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : animales.isEmpty
                          ? Center(
                              child: Text(
                                'No hay animales registrados',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: animales.length,
                              itemBuilder: (context, index) {
                                return _buildAnimalCard(animales[index]);
                              },
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
