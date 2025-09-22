import 'package:flutter/material.dart';
// import 'package:fitzz/widgets/app_drawer.dart';
import 'package:fitzz/widgets/bottom_nav.dart';
import 'package:fitzz/widgets/top_status_header.dart';

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
    Future.microtask(() async {
      if (!mounted) return;
      setState(() { _ready = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_ready) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(96),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: const TopStatusHeader(),
              ),
            ),
          ),
        ),
        bottomNavigationBar: widget.withBottomNav ? const AppBottomNav(currentIndex: 3) : null,
        body: const SizedBox.expand(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: const TopStatusHeader(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.withBottomNav ? const AppBottomNav(currentIndex: 3) : null,
      body: Container(
        color: const Color(0xFFF0F0F0),
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Full-width black bar behind the top white section
            Positioned(top: 0, left: 0, right: 0, child: Container(height: 48, color: Colors.black)),
            // Content list sits below; header will be drawn on top to avoid bleed-through
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 600;
                const double stickyHeaderHeight = 68; // approx height of sticky header
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16).copyWith(top: stickyHeaderHeight + 16),
                  itemCount: _moves.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final a = _moves[i];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 16),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Media preview (GIF/JPG) - smaller height and tappable for Inspect
                            GestureDetector(
                              onTap: () => _openInspect(context, a['asset']!, a['title'] ?? 'Gerakan'),
                              child: Container(
                                color: const Color(0xFFF7F7F7),
                                alignment: Alignment.center,
                                child: SizedBox(
                                  height: 160,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      a['asset']!,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                      filterQuality: FilterQuality.medium,
                                      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEDEDED)),
                                    ),
                                  ),
                                ),
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
                      ),
                    );
                  },
                );
              },
            ),
            // Sticky header card with rounded top corners (painted on top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Text('Library Gerakan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openInspect(BuildContext context, String assetPath, String title) async {
  await showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                    Positioned(
                      right: 0,
                      child: IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Interactive viewer to zoom/pan the animation/image
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('Gagal memuat media')),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
