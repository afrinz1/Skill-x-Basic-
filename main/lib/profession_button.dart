import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfessionButton extends StatelessWidget {
  final String title;
  final IconData icon;

  ProfessionButton({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Implement navigation or selection logic
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(title, style: GoogleFonts.robotoMono()),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}
