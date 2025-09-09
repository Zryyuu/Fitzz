import 'package:flutter/material.dart';
import 'package:fitzz/services/storage_service.dart';
import 'package:ionicons/ionicons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    await LocalStorageService.instance.setLoggedIn(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final panelTop = size.height * 0.3; // ~2/5 of the screen height
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Header icon centered within the enlarged black header
            Positioned(
              top: size.height * 0.12,
              left: 0,
              right: 0,
              child: const Icon(Ionicons.person_sharp, color: Colors.white, size: 72),
            ),
            // White panel overlapped
            Positioned.fill(
              top: panelTop,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(64),
                    topRight: Radius.circular(0),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text('Login', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 20),
                        // Email label and field
                        Text('Email', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800])),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: _inputDecoration(),
                          validator: (v) => (v==null||v.isEmpty) ? 'Masukkan email' : null,
                        ),
                        const SizedBox(height: 14),
                        // Password label and field
                        Text('Password', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800])),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: _inputDecoration(),
                          validator: (v) => (v==null||v.isEmpty) ? 'Masukkan password' : null,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('lupa password?', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Belum punya akun?  '),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushReplacementNamed('/register'),
                              child: const Text('Daftar Sekarang', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        // Slight grey background for input fields
        fillColor: const Color(0xFFE5E5E5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}
