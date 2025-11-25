import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  DateTime? _selectedDate;

  final _firebaseService = FirebaseService();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: Colors.purple.shade400,
            onPrimary: Colors.white,
            surface: Colors.grey.shade900,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    // HATA ÇÖZÜMÜ: Süslü parantez
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text("Şifre Sıfırlama",
            style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("E-posta adresinizi girin.",
                style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: const InputDecoration(hintText: "E-posta"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) return;
              try {
                await _firebaseService
                    .sendPasswordResetEmail(resetEmailController.text.trim());
                // HATA ÇÖZÜMÜ: Süslü parantezler
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("E-posta gönderildi!")));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Hata: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Gönder", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      _showError("Geçerli email ve en az 6 haneli şifre girin.");
      return;
    }

    if (!_isLogin &&
        (_nameController.text.isEmpty ||
            _surnameController.text.isEmpty ||
            _selectedDate == null)) {
      _showError("Lütfen tüm alanları doldurun.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _firebaseService.signIn(email, password);
      } else {
        await _firebaseService.signUp(
          email: email,
          password: password,
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          birthDate: _selectedDate!,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Bir hata oluştu.");
    } finally {
      // HATA ÇÖZÜMÜ: Süslü parantez
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _firebaseService.signInWithGoogle();
    } catch (e) {
      _showError("Google girişi başarısız: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), backgroundColor: Colors.red.shade700));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.auto_awesome_mosaic_rounded,
                        size: 60, color: Colors.purple.shade400),
                  ),
                ),
                const SizedBox(height: 30),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    _isLogin ? 'Hoş Geldiniz' : 'Hesap Oluştur',
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          Row(children: [
                            Expanded(
                                child: _buildTextField(
                                    _nameController, 'Ad', Icons.person)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildTextField(_surnameController,
                                    'Soyad', Icons.person_outline)),
                          ]),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickDate,
                            child: _buildContainer(
                              child: Row(children: [
                                Icon(Icons.cake_rounded,
                                    color: Colors.purple.shade400),
                                const SizedBox(width: 12),
                                Text(
                                    _selectedDate == null
                                        ? 'Doğum Tarihi'
                                        : DateFormat('d MMM yyyy', 'tr')
                                            .format(_selectedDate!),
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70))
                              ]),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildTextField(
                            _emailController, 'E-posta', Icons.email_rounded),
                        const SizedBox(height: 16),
                        _buildTextField(
                            _passwordController, 'Şifre', Icons.key_rounded,
                            isPassword: true),
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text("Şifremi Unuttum?",
                                  style: GoogleFonts.poppins(
                                      color: Colors.purple.shade300,
                                      fontSize: 12)),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _authenticate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade600,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _googleSignIn,
                    icon: const Icon(Icons.g_mobiledata_rounded,
                        size: 32, color: Colors.white),
                    label: Text("Google ile Devam Et",
                        style: GoogleFonts.poppins(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: RichText(
                        text: TextSpan(
                            text: _isLogin
                                ? "Hesabın yok mu? "
                                : "Zaten hesabın var mı? ",
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade500),
                            children: [
                          TextSpan(
                              text: _isLogin ? "Kayıt Ol" : "Giriş Yap",
                              style: GoogleFonts.poppins(
                                  color: Colors.purple.shade400,
                                  fontWeight: FontWeight.bold))
                        ])),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10)),
      child: child,
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isPassword = false}) {
    return _buildContainer(
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.purple.shade400),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
