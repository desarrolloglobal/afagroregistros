import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:convert'; // Añadimos importación para utf8

class CargarInventarioPage extends StatefulWidget {
  final int fincaId;
  final String nombreFinca;
  final SupabaseClient supabase;
  final String userId;

  const CargarInventarioPage({
    Key? key,
    required this.fincaId,
    required this.nombreFinca,
    required this.supabase,
    required this.userId,
  }) : super(key: key);

  @override
  _CargarInventarioPageState createState() => _CargarInventarioPageState();
}

class _CargarInventarioPageState extends State<CargarInventarioPage> {
  String? _selectedFilePath;
  bool _isLoading = false;
  List<List<dynamic>>? _csvData;
  PlatformFile? _selectedFile;

  Future<void> _downloadTemplate() async {
    try {
      final String csvData =
          await rootBundle.loadString('assets/files/inventario.csv');

      // Crear el blob con el contenido CSV usando utf8 encode
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Crear un elemento anchor temporal para la descarga
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'plantilla_inventario.csv')
        ..style.display = 'none';

      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      _showSuccessMessage('Plantilla descargada exitosamente');
    } catch (e) {
      _showErrorMessage('Error al descargar la plantilla: ${e.toString()}');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.name;
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      _showErrorMessage('Error al seleccionar el archivo: ${e.toString()}');
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

  String? _parseDateToString(String? value) {
    try {
      if (value == null || value.trim().isEmpty)
        return null; // Return null for empty cells

      // Try parsing with d/mm/yyyy format first
      final format = DateFormat('d/MM/yyyy');
      final date = format.parse(value);
      return date.toIso8601String();
    } catch (e) {
      try {
        // If d/mm/yyyy fails, try parsing with other formats or default DateTime.parse
        final date =
            DateTime.parse(value!); // Fallback to default parsing (if needed)
        return date.toIso8601String();
      } catch (e) {
        print('Error parsing date: $value');
        return null; // Return null on parsing error
      }
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) {
      _showErrorMessage('Por favor, seleccione un archivo primero');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert CSV to list
      String csvString = String.fromCharCodes(_selectedFile!.bytes!);
      _csvData = const CsvToListConverter(fieldDelimiter: ';')
          .convert(csvString)
          .skip(1)
          .toList();

      // 1. Create document record first
      final DateTime now = DateTime.now();
      final documentData = {
        'sdoc': '1',
        'ffechadoc': now.toIso8601String(),
        'tipomov': 'II',
        'sdescripcion': 'Inventario Inicial',
        'useriddoc': widget.userId,
      };

      // Insert document and get the generated ID
      final DocumentResponse = await widget.supabase
          .from('dbdocumentos')
          .insert(documentData)
          .select('iddoc')
          .single();

      final int iddocumento = DocumentResponse['iddoc'];

      // Prepare data for dbanimaltmp
      List<Map<String, dynamic>> animalesData = _csvData!.map((row) {
        return {
          'n_finca': widget.fincaId,
          'sid_animal': row[0].toString(),
          'snom_animal': row[1].toString(),
          'svacuno_bufalo': row[2].toString(),
          'scategoria': row[3].toString(),
          'sid_madre': row[4].toString(),
          'snombremadre': row[5].toString(),
          'sid_padre': row[6].toString(),
          'fnacimiento': _parseDateToString(row[7]?.toString()),
          'ndiasnace': double.tryParse(row[8].toString()),
          'nmesesnace': double.tryParse(row[9].toString()),
          'n_pesonace': double.tryParse(row[10].toString()),
          'fparto1': _parseDateToString(row[11]?.toString()),
          'fultimoparto': _parseDateToString(row[12]?.toString()),
          'fpanterior': _parseDateToString(row[13]?.toString()),
          'n_partos': double.tryParse(row[14].toString()),
          'scolor': row[15].toString(),
          'sraza': row[16].toString(),
          'n_pesoultimo': double.tryParse(row[17].toString()),
          'n_valorkilo': double.tryParse(row[18].toString()),
        };
      }).toList();

      // Insert into temporary table
      await widget.supabase.from('dbanimaltmp').insert(animalesData);

      // Create movement records from dbanimaltmp data
      final tmpAnimals = await widget.supabase
          .from('dbanimaltmp')
          .select()
          .eq('n_finca', widget.fincaId);

      final List<Map<String, dynamic>> movimientosData =
          tmpAnimals.map((animal) {
        return {
          'iddocum': iddocumento,
          'nfinca': widget.fincaId,
          'ffecha': now.toIso8601String(),
          'stipomov': 'II',
          'nidanimal1': animal['sid_animal']?.toString().isEmpty == true
              ? animal['snom_animal']
              : animal['sid_animal'],
          'nnomanimal': animal['snom_animal'],
          'npesoanimal1': animal['n_pesoultimo'],
          'catentra': animal['scategoria'],
          'canentra': 1,
          'cansale': 0,
        };
      }).toList();

      // Insert movement records
      await widget.supabase.from('dbmovimientos').insert(movimientosData);

      // Transform and move data from dbanimaltmp to dbanimal
      final result = await widget.supabase.rpc('sp_transform_and_move_animals',
          params: {'p_finca_id': widget.fincaId});

      // Clear the temporary table
      await widget.supabase
          .from('dbanimaltmp')
          .delete()
          .eq('n_finca', widget.fincaId);

      _showSuccessMessage(
          'Archivo procesado exitosamente. ${animalesData.length} registros importados.');

      setState(() {
        _selectedFilePath = null;
        _selectedFile = null;
        _csvData = null;
      });
    } catch (e) {
      _showErrorMessage('Error al procesar el archivo: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4D3E),
        title: const Text(
          'CARGAR INVENTARIO INICIAL',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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
                          'Finca: ${widget.fincaId} ${widget.nombreFinca} ${widget.userId}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Instrucciones:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Descargue la plantilla CSV para el inventario de animales\n'
                          '2. Complete la plantilla con la información de los animales. Las columnas son: ID Animal, Nombre, Tipo, Categoría, ID Madre, Nombre Madre, ID Padre, Fecha Nacimiento, Días Nace, Meses Nace, Peso Nace, Fecha Primer Parto, Fecha Último Parto, Fecha Anterior, Número Partos, Color, Raza, Peso Último, Valor Kilo\n'
                          '3. Las fechas deben estar en formato d/mm/yyyy\n'
                          '4. Use punto y coma (;) como separador\n'
                          '5. Seleccione el archivo completado y presione "Procesar" para cargar el inventario',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _downloadTemplate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4D3E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text(
                            'Descargar Plantilla',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedFilePath ??
                                    'Ningún archivo seleccionado',
                                style: TextStyle(
                                  color: _selectedFilePath != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickFile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4D3E),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.file_upload,
                                  color: Colors.white),
                              label: const Text(
                                'Seleccionar Archivo',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _processFile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4D3E),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Procesar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
}
