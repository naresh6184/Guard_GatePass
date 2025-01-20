// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuardLoginPage extends StatefulWidget {
  const GuardLoginPage({super.key});

  @override
  GuardLoginPageState createState() => GuardLoginPageState();
}

class GuardLoginPageState extends State<GuardLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';
  bool showPassword = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkRememberedUser();
  }

  Future<void> _checkRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');
    final savedRememberMe = prefs.getBool('rememberMe') ?? false;

    if (savedRememberMe && savedEmail != null && savedPassword != null) {
      setState(() {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        rememberMe = savedRememberMe;
      });
      await _login(); // Attempt auto-login
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _login() async {
    try {
      // Log in using email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);

      User? user = userCredential.user;

      if (user == null) {
        setState(() => errorMessage = 'User not found');
        return;
      }

      // Check email verification
      if (!user.emailVerified) {
        setState(() => errorMessage = 'Please verify your email.');
        return;
      }

      // Check ActivePermission from the database
      DocumentSnapshot guardDoc = await FirebaseFirestore.instance
          .collection('guards')
          .doc(user.uid)
          .get();

      if (guardDoc.exists) {
        bool activePermission = guardDoc['activePermission'] ?? false;

        if (!activePermission) {
          setState(
                  () => errorMessage = 'You are not Fully Authorized to Login');
          return;
        }

        // Save credentials if "Remember Me" is checked
        await _saveCredentials();

        // Login successful
        setState(() => errorMessage = '');
        // Navigate to the home screen or dashboard
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => errorMessage = 'Guard not found in the database.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Login failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => errorMessage = ''),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Guard Login'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor:
          const Color.fromARGB(255, 86, 8, 164), // Purple title color
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Spacing to maintain symmetry
                const SizedBox(height: 80), // Added spacing for symmetry

                _buildTextField('Email', emailController,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _buildPasswordField(
                  'Password',
                  passwordController,
                  showPassword,
                      (value) {
                    setState(() => showPassword = value);
                  },
                ),
                const SizedBox(height: 20),
                if (errorMessage.isNotEmpty)
                  _buildMessage(errorMessage, Colors.red),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Remember Me',
                      style: TextStyle(color: Color.fromARGB(255, 90, 12, 157)),
                    ),
                    const Spacer(), // This pushes the 'Forgot Password?' button to the right
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/forgot');
                      },
                      child: const Text(
                        'Forgot Password?',
                        style:
                        TextStyle(color: Color.fromARGB(255, 73, 39, 118)),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Color.fromARGB(255, 79, 26, 147)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      child: const Text(
                        'Sign Up',
                        style:
                        TextStyle(color: Color.fromARGB(255, 63, 16, 124)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color.fromARGB(255, 11, 11, 11)),
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildPasswordField(String labelText, TextEditingController controller,
      bool showPassword, void Function(bool) onToggle) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => onToggle(!showPassword),
        ),
      ),
    );
  }

  Widget _buildMessage(String message, Color color) {
    return Text(
      message,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}
