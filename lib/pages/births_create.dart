import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BirthsRegistrationPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BirthsRegistrationPage({Key? key, required this.arguments})
      : super(key: key);

  @override
  _BirthsRegistrationPageState createState() => _BirthsRegistrationPageState();
}

class _BirthsRegistrationPageState extends State<BirthsRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _birthDate;
  final TextEditingController _motherWeightController = TextEditingController();
  int _numberOfOffspring = 1;

  // Controllers for first offspring
  final TextEditingController _idCria1Controller = TextEditingController();
  final TextEditingController _nameCria1Controller = TextEditingController();
  String _category1 = 'CH';
  final TextEditingController _weight1Controller = TextEditingController();
  final TextEditingController _color1Controller = TextEditingController();
  final TextEditingController _breed1Controller = TextEditingController();

  // Controllers for second offspring
  final TextEditingController _idCria2Controller = TextEditingController();
  final TextEditingController _nameCria2Controller = TextEditingController();
  String _category2 = 'CH';
  final TextEditingController _weight2Controller = TextEditingController();
  final TextEditingController _color2Controller = TextEditingController();
  final TextEditingController _breed2Controller = TextEditingController();

  // Controllers for third offspring
  final TextEditingController _idCria3Controller = TextEditingController();
  final TextEditingController _nameCria3Controller = TextEditingController();
  String _category3 = 'CH';
  final TextEditingController _weight3Controller = TextEditingController();
  final TextEditingController _color3Controller = TextEditingController();
  final TextEditingController _breed3Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _birthDate = DateTime.now();
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF1B4D3E)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1B4D3E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _saveBirth() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Get current mother data to check n_partos
      final motherDataList = await Supabase.instance.client
          .from('dbanimal')
          .select('n_partos')
          .eq('sid_animal', widget.arguments['motherId'])
          .eq('n_finca',
              widget.arguments['fincaId']) // Añadimos filtro por finca
          .limit(1); // Limitamos a 1 resultado

      if (motherDataList.isEmpty) {
        throw Exception('No se encontró el animal madre');
      }

      // Calculate new n_partos value
      final int newPartos = (motherDataList[0]['n_partos'] ?? 0) + 1;

      // Update mother's category, weight and births count
      await Supabase.instance.client
          .from('dbanimal')
          .update({
            'scategoria': 'HP',
            'n_pesoultimo': double.parse(_motherWeightController.text),
            'n_partos': newPartos,
          })
          .eq('sid_animal', widget.arguments['motherId'])
          .eq('n_finca',
              widget.arguments['fincaId']); // Añadimos filtro por finca

      // Create document record
      final docResponse = await Supabase.instance.client
          .from('dbdocumentos')
          .insert({
            'sdoc': '2',
            'ffechadoc': DateTime.now().toIso8601String(),
            'tipomov': 'NA',
            'useriddoc': widget.arguments['userId'],
          })
          .select()
          .single();

      final int docId = docResponse['iddoc'];

      // Create birth movement record
      await Supabase.instance.client.from('dbmovimientos').insert({
        'iddocum': docId,
        'nfinca': widget.arguments['fincaId'],
        'ffecha': DateTime.now().toIso8601String(),
        'stipomov': 'PTO',
        'nidanimal1': widget.arguments['motherId'],
        'npesoanimal1': double.parse(_motherWeightController.text),
        'catsale': widget.arguments['scategoria'],
        'catentra': 'HP',
        'canentra': 1,
        'cansale': 1,
      });

      // Function to create offspring records
      Future<void> createOffspringRecords(
        String idCria,
        String nameCria,
        String category,
        double weight,
        String color,
        String breed,
      ) async {
        // Create animal record
        await Supabase.instance.client.from('dbanimal').insert({
          'n_finca': widget.arguments['fincaId'],
          'sid_animal': idCria,
          'snom_animal': nameCria,
          'svacuno_bufalo': 'V',
          'scategoria': category,
          'sid_madre': widget.arguments['motherId'],
          'fnacimiento': _birthDate.toIso8601String(),
          'n_pesonace': weight,
          'scolor': color,
          'sraza': breed,
          'n_pesoultimo': weight,
        });

        // Create movement record
        await Supabase.instance.client.from('dbmovimientos').insert({
          'iddocum': docId,
          'nfinca': widget.arguments['fincaId'],
          'ffecha': DateTime.now().toIso8601String(),
          'stipomov': 'NA',
          'nidanimal1': idCria,
          'npesoanimal1': weight,
          'catentra': category,
          'canentra': 0,
          'cansale': 1,
        });
      }

      // Create records for first offspring
      await createOffspringRecords(
        _idCria1Controller.text,
        _nameCria1Controller.text,
        _category1,
        double.parse(_weight1Controller.text),
        _color1Controller.text,
        _breed1Controller.text,
      );

      // Create records for second offspring if exists
      if (_numberOfOffspring >= 2) {
        await createOffspringRecords(
          _idCria2Controller.text,
          _nameCria2Controller.text,
          _category2,
          double.parse(_weight2Controller.text),
          _color2Controller.text,
          _breed2Controller.text,
        );
      }

      // Create records for third offspring if exists
      if (_numberOfOffspring == 3) {
        await createOffspringRecords(
          _idCria3Controller.text,
          _nameCria3Controller.text,
          _category3,
          double.parse(_weight3Controller.text),
          _color3Controller.text,
          _breed3Controller.text,
        );
      }

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nacimiento registrado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el nacimiento: $e')),
      );
    }
  }

  Widget _buildOffspringForm(
    int index,
    TextEditingController idController,
    TextEditingController nameController,
    String category,
    TextEditingController weightController,
    TextEditingController colorController,
    TextEditingController breedController,
    Function(String) onCategoryChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Datos de la Cría ${index + 1}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1B4D3E),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        TextFormField(
          controller: idController,
          decoration: _buildInputDecoration('ID Cría'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: nameController,
          decoration: _buildInputDecoration('Nombre Cría'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: category,
          decoration: _buildInputDecoration('Categoría'),
          items: const [
            DropdownMenuItem(value: 'CM', child: Text('CM')),
            DropdownMenuItem(value: 'CH', child: Text('CH')),
          ],
          onChanged: (value) => onCategoryChanged(value ?? 'CM'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: weightController,
          decoration: _buildInputDecoration('Peso de la Cría (Kg)'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Campo requerido';
            if (double.tryParse(value!) == null) return 'Debe ser un número';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: colorController,
          decoration: _buildInputDecoration('Color'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: breedController,
          decoration: _buildInputDecoration('Raza o Cruce'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4D3E),
        title: const Text(
          'Nuevo Nacimiento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datos de la Madre',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: const Color(0xFF1B4D3E),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text('ID Madre: ${widget.arguments['motherId']}',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Nombre: ${widget.arguments['snom_animal']}',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Categoría: ${widget.arguments['scategoria']}',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _birthDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _birthDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration:
                                  _buildInputDecoration('Fecha del Parto'),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_birthDate),
                                  ),
                                  const Icon(Icons.calendar_today,
                                      color: Color(0xFF1B4D3E)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _motherWeightController,
                            decoration:
                                _buildInputDecoration('Peso de la Madre (Kg)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Campo requerido';
                              if (double.tryParse(value!) == null) {
                                return 'Debe ser un número';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _numberOfOffspring,
                            decoration:
                                _buildInputDecoration('Número de Crías'),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1')),
                              DropdownMenuItem(value: 2, child: Text('2')),
                              DropdownMenuItem(value: 3, child: Text('3')),
                            ],
                            onChanged: (value) {
                              setState(() => _numberOfOffspring = value ?? 1);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildOffspringForm(
                            0,
                            _idCria1Controller,
                            _nameCria1Controller,
                            _category1,
                            _weight1Controller,
                            _color1Controller,
                            _breed1Controller,
                            (value) => setState(() => _category1 = value),
                          ),
                          if (_numberOfOffspring >= 2) ...[
                            const Divider(height: 32),
                            _buildOffspringForm(
                              1,
                              _idCria2Controller,
                              _nameCria2Controller,
                              _category2,
                              _weight2Controller,
                              _color2Controller,
                              _breed2Controller,
                              (value) => setState(() => _category2 = value),
                            ),
                          ],
                          if (_numberOfOffspring == 3) ...[
                            const Divider(height: 32),
                            _buildOffspringForm(
                              2,
                              _idCria3Controller,
                              _nameCria3Controller,
                              _category3,
                              _weight3Controller,
                              _color3Controller,
                              _breed3Controller,
                              (value) => setState(() => _category3 = value),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveBirth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4D3E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Guardar Nacimiento',
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
        ),
      ),
    );
  }
}
