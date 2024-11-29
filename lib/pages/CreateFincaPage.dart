import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateFincaPage extends StatefulWidget {
  const CreateFincaPage({Key? key}) : super(key: key);

  @override
  _CreateFincaPageState createState() => _CreateFincaPageState();
}

class _CreateFincaPageState extends State<CreateFincaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreFincaController = TextEditingController();
  final _nitController = TextEditingController();
  final _legalController = TextEditingController();
  final _contactoController = TextEditingController();
  final _emailFincaController = TextEditingController();
  final _celularFincaController = TextEditingController();
  String? _selectedDepartamento;
  String? _selectedMunicipio;

  final List<String> departamentos = ['Antioquia', 'Córdoba'];
  final Map<String, List<String>> municipios = {
    'Antioquia': ['Caceres', 'Caucasia', 'Zaragoza', 'Nechi', 'El Bagre'],
    'Córdoba': ['Caceres', 'Caucasia', 'Zaragoza', 'Nechi', 'El Bagre'],
  };

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          _showErrorMessage('Usuario no autenticado');
          return;
        }

        final response =
            await Supabase.instance.client.from('dbFincas').insert({
          's_nombrefinca': _nombreFincaController.text,
          's_nit': _nitController.text,
          's_legal': _legalController.text,
          's_contacto': _contactoController.text,
          's_departamento': _selectedDepartamento,
          's_ciudad': _selectedMunicipio,
          's_emailfinca': _emailFincaController.text,
          's_celularfinca': _celularFincaController.text,
          'iduser': user.id,
        }).select();

        if (response.isEmpty) {
          throw Exception('No se pudo crear la finca');
        }

        _showSuccessMessage('Finca creada exitosamente');
        Navigator.of(context).pop(true);
      } catch (e) {
        _showErrorMessage('Error al crear la finca: ${e.toString()}');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Fincas'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 650),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('images/afagro_logo.png', height: 100),
                  const SizedBox(height: 20),
                  const Text(
                    'Fincas',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ingrese los datos de la Finca:',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _nombreFincaController,
                    label: 'Nombre de la Finca',
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Por favor ingrese el nombre de la finca'
                        : null,
                  ),
                  _buildTextField(
                    controller: _nitController,
                    label: 'Número Identificación - Nit o CC',
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Por favor ingrese el NIT o CC'
                        : null,
                  ),
                  _buildTextField(
                    controller: _legalController,
                    label: 'Propietario',
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Por favor ingrese el nombre del propietario'
                        : null,
                  ),
                  _buildTextField(
                    controller: _contactoController,
                    label: 'Encargado de los datos',
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Por favor ingrese el nombre del encargado'
                        : null,
                  ),
                  _buildDropdownField(
                    value: _selectedDepartamento,
                    label: 'Departamento',
                    items: departamentos,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDepartamento = newValue;
                        _selectedMunicipio = null;
                      });
                    },
                    validator: (value) => value == null
                        ? 'Por favor seleccione un departamento'
                        : null,
                  ),
                  _buildDropdownField(
                    value: _selectedMunicipio,
                    label: 'Municipio',
                    items: _selectedDepartamento != null
                        ? municipios[_selectedDepartamento!] ?? []
                        : [],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMunicipio = newValue;
                      });
                    },
                    validator: (value) => value == null
                        ? 'Por favor seleccione un municipio'
                        : null,
                  ),
                  _buildTextField(
                    controller: _emailFincaController,
                    label: 'Correo',
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Por favor ingrese un correo';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value!)) {
                        return 'Por favor ingrese un correo válido';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    controller: _celularFincaController,
                    label: 'Teléfono - Celular',
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Por favor ingrese un número de teléfono o celular'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Grabar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
