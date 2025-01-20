// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuardSignupPage extends StatefulWidget {
  const GuardSignupPage({super.key});

  @override
  GuardSignupPageState createState() => GuardSignupPageState();
}

class GuardSignupPageState extends State<GuardSignupPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController gateNoController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String countryCode = '+91';
  bool mobileVerified = false;
  bool otpRequested = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  String verificationId = '';
  String errorMessage = '';
  String successMessage = '';

  bool emailTouched = false;
  bool phoneTouched = false;
  bool passwordTouched = false;
  bool confirmPasswordTouched = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => errorMessage = ''),
      child: Scaffold(
        appBar: AppBar(title: const Text('Guard Signup')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Full Name', fullNameController),
                const SizedBox(height: 10),
                _buildTextField(
                  'Email',
                  emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => emailTouched &&
                          (!value.contains('@') || !value.contains('.'))
                      ? 'Enter a valid email'
                      : null,
                  onFocus: () => setState(() => emailTouched = true),
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                  'Password',
                  passwordController,
                  showPassword,
                  (value) => setState(() => showPassword = value),
                  onFocus: () => setState(() => passwordTouched = true),
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                    'Confirm Password',
                    confirmPasswordController,
                    showConfirmPassword, 
                    (value) => setState(() => showConfirmPassword = value),
                  onFocus: () => setState(() {
                    confirmPasswordTouched = true;
                    _validatePasswords(); // Trigger validation on field focus
                  }),
                ),
                const SizedBox(height: 10),
                _buildTextField('Gate No.', gateNoController),
                const SizedBox(height: 10),
                _buildMobileNumberField(),
                const SizedBox(height: 20),
                if (errorMessage.isNotEmpty)
                  _buildMessage(errorMessage, Colors.red),
                if (successMessage.isNotEmpty)
                  _buildMessage(successMessage, Colors.green),
                
          
                const SizedBox(height: 20),
                if (!mobileVerified)
                  ElevatedButton(
                    onPressed:(){
                      _validatePasswords();
                      _requestOTP();
                    },
                    child: const Text('Verify Mobile Number'),
                  ),
                  Column(
            children: [
              _buildMessage(successMessage, Colors.green),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // going to Login Page
                   Navigator.pushReplacementNamed(
        context,
        '/'
      );
                },
                child: const Text(
                  'Already have an Account? Login',
                  style: TextStyle(color: Color.fromARGB(255, 48, 13, 94)),
                ),
              ),
            ],
          ),
                if (mobileVerified)
                  ElevatedButton(
                    onPressed: _signUp,
                    child: const Text('Sign Up'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String)? validator,
      VoidCallback? onFocus}) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && onFocus != null) onFocus();
      },
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          errorText: validator != null ? validator(controller.text) : null,
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildPasswordField(String labelText, TextEditingController controller,
      bool showPassword, void Function(bool) onToggle,
      {VoidCallback? onFocus}) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && onFocus != null) onFocus();
      },
      child: TextField(
        controller: controller,
        obscureText: !showPassword,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => onToggle(!showPassword),
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DropdownButton<String>(
              value: countryCode,
              items: ['+91', '+1', '+44', '+61', '+81']
                  .map((code) =>
                      DropdownMenuItem(value: code, child: Text(code)))
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => countryCode = newValue ?? '+91'),
            ),
            const SizedBox(width: 10),
            Expanded(child: _buildMobileNumberInput()),
          ],
        ),
        if (otpRequested) _buildOTPSection(),
      ],
    );
  }

  Widget _buildMobileNumberInput() {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) setState(() => phoneTouched = true);
      },
      child: TextField(
        controller: phoneController,
        keyboardType: TextInputType.number,
        maxLength: 10,
        readOnly: mobileVerified || otpRequested,
        decoration: InputDecoration(
          labelText: 'Mobile Number',
          border: const OutlineInputBorder(),
          counterText: '',
          errorText: phoneTouched &&
                  (phoneController.text.isEmpty ||
                      phoneController.text.length != 10)
              ? 'Enter a valid 10-digit number'
              : null,
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildOTPSection() {
    return Column(
      children: [
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Enter OTP',
            border: OutlineInputBorder(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _requestOTP,
              child: const Text('Resend OTP'),
            ),
            ElevatedButton(
              onPressed: _validateOTP,
              child: const Text('Validate OTP'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessage(String message, Color color) {
    return Text(
      message,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

 void _validatePasswords() {
    if (passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      setState(() => errorMessage = 'Password fields cannot be empty.');
    } else if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = 'Passwords do not match.');
    } else {
      setState(() => errorMessage = '');
    }
  }
  Future<void> _requestOTP() async {
    setState(() {
      errorMessage = '';
      successMessage = '';
    });

    if (phoneController.text.length != 10) {
      setState(() {
        errorMessage = 'Enter a valid 10-digit mobile number.';
      });
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '$countryCode${phoneController.text}',
      verificationCompleted: (PhoneAuthCredential credential) async {
        setState(() {
          mobileVerified = true;
          otpRequested = false;
          successMessage = 'Mobile number verified automatically!';
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          errorMessage = e.message ?? 'Verification failed!';
          otpRequested = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          this.verificationId = verificationId;
          otpRequested = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _validateOTP() async {
    String otp = otpController.text;
    if (otp.length == 6) {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: otp);

      try {
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() {
          mobileVerified = true;
          otpRequested = false;
          successMessage = 'Mobile number verified successfully!';
        });
      } catch (e) {
        setState(() => errorMessage = 'Invalid OTP: $e');
      }
    } else {
      setState(() => errorMessage = 'Invalid OTP');
    }
  }

  Future<void> _signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = 'Passwords do not match');
      return;
    }

    if (!emailController.text.contains('@') ||
        !emailController.text.contains('.')) {
      setState(() => errorMessage = 'Enter a valid email address.');
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      String guardId = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('guards').doc(guardId).set({
        'fullName': fullNameController.text,
        'email': emailController.text,
        'gateNo': gateNoController.text,
        'mobile': '$countryCode${phoneController.text}',
        'activePermission': false,
      });

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      setState(() => successMessage = 'Signup successful! Verification email sent.');
       // Wait for 2-3 seconds before redirecting to the login page
    await Future.delayed(const Duration(seconds: 3));

    // Redirect to login page
     Navigator.pushReplacementNamed(
        context,
        '/'
      );
    } catch (e) {
      setState(() => errorMessage = 'Signup failed: $e');
    }
  }
}
