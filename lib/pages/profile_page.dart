import 'package:flutter/material.dart';
import 'package:fitzz/services/storage_service.dart';
import 'package:fitzz/widgets/app_drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

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
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _load();
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
                  backgroundImage: _avatarBase64 == null ? null : MemoryImage(base64Decode(_avatarBase64!)),
                  child: _avatarBase64 == null ? const Icon(Icons.person, color: Colors.black, size: 48) : null,
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
    String? tempAvatar = _avatarBase64;
    int? tempBadge = _selectedBadge;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          final imageProvider = tempAvatar == null ? null : MemoryImage(base64Decode(tempAvatar!));
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
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
                        if (f == null) return;
                        final b64 = base64Encode(await f.readAsBytes());
                        setLocal(() => tempAvatar = b64);
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Ganti Foto'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
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
                  await LocalStorageService.instance.setDisplayName(nameCtrl.text.trim());
                  await LocalStorageService.instance.setAvatarBase64(tempAvatar);
                  if (!mounted) return;
                  setState(() {
                    _displayName = nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim();
                    _avatarBase64 = tempAvatar;
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
    final storage = LocalStorageService.instance;
    final name = await storage.getDisplayName();
    final badges = await storage.getBadges();
    final selected = await storage.getSelectedBadgeLevel();
    final avatar = await storage.getAvatarBase64();
    setState(() {
      _displayName = name;
      _earnedBadges = badges;
      _selectedBadge = selected;
      _avatarBase64 = avatar;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await LocalStorageService.instance.setLoggedIn(false);
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
  
  Future<void> _changePassword() async {
    final passOldCtrl = TextEditingController();
    final passNewCtrl = TextEditingController();
    final passConfCtrl = TextEditingController();
    final currentSaved = await LocalStorageService.instance.getPassword();
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
            TextField(controller: passConfCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi password')),
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
    if ((currentSaved ?? '') != (passOldCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password sekarang salah')));
      return;
    }
    if (passNewCtrl.text.isEmpty || passNewCtrl.text != passConfCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok')));
      return;
    }
    await LocalStorageService.instance.setPassword(passNewCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
  }

  Future<void> _selectBadge(int? level) async {
    await LocalStorageService.instance.setSelectedBadgeLevel(level);
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

  Widget _avatarPreview() {
    final imageProvider = _avatarBase64 == null
        ? null
        : MemoryImage(base64Decode(_avatarBase64!));
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                GestureDetector(onTap: _showPreviewDialog, child: _avatarPreview()),
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
                IconButton(onPressed: _showEditDialog, icon: const Icon(Icons.edit), tooltip: 'Edit Profil')
              ],
            ),
          ),
          // Hapus kartu 'Ganti Foto Profil' karena edit dipindah ke popup
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
                Text('Cincin Badge Avatar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                    if (_earnedBadges.isNotEmpty)
                      ..._earnedBadges.map((b) => ChoiceChip(
                            label: Text('Lv$b'),
                            selected: _selectedBadge == b,
                            onSelected: (_) => _selectBadge(b),
                            backgroundColor: Colors.white,
                            selectedColor: Colors.white,
                            labelStyle: const TextStyle(color: Colors.black),
                            shape: const StadiumBorder(side: BorderSide(color: Colors.black)),
                          )),
                  ],
                ),
                const SizedBox(height: 8),
                if (_earnedBadges.isEmpty)
                  Text('Kamu belum memiliki badge.', style: theme.textTheme.bodySmall)
                else
                  Text('Pilih level badge untuk menjadi border avatar.', style: theme.textTheme.bodySmall),
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
                  onTap: _logout,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
