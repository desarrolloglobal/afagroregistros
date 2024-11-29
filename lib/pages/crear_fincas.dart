import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_state_manager.dart';

class CrearFincasPage extends StatefulWidget {
  @override
  _CrearFincasPageState createState() => _CrearFincasPageState();
}

class _CrearFincasPageState extends State<CrearFincasPage> {
  final _formKey = GlobalKey<FormState>();
  final _stateManager = OfflineStateManager();

  // Form controllers
  final _nombreFincaController = TextEditingController();
  final _nitController = TextEditingController();
  final _propietarioController = TextEditingController();
  final _contactoController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();

  // Dropdown values
  String? _selectedDepartamento;
  String? _selectedCiudad;
  List<String> _departamentos = [];
  List<String> _ciudades = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDepartamentos();
  }

  Future<void> _loadDepartamentos() async {
    try {
      print('Cargando departamentos...');
      final response = await Supabase.instance.client
          .from('ts_departamentos')
          .select('nomdepartamento')
          .order('nomdepartamento');

      print('Respuesta departamentos: $response');

      if (mounted) {
        setState(() {
          _departamentos = List<String>.from((response as List)
              .map((dep) => dep['nomdepartamento'] as String));
        });
      }
    } catch (e) {
      print('Error cargando departamentos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar departamentos')));
      }
    }
  }

  Future<void> _loadCiudades(String departamento) async {
    try {
      print('Cargando ciudades para: $departamento');
      final response = await Supabase.instance.client
          .from('ts_municipios')
          .select('smunicipio')
          // .eq('nomdepartamento', departamento)
          .order('smunicipio');

      print('Respuesta ciudades: $response');

      if (mounted) {
        setState(() {
          _ciudades = List<String>.from(
              (response as List).map((city) => city['smunicipio'] as String));
        });
      }
    } catch (e) {
      print('Error cargando ciudades: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al cargar ciudades')));
      }
    }
  }

  Future<void> _guardarFinca() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('dbFincas').insert({
        's_nombrefinca': _nombreFincaController.text,
        's_nit': _nitController.text,
        's_legal': _propietarioController.text,
        's_contacto': _contactoController.text,
        's_departamento': _selectedDepartamento,
        's_ciudad': _selectedCiudad,
        's_emailfinca': _emailController.text,
        's_celularfinca': _celularController.text,
        'iduser': _stateManager.currentUserId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Finca guardada exitosamente')));
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error guardando finca: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar la finca: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDepartamentoDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartamento,
      decoration: InputDecoration(
        labelText: 'Departamento',
        border: OutlineInputBorder(),
        errorText:
            _departamentos.isEmpty ? 'Error cargando departamentos' : null,
      ),
      hint: Text('Seleccione un departamento'),
      items: _departamentos.map((String departamento) {
        return DropdownMenuItem(
          value: departamento,
          child: Text(departamento),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedDepartamento = newValue;
          _selectedCiudad = null; // Reset ciudad when departamento changes
          _ciudades.clear(); // Clear ciudades list
          if (newValue != null) {
            _loadCiudades(newValue);
          }
        });
      },
      validator: (value) => value == null ? 'Seleccione un departamento' : null,
    );
  }

  Widget _buildCiudadDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCiudad,
      decoration: InputDecoration(
        labelText: 'Ciudad',
        border: OutlineInputBorder(),
        errorText: _selectedDepartamento != null && _ciudades.isEmpty
            ? 'Error cargando ciudades'
            : null,
      ),
      hint: Text('Seleccione una ciudad'),
      items: _ciudades.map((String ciudad) {
        return DropdownMenuItem(
          value: ciudad,
          child: Text(ciudad),
        );
      }).toList(),
      onChanged: _selectedDepartamento == null
          ? null
          : (String? newValue) {
              setState(() {
                _selectedCiudad = newValue;
              });
            },
      validator: (value) => value == null ? 'Seleccione una ciudad' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        title: Text('Adicionar Fincas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nombreFincaController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Finca',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nitController,
                    decoration: InputDecoration(
                      labelText: 'NIT',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _propietarioController,
                    decoration: InputDecoration(
                      labelText: 'Propietario',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _contactoController,
                    decoration: InputDecoration(
                      labelText: 'Contacto',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  SizedBox(height: 16),
                  _buildDepartamentoDropdown(),
                  SizedBox(height: 16),
                  _buildCiudadDropdown(),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _celularController,
                    decoration: InputDecoration(
                      labelText: 'Celular finca',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _guardarFinca,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34A853),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Guardar Finca',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreFincaController.dispose();
    _nitController.dispose();
    _propietarioController.dispose();
    _contactoController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    super.dispose();
  }
}
