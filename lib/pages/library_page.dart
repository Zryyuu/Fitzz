import 'package:flutter/material.dart';
// import 'package:fitzz/widgets/app_drawer.dart';
import 'package:fitzz/widgets/bottom_nav.dart';
import 'package:fitzz/widgets/profile_avatar_button.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.withBottomNav = true});

  final bool withBottomNav;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool _ready = false; // keep consistent UX with other tabs

  // Sumber data gerakan: judul, deskripsi singkat, dan path asset GIF/JPG
  final List<Map<String, String>> _moves = const [
    {
      'title': 'Push Up',
      'desc': 'Dorong badan dari lantai. Jaga punggung lurus dan core aktif.',
      'asset': 'Assets/Push-Up.gif',
    },
    {
      'title': 'Plank',
      'desc': 'Tahan badan di posisi plank. Jaga punggung lurus dan core aktif.',
      'asset': 'Assets/Plank.png',
    },
    {
      'title': 'Sit Up',
      'desc': 'Angkat badan dari posisi telentang. Gunakan otot perut, bukan leher.',
      'asset': 'Assets/Sit-up.gif',
    },
    {
      'title': 'Squat',
      'desc': 'Tekuk lutut dan dorong pinggul ke belakang. Tumit tetap menapak.',
      'asset': 'Assets/Squat.gif',
    },
    {
      'title': 'Lunge',
      'desc': 'Langkah satu kaki ke depan dan turunkan lutut belakang mendekati lantai.',
      'asset': 'Assets/Lunge.gif',
    },
    {
      'title': 'Burpee',
      'desc': 'Kombinasi squat, plank, dan lompatan. Gerakan full body yang intens.',
      'asset': 'Assets/Burpee.gif',
    },
    {
      'title': 'Dip (Kursi)',
      'desc': 'Gunakan kursi stabil. Turunkan tubuh dengan siku menekuk ke belakang.',
      'asset': 'Assets/Dip.gif',
    },
    {
      'title': 'Jumping Jack',
      'desc': 'Buka-tutup kaki dan tangan sambil melompat. Ritme konstan.',
      'asset': 'Assets/Jumping-jack.gif',
    },
    {
      'title': 'High Knees',
      'desc': 'Angkat lutut setinggi pinggang secara bergantian, gerak cepat.',
      'asset': 'Assets/Highknee.gif',
    },
    {
      'title': 'Mountain Climber',
      'desc': 'Dari posisi plank, tarik lutut ke dada secara bergantian.',
      'asset': 'Assets/Mountainclimb.gif',
    },
    {
      'title': 'Jump Squat',
      'desc': 'Lakukan squat lalu dorong ke atas dengan lompatan lembut.',
      'asset': 'Assets/Jumpsquat.gif',
    },
    {
      'title': 'Wall Sit',
      'desc': 'Sandarkan punggung ke dinding, lutut 90°. Tahan posisi.',
      'asset': 'Assets/Walllsit.jpeg',
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_ready) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Library Gerakan'),
          actions: const [
            ProfileAvatarButton(radius: 18),
          ],
        ),
        bottomNavigationBar: widget.withBottomNav ? const AppBottomNav(currentIndex: 3) : null,
        body: const SizedBox.expand(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Library Gerakan'),
        actions: const [
          ProfileAvatarButton(radius: 18),
        ],
      ),
      bottomNavigationBar: widget.withBottomNav ? const AppBottomNav(currentIndex: 3) : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _moves.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final a = _moves[i];
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media preview (GIF/JPG)
                    AspectRatio(
                      aspectRatio: 16/9,
                      child: Image.asset(
                        a['asset']!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEDEDED)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.fitness_center_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a['title']!, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(a['desc']!, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
