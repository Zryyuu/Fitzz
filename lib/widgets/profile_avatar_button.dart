import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fitzz/services/firebase_user_service.dart';
import 'package:fitzz/pages/tab_shell.dart';

class ProfileAvatarButton extends StatefulWidget {
  const ProfileAvatarButton({super.key, this.radius = 18});

  final double radius;

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  String? _avatarUrl;
  String? _avatarData; // base64 string
  int? _selectedBadge;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _attachListeners();
  }

  void _attachListeners() async {
    final storage = FirebaseUserService.instance;
    // Ensure notifiers have initial values
    await storage.preloadNotifiers();
    _avatarUrl = storage.avatarUrlNotifier.value;
    _avatarData = storage.avatarDataNotifier.value;
    _selectedBadge = storage.selectedBadgeLevelNotifier.value;
    if (mounted) setState(() => _loading = false);

    storage.avatarUrlNotifier.addListener(_onNotified);
    storage.avatarDataNotifier.addListener(_onNotified);
    storage.selectedBadgeLevelNotifier.addListener(_onNotified);
  }

  void _onNotified() {
    final storage = FirebaseUserService.instance;
    if (!mounted) return;
    setState(() {
      _avatarUrl = storage.avatarUrlNotifier.value;
      _avatarData = storage.avatarDataNotifier.value;
      _selectedBadge = storage.selectedBadgeLevelNotifier.value;
    });
  }

  @override
  void dispose() {
    final storage = FirebaseUserService.instance;
    storage.avatarUrlNotifier.removeListener(_onNotified);
    storage.avatarDataNotifier.removeListener(_onNotified);
    storage.selectedBadgeLevelNotifier.removeListener(_onNotified);
    super.dispose();
  }

  Color _ringColorForBadge(int? level) {
    if (level == null) return Colors.black;
    switch (level) {
      case 10:
        return const Color(0xFFB0BEC5);
      case 25:
        return const Color(0xFF26C6DA);
      case 45:
        return const Color(0xFF66BB6A);
      case 65:
        return const Color(0xFFFFCA28);
      case 75:
        return const Color(0xFFFF7043);
      case 100:
        return const Color(0xFFAB47BC);
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius;
    if (_loading) {
      return SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: const Center(
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    ImageProvider? imageProvider;
    if (_avatarData != null && _avatarData!.isNotEmpty) {
      try {
        final bytes = base64Decode(_avatarData!);
        imageProvider = MemoryImage(bytes);
      } catch (_) {
        imageProvider = null;
      }
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_avatarUrl!);
    } else {
      imageProvider = null;
    }
    final ringColor = _ringColorForBadge(_selectedBadge);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const TabShell(initialIndex: 4),
              transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        borderRadius: BorderRadius.circular(radius + 6),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 3),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(Icons.person_rounded, color: Colors.black, size: radius + 6)
                : null,
          ),
        ),
      ),
    );
  }
}
