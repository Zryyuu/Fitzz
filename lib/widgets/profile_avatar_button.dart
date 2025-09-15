import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fitzz/services/storage_service.dart';
import 'package:fitzz/pages/profile_page.dart';

class ProfileAvatarButton extends StatefulWidget {
  const ProfileAvatarButton({super.key, this.radius = 18});

  final double radius;

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  String? _avatarBase64;
  int? _selectedBadge;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = LocalStorageService.instance;
    final avatar = await storage.getAvatarBase64();
    final badge = await storage.getSelectedBadgeLevel();
    if (!mounted) return;
    setState(() {
      _avatarBase64 = avatar;
      _selectedBadge = badge;
      _loading = false;
    });
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

    final imageProvider = (_avatarBase64 == null) ? null : MemoryImage(base64Decode(_avatarBase64!));
    final ringColor = _ringColorForBadge(_selectedBadge);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
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
