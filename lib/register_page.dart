import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _resendVerification(String email, String password) async {
    setState(() => _isLoading = true);
    try {
     
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      await userCredential.user!.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      
      _showSnackBar("Link baru terkirim! Silakan cek email Anda kembali.", Colors.blue);
    } catch (e) {
      _showSnackBar("Gagal mengirim ulang: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _handleRegister() async {
    String fullName = _fullNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Nama, Email, dan Password wajib diisi!", Colors.orange);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar("Format email tidak valid!", Colors.orange);
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password minimal 6 karakter!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'fullname': fullName,
        'email': email,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'role': 'user',
        'created_at': FieldValue.serverTimestamp(),
      });

      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        _showSnackBar(
          "Berhasil! Jika link expired, klik tombol di kanan ->", 
          Colors.green,
          showResend: true,
          email: email,
          pass: password,
        );
      }
      await FirebaseAuth.instance.signOut();

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) Navigator.pop(context);
      });

    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan sistem.";
      if (e.code == 'email-already-in-use') {
        message = "Email ini sudah terdaftar.";
      } else if (e.code == 'too-many-requests') {
        message = "Terlalu banyak permintaan. Coba lagi nanti.";
      }
      _showSnackBar(message, Colors.red);
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color, {bool showResend = false, String? email, String? pass}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: showResend ? 8 : 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: showResend 
          ? SnackBarAction(
              label: "KIRIM LAGI", 
              textColor: Colors.white,
              onPressed: () => _resendVerification(email!, pass!),
            )
          : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF64B5F6), Color(0xFF1B4EAD)],
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 40, top: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Create\nAccount",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // FORM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                children: [
                  _buildModernField(_fullNameController, "Full Name", Icons.person_rounded),
                  const SizedBox(height: 20),
                  _buildModernField(_emailController, "Email Address", Icons.email_rounded),
                  const SizedBox(height: 20),
                  _buildModernField(_phoneController, "Phone Number", Icons.phone_android_rounded),
                  const SizedBox(height: 20),
                  _buildModernField(_addressController, "Address", Icons.location_on_rounded),
                  const SizedBox(height: 20),
                  _buildModernField(
                    _passwordController, 
                    "Password", 
                    Icons.lock_rounded, 
                    isPassword: true
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C3FF), Color(0xFF1B4EAD)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B4EAD).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text(
                            "SIGN UP", 
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 1
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ", style: TextStyle(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Sign In", 
                          style: TextStyle(color: Color(0xFF1B4EAD), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1B4EAD), size: 22),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(_isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}