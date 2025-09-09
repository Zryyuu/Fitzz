import 'package:flutter/material.dart';
import 'package:fitzz/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:fitzz/widgets/app_drawer.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _loading = true;
  int _strike = 0;
  String _lastDate = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = LocalStorageService.instance;
    final strike = await storage.getStrike();
    final last = await storage.getLastCompletedDate() ?? '-';
    if (!mounted) return;
    setState(() {
      _strike = strike;
      _lastDate = last;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Progress'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text('Strike: $_strike hari', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Terakhir selesai: $_lastDate'),
                Text('Hari ini: $today'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grafik Mingguan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 6 ? 0 : 6),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: index < (_strike % 7) ? Colors.black : const Color(0xFFE6E6E6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Sen'),
                    Text('Sel'),
                    Text('Rab'),
                    Text('Kam'),
                    Text('Jum'),
                    Text('Sab'),
                    Text('Min'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
