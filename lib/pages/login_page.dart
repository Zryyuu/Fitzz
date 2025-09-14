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
  bool _obscurePass = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final email = _emailCtrl.text.trim().toLowerCase();
      final pass = _passCtrl.text;
      final storage = LocalStorageService.instance;
      final ok = await storage.validateCredentials(email: email, password: pass);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email atau password salah')));
        return;
      }
      await storage.setActiveEmail(email);
      await storage.setLoggedIn(true);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final panelTop = size.height * 0.3; // ~2/5 of the screen height
    // Cap how much bottom padding we add when the keyboard is open to avoid overly long scrollable area
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final cappedKeyboardInset = keyboardInset.clamp(0.0, 90.0);
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Header icon centered within the enlarged black header
            Positioned(
              top: size.height * 0.10,
              left: 0,
              right: 0,
              child: const Icon(Ionicons.person_sharp, color: Colors.white, size: 72),
            ),
            // White panel overlapped
            Positioned.fill(
              top: panelTop,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(64),
                    topRight: Radius.circular(0),
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (overscroll) {
                    overscroll.disallowIndicator();
                    return true;
                  },
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + cappedKeyboardInset),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Text('Login', style: theme.textTheme.headlineSmall),
                          ),
                          const SizedBox(height: 20),
                          // Email label and field
                          Text('Email', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Masukkan email';
                              final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                              if (!emailRegex.hasMatch(v)) return 'Format email tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          // Password label and field
                          Text('Password', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Ionicons.eye_off : Ionicons.eye),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) => (v==null||v.isEmpty) ? 'Masukkan password' : null,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'lupa password?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                  : const Text('Login' , style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
            ),
          ],
        ),
      ),
    );
  }

  // InputDecoration is centralized via Theme.inputDecorationTheme
}
