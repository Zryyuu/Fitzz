import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:fitzz/services/storage_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 10000));
    final loggedIn = await LocalStorageService.instance.isLoggedIn();
    if (!mounted) return;
    if (loggedIn) {
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
              const Icon(Ionicons.fitness_sharp, color: Colors.black, size: 56),
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
