import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_state_manager.dart';
import 'cargar_inventario.dart';
import 'lista_animales.dart';
import 'menu_reclasifica.dart';
import 'movimientos_page.dart';

class MenuFincaPage extends StatelessWidget {
  final int fincaId;
  final String nombreFinca;

  MenuFincaPage({
    required this.fincaId,
    required this.nombreFinca,
  });

  String get userId =>
      OfflineStateManager().currentUserId ??
      Supabase.instance.client.auth.currentUser!.id;

  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1B4D3E),
          padding: EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCargarInventario(BuildContext context) {
    // Obtenemos la instancia de Supabase que ya está inicializada
    final supabase = Supabase.instance.client;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CargarInventarioPage(
          fincaId: fincaId,
          nombreFinca: nombreFinca,
          supabase: supabase, // Pasamos la instancia de Supabase
          userId: userId,
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
          'MENÚ FINCA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
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
                          SizedBox(height: 12),
                          Text(
                            'Finca: $fincaId $nombreFinca $userId',
                            style: TextStyle(fontSize: 16),
                          ),
                          // Text(
                          //   'Usuario ID: $userId',
                          //   style: TextStyle(fontSize: 16),
                          // ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Opciones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildMenuButton(
                    title: 'Datos de la Finca',
                    icon: Icons.business,
                    onPressed: () {
                      // Navigate to farm data page
                    },
                  ),
                  _buildMenuButton(
                    title: 'Ver Animales',
                    icon: Icons.history_edu,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListaAnimalesPage(
                            fincaId: fincaId,
                            nombreFinca: nombreFinca,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    title: 'Cargar Inventario Inicial',
                    icon: Icons.file_upload,
                    onPressed: () => _navigateToCargarInventario(context),
                  ),
                  _buildMenuButton(
                    title: 'Reclasificaciones',
                    icon: Icons.compare_arrows,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuReclasificaPage(
                            fincaId: fincaId,
                            nombreFinca: nombreFinca,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    title: 'Pesajes - Control',
                    icon: Icons.monitor_weight,
                    onPressed: () {
                      // Navigate to weight control page
                    },
                  ),
                  _buildMenuButton(
                    title: 'Reportes',
                    icon: Icons.assessment,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovimientosPage(
                            fincaId: fincaId,
                            nombreFinca: nombreFinca,
                            userId: userId,
                          ),
                        ),
                      );
                    },
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
