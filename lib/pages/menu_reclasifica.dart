import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_state_manager.dart';
import 'births_page.dart';

class MenuReclasificaPage extends StatelessWidget {
  final int fincaId;
  final String nombreFinca;

  MenuReclasificaPage({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        title: Text(
          'RECLASIFICACIONES',
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
                    'Opciones de Reclasificación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildMenuButton(
                    title: 'Nacimientos',
                    icon: Icons.child_care,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BirthsPage(
                            fincaId: fincaId,
                            nombreFinca: nombreFinca,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
                    title: 'Destetes',
                    icon: Icons.family_restroom,
                    onPressed: () {
                      // Navigate to weaning page
                    },
                  ),
                  _buildMenuButton(
                    title: 'Abortos',
                    icon: Icons.warning_rounded,
                    onPressed: () {
                      // Navigate to abortions page
                    },
                  ),
                  _buildMenuButton(
                    title: 'Muertes y Robos',
                    icon: Icons.dangerous,
                    onPressed: () {
                      // Navigate to deaths and theft page
                    },
                  ),
                  _buildMenuButton(
                    title: 'Destetes Huérfanos',
                    icon: Icons.person_off,
                    onPressed: () {
                      // Navigate to orphan weaning page
                    },
                  ),
                  _buildMenuButton(
                    title: 'Levantes',
                    icon: Icons.trending_up,
                    onPressed: () {
                      // Navigate to raising page
                    },
                  ),
                  _buildMenuButton(
                    title: 'Toretes',
                    icon: Icons.male,
                    onPressed: () {
                      // Navigate to young bulls page
                    },
                  ),
                  _buildMenuButton(
                    title: 'Hembras de Producción',
                    icon: Icons.female,
                    onPressed: () {
                      // Navigate to production females page
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
