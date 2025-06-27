import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'signup_page.dart';
import 'SkillSelectionPage.dart'; // New page for selecting skills

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Changed to black for contrast
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0), // Slightly increased padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 200, // Slightly reduced size for minimalism
                  color: Colors.white, // White tint for black background
                ),
                const SizedBox(height: 40),
                Text(
                  'Login',
                  style: GoogleFonts.robotoMono(
                    fontSize: 28, // Slightly larger for emphasis
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 300, // Reduced width for minimalism
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: _inputDecoration('Email'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    decoration: _inputDecoration('Password'),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _signIn(context),
                  style: _buttonStyle(),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.robotoMono(
                      color: Colors.black, // Black text on white button
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Signup()),
                    );
                  },
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.robotoMono(
                      color: Colors.white70, // Slightly muted white
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

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white54), // Muted white hint
      contentPadding: const EdgeInsets.symmetric(vertical: 14), // Slimmer input
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(8), // Sharper corners
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white, // White button on black background
      foregroundColor: Colors.black, // Black text/icon color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Sharper corners
      ),
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
      elevation: 0, // Flat design for minimalism
    );
  }

  Future<void> _signIn(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SkillSelectionPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login failed',
            style: GoogleFonts.robotoMono(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
