import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DesteteCreatePage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const DesteteCreatePage({Key? key, required this.arguments})
      : super(key: key);

  @override
  State<DesteteCreatePage> createState() => _DesteteCreatePageState();
}

class _DesteteCreatePageState extends State<DesteteCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // Data de la cría
  late String _criaId;
  late String _nomCria;
  late String _categoriaCria;
  DateTime? _fechaNace;
  double? _pesoNace;

  // Data de la madre
  late String _madreId;
  String _nomMadre = '';
  String _categoriaMadre = '';

  // Datos del destete
  final _fechaDesteteController = TextEditingController();
  final _pesoMadreController = TextEditingController();
  final _pesoCriaController = TextEditingController();
  final _diasDesteteController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _criaId = widget.arguments['CriaId'];
    _nomCria = widget.arguments['snom_animal'];
    _categoriaCria = widget.arguments['scategoria'];
    _madreId = widget.arguments['madreId'];
    _fetchAnimalData();
  }

  Future<void> _fetchAnimalData() async {
    try {
      setState(() => _isLoading = true);

      // Fetch cría details
      final criaResponse = await Supabase.instance.client
          .from('dbanimal')
          .select('fnacimiento, n_pesonace')
          .eq('sid_animal', _criaId)
          .eq('n_finca', widget.arguments['fincaId'])
          .limit(1)
          .maybeSingle();

      if (criaResponse != null) {
        setState(() {
          _fechaNace = criaResponse['fnacimiento'] != null
              ? DateTime.parse(criaResponse['fnacimiento'])
              : null;
          _pesoNace = criaResponse['n_pesonace']?.toDouble();
        });
      }

      // Fetch madre details
      final madreResponse = await Supabase.instance.client
          .from('dbanimal')
          .select('snom_animal, scategoria')
          .eq('sid_animal', _madreId)
          .eq('n_finca', widget.arguments['fincaId'])
          .limit(1)
          .maybeSingle();

      if (madreResponse != null) {
        setState(() {
          _nomMadre = madreResponse['snom_animal'] ?? '';
          _categoriaMadre = madreResponse['scategoria'] ?? '';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching animal data: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los datos del animal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveDestete() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);

        // Calculate temporary variables
        final fechaNacetmp =
            _fechaNace ?? DateTime.now().subtract(const Duration(days: 150));
        final pesoDefault = _categoriaCria == 'CH' ? 33.0 : 38.0;
        final pesoNacetmp = _pesoNace ?? pesoDefault;
        final categoriatmp = _categoriaCria == 'CH' ? 'HL' : 'ML';

        final fechaDestete = DateTime.parse(_fechaDesteteController.text);
        final pesoCriaDestete = double.parse(_pesoCriaController.text);
        final pesoMadre = double.parse(_pesoMadreController.text);

        // Calculate days between dates
        final diasDestete = fechaDestete.difference(fechaNacetmp).inDays;

        // Calculate weight gain
        final gananciaPesoTmp =
            ((pesoCriaDestete - pesoNacetmp) / diasDestete) * 1000;

        // Insert into dbdocumentos and get the document ID
        final docResponse = await Supabase.instance.client
            .from('dbdocumentos')
            .insert({
              'sdoc': '3',
              'ffechadoc': DateTime.now().toIso8601String(),
              'tipomov': 'DT',
              'useriddoc': widget.arguments['userId'],
            })
            .select('iddoc')
            .single();

        final idDoc = docResponse['iddoc'];

        // Insert cria movement based on mother's category
        if (_categoriaMadre != 'HP') {
          // Insert huerfana movement
          await Supabase.instance.client.from('dbmovimientos').insert({
            'iddocum': idDoc,
            'nfinca': widget.arguments['fincaId'],
            'ffecha': DateTime.now().toIso8601String(),
            'stipomov': 'DTH',
            'nidanimal1': _criaId,
            'npesoanimal1': pesoCriaDestete,
            'catsale': _categoriaCria,
            'catentra': categoriatmp,
            'canentra': 1,
            'cansale': 1,
            'npesonace': pesoNacetmp,
            'ndiasdestete': diasDestete,
            'nganancia': gananciaPesoTmp,
          });
        } else {
          // Insert normal cria movement
          await Supabase.instance.client.from('dbmovimientos').insert({
            'iddocum': idDoc,
            'nfinca': widget.arguments['fincaId'],
            'ffecha': DateTime.now().toIso8601String(),
            'stipomov': 'DT',
            'nidanimal1': _criaId,
            'npesoanimal1': pesoCriaDestete,
            'catsale': _categoriaCria,
            'catentra': categoriatmp,
            'canentra': 1,
            'cansale': 1,
            'npesonace': pesoNacetmp,
            'ndiasdestete': diasDestete,
            'nganancia': gananciaPesoTmp,
          });

          // Insert mother movement
          await Supabase.instance.client.from('dbmovimientos').insert({
            'iddocum': idDoc,
            'nfinca': widget.arguments['fincaId'],
            'ffecha': DateTime.now().toIso8601String(),
            'stipomov': 'DTM',
            'nidanimal1': _madreId,
            'npesoanimal1': pesoMadre,
            'catsale': _categoriaMadre,
            'catentra': 'HS',
            'canentra': 1,
            'cansale': 1,
          });
        }

        // Update cria in dbanimal
        await Supabase.instance.client
            .from('dbanimal')
            .update({
              'n_pesonace': pesoNacetmp,
              'n_pesoultimo': pesoCriaDestete,
              'fnacimiento': fechaNacetmp.toIso8601String(),
              'scategoria': categoriatmp,
            })
            .eq('sid_animal', _criaId)
            .eq('n_finca', widget.arguments['fincaId']);

        // Update mother in dbanimal
        await Supabase.instance.client
            .from('dbanimal')
            .update({
              'n_pesoultimo': pesoMadre,
              'scategoria': 'HS',
            })
            .eq('sid_animal', _madreId)
            .eq('n_finca', widget.arguments['fincaId']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Destete guardado exitosamente')),
          );
          Navigator.pop(context);
        }
      } catch (e, stackTrace) {
        debugPrint('Error saving destete: $e');
        debugPrint('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar el destete'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4D3E),
        title: const Text(
          'Agregar Destete',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('Finca-Usuario',
                        '${widget.arguments['fincaId'].toString()} - ${widget.arguments['nombreFinca']} - ${widget.arguments['userId']}'),
                    _buildSectionTitle('Datos de la Cría'),
                    _buildDataRow('ID Cría', _criaId),
                    _buildDataRow('Nombre', _nomCria),
                    _buildDataRow('Categoría', _categoriaCria),
                    _buildDataRow(
                        'Fecha Nace',
                        _fechaNace != null
                            ? DateFormat('dd/MM/yyyy').format(_fechaNace!)
                            : ''),
                    _buildDataRow('Peso Nace', _pesoNace?.toString() ?? ''),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Datos de la Madre'),
                    _buildDataRow('ID Madre', _madreId),
                    _buildDataRow('Nombre', _nomMadre),
                    _buildDataRow('Categoría', _categoriaMadre),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Datos Destete'),
                    _buildDateField(
                      'Fecha del parto',
                      _fechaDesteteController,
                      (value) => value?.isEmpty == true
                          ? 'Este campo es requerido'
                          : null,
                    ),
                    _buildNumberField(
                      'Peso de la Madre Kg',
                      _pesoMadreController,
                      (value) => value?.isEmpty == true
                          ? 'Este campo es requerido'
                          : null,
                    ),
                    _buildNumberField(
                      'Peso de la cría Kg',
                      _pesoCriaController,
                      (value) => value?.isEmpty == true
                          ? 'Este campo es requerido'
                          : null,
                    ),
                    _buildNumberField(
                      'Días destete',
                      _diasDesteteController,
                      (value) => value?.isEmpty == true
                          ? 'Este campo es requerido'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDestete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              )
                            : const Text(
                                'Agregar destete +',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B4D3E),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    String? Function(String?)? validator,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        readOnly: true,
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            controller.text = DateFormat('yyyy-MM-dd').format(date);
          }
        },
        validator: validator,
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    String? Function(String?)? validator,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _fechaDesteteController.dispose();
    _pesoMadreController.dispose();
    _pesoCriaController.dispose();
    _diasDesteteController.dispose();
    super.dispose();
  }
}
