import 'package:flutter/material.dart';
import 'package:fitzz/services/firebase_user_service.dart';
// import 'package:fitzz/widgets/app_drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
// Top header is not used on Profile per design

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _displayName;
  List<int> _earnedBadges = const [];
  int? _selectedBadge;
  bool _loading = true;
  String? _avatarUrl;
  String? _avatarData; // base64 avatar (tanpa Storage)
  // Semua level badge yang tersedia
  static const List<int> _allBadgeLevels = <int>[10, 25, 45, 65, 75, 100];

  @override
  void initState() {
    super.initState();
    _load();
  }

  ImageProvider? _buildImageProvider({bool preview = false, String? tempData, bool useBase64 = false}) {
    // If tempData provided with useBase64, interpret as base64 (for dialog preview)
    if (useBase64 && tempData != null && tempData.isNotEmpty) {
      try { return MemoryImage(base64Decode(tempData)); } catch (_) { return null; }
    }
    // Prefer base64 avatarData
    if (_avatarData != null && _avatarData!.isNotEmpty) {
      try { return MemoryImage(base64Decode(_avatarData!)); } catch (_) { return null; }
    }
    // Fallback to URL if exists (ke depan bisa dihapus bila full base64)
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }
    return null;
  }
  Future<void> _showPreviewDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large preview with ring
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _ringColorForBadge(_selectedBadge), width: 5),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _buildImageProvider(preview: true),
                  child: _buildImageProvider(preview: true) == null ? const Icon(Icons.person, color: Colors.black, size: 48) : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(_displayName?.isNotEmpty == true ? _displayName! : 'Guest User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); _showEditDialog(); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
              child: const Text('Edit Profil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog() async {
    final nameCtrl = TextEditingController(text: _displayName ?? '');
    String? tempAvatarUrl = _avatarUrl;
    int? tempBadge = _selectedBadge;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          final ImageProvider? imageProvider = _buildImageProvider(tempData: tempAvatarUrl, useBase64: true);
          return AlertDialog(
            title: const Text('Edit Profil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _ringColorForBadge(tempBadge), width: 5),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        backgroundImage: imageProvider,
                        child: imageProvider == null ? const Icon(Icons.person, color: Colors.black, size: 40) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final picker = ImagePicker();
                              final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
                              if (f == null) return;
                              final uid = FirebaseAuth.instance.currentUser?.uid;
                              if (uid == null) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi pengguna tidak ditemukan')));
                                return;
                              }
                              final bytes = await f.readAsBytes();
                              final b64 = base64Encode(bytes);
                              // Update sementara di dialog
                              setLocal(() => tempAvatarUrl = b64);
                              // Simpan ke Firestore sebagai base64 dan notifikasi UI
                              await FirebaseUserService.instance.setAvatarData(b64);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui')));
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan foto: $e')));
                            }
                          },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Ganti Foto'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: ctx,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Hapus Foto Profil'),
                                content: const Text('Apakah kamu yakin ingin menghapus foto profil?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Batal')),
                                  ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Hapus')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              setLocal(() => tempAvatarUrl = null);
                              await FirebaseUserService.instance.setAvatarData(null);
                              await FirebaseUserService.instance.setAvatarUrl(null);
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Hapus Foto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nama'),
                  const SizedBox(height: 6),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Nama panggilan')), 
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseUserService.instance.setDisplayName(nameCtrl.text.trim());
                  await FirebaseUserService.instance.setAvatarUrl(tempAvatarUrl);
                  if (!mounted) return;
                  setState(() {
                    _displayName = nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim();
                    _avatarUrl = tempAvatarUrl;
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _load() async {
    final storage = FirebaseUserService.instance;
    final name = await storage.getDisplayName();
    final badges = await storage.getBadges();
    final selected = await storage.getSelectedBadgeLevel();
    final avatar = await storage.getAvatarUrl();
    final avatarData = await storage.getAvatarData();
    setState(() {
      _displayName = name;
      _earnedBadges = badges;
      _selectedBadge = selected;
      _avatarUrl = avatar;
      _avatarData = avatarData;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
  
  Future<void> _confirmLogout() async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true) {
      await _logout();
    }
  }
  
  Future<void> _changePassword() async {
    final passOldCtrl = TextEditingController();
    final passNewCtrl = TextEditingController();
    final passConfCtrl = TextEditingController();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: passOldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password sekarang')),
            const SizedBox(height: 8),
            TextField(controller: passNewCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru')),
            const SizedBox(height: 8),
            TextField(controller: passConfCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi password baru')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final oldPass = passOldCtrl.text.trim();
    final newPass = passNewCtrl.text.trim();
    final confPass = passConfCtrl.text.trim();

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password baru minimal 6 karakter')));
      return;
    }
    if (newPass != confPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok')));
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada sesi pengguna')));
        return;
      }
      // Reauthenticate
      final email = user.email;
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email pengguna tidak ditemukan')));
        return;
      }
      final cred = EmailAuthProvider.credential(email: email, password: oldPass);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal mengubah password';
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') msg = 'Password sekarang salah';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
  }

  Future<void> _selectBadge(int? level) async {
    // Cegah memilih badge yang masih terkunci
    if (level != null && !_earnedBadges.contains(level)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Badge Lv$level masih terkunci. Selesaikan syaratnya dulu.')),
        );
      }
      return;
    }
    await FirebaseUserService.instance.setSelectedBadgeLevel(level);
    if (!mounted) return;
    setState(() => _selectedBadge = level);
  }

  

  Color _ringColorForBadge(int? level) {
    if (level == null) return Colors.grey.shade300;
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

  bool _isUnlocked(int level) => _earnedBadges.contains(level);

  String _requirementText(int level) {
    // Kamu bisa menyesuaikan syarat berikut sesuai logika gamifikasi di app.
    // Untuk saat ini tampilkan syarat generik.
    return 'Capai Badge Level $level untuk membuka';
  }

  Widget _avatarPreview() {
    final ImageProvider? imageProvider = _buildImageProvider();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _ringColorForBadge(_selectedBadge), width: 4),
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        backgroundImage: imageProvider,
        child: imageProvider == null ? const Icon(Icons.person, color: Colors.black) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 64,
        title: const Text('Profile'),
      ),
      // Drawer removed; profile accessible via AppBar avatar.
      body: Container(
        color: const Color(0xFFF0F0F0),
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Edge-to-edge layout: horizontal padding handled at ListView level
            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 16),
              children: [
                // Top profile card with rounded corners
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      InkWell(onTap: _showPreviewDialog, child: _avatarPreview()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_displayName?.isNotEmpty == true ? _displayName! : 'Guest User',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Keamanan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Ganti Password'),
                        onTap: _changePassword,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Border Badge Avatar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('None'),
                            selected: _selectedBadge == null,
                            onSelected: (_) => _selectBadge(null),
                            backgroundColor: Colors.white,
                            selectedColor: Colors.white,
                            labelStyle: const TextStyle(color: Colors.black),
                            shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                          ),
                          // Tampilkan semua badge. Yang belum didapat ditandai terkunci.
                          ..._allBadgeLevels.map((b) {
                            final bool unlocked = _isUnlocked(b);
                            final bool selected = _selectedBadge == b;
                            return ChoiceChip(
                              avatar: unlocked ? null : const Icon(Icons.lock, size: 16),
                              label: Text('Lv$b'),
                              selected: selected,
                              onSelected: unlocked ? (_) => _selectBadge(b) : (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lv$b terkunci. ${_requirementText(b)}')),
                                );
                              },
                              backgroundColor: unlocked ? Colors.white : Colors.grey.shade200,
                              selectedColor: Colors.white,
                              labelStyle: TextStyle(color: unlocked ? Colors.black : Colors.black54),
                              shape: StadiumBorder(side: BorderSide(color: unlocked ? Colors.black : Colors.grey.shade400)),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _earnedBadges.isEmpty
                            ? 'Kamu belum memiliki badge. Selesaikan misi untuk membuka.'
                            : 'Pilih level badge untuk menjadi border avatar. Badge yang terkunci ditandai ikon gembok.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lainnya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: _confirmLogout,
                      )
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
