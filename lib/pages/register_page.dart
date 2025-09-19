import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitzz/services/firebase_user_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final pass = _passCtrl.text;
      final name = _nameCtrl.text.trim();
      // Create user with Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      // Try update display name on auth profile (best effort)
      try {
        await cred.user?.updateDisplayName(name);
      } catch (_) {}
      // Create user profile document
      final uid = cred.user!.uid;
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          StorageKeys.displayName: name,
          StorageKeys.totalXp: 0,
          StorageKeys.totalWorkouts: 0,
          StorageKeys.bestStrike: 0,
          StorageKeys.strikeCount: 0,
          'avatarUrl': null,
          StorageKeys.badgesEarned: <int>[],
          StorageKeys.selectedBadgeLevel: null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on FirebaseException catch (e) {
        // Roll back the partially created account to avoid orphaned auth users with no profile
        try { await cred.user?.delete(); } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: ${e.message ?? e.code}')),
        );
        return; // stop flow
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi berhasil. Silakan login')));
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      String msg = 'Registrasi gagal';
      if (e.code == 'email-already-in-use') msg = 'Email sudah terdaftar';
      if (e.code == 'weak-password') msg = 'Password terlalu lemah';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final panelTop = size.height * 0.2; // sama seperti Login untuk jarak atas lebih lebar
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final cappedKeyboardInset = keyboardInset.clamp(0.0, 130.0);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Header title di area hitam
            Positioned(
              top: size.height * 0.08,
              left: 0,
              right: 0,
              child: Center(
                child: Text('Buat Akun', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
              ),
            ),
            // Panel putih dengan radius yang sama seperti Login
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
                    physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + cappedKeyboardInset),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Label di atas setiap kolom
                          Text('Nama', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(),
                            validator: (v) => (v==null||v.isEmpty) ? 'Masukkan nama' : null,
                          ),
                          const SizedBox(height: 14),

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

                          Text('Password', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Ionicons.eye_off : Ionicons.eye),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) => (v==null||v.length<6) ? 'Min. 6 karakter' : null,
                          ),
                          const SizedBox(height: 14),

                          Text('Konfirmasi Password', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Ionicons.eye_off : Ionicons.eye),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) => (v!=_passCtrl.text) ? 'Tidak cocok' : null,
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
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Daftar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Sudah punya akun?  '),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                                child: const Text('Masuk Sekarang', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
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

  // InputDecoration centralized via Theme.inputDecorationTheme
}
