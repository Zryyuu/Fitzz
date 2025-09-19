import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Shorter splash delay to avoid late redirects during development/hot-restart
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    // Only navigate if Splash is still the current/top route and we haven't navigated before
    final isCurrent = ModalRoute.of(context)?.isCurrent == true;
    if (!isCurrent || _navigated) return;

    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final activeEmail = FirebaseAuth.instance.currentUser?.email;
    if (!mounted) return;
    _navigated = true;
    if (loggedIn && (activeEmail != null && activeEmail.isNotEmpty)) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Ionicons.fitness_sharp, color: Colors.black, size: 80),
              const SizedBox(height: 12),
              const Text(
                'Fitzz',
                style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
