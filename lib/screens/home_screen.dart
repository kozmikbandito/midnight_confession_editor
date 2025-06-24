// lib/screens/home_screen.dart - YENİ VE TEMİZ HALİ
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'olay_tahtasi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _caseList = [];
  bool _isLoadingCases = true;
  Map<String, dynamic>? _selectedCase; // Sadece seçimi takip etmek için

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  Future<void> _fetchCases() async {
    setState(() { _isLoadingCases = true; });
    try {
      final data = await _supabaseService.fetchCases();
      if (!mounted) return;
      setState(() { _caseList = data; });
    } catch (e) {
      // TODO: Hata durumunda kullanıcıya bir mesaj gösterilebilir.
    } finally {
      if (!mounted) return;
      setState(() { _isLoadingCases = false; });
    }
  }

  void _handleSelectCase(Map<String, dynamic> vaka) {
    setState(() { _selectedCase = vaka; });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OlayTahtasiScreen(selectedCase: vaka),
      ),
      // Olay Tahtası ekranından geri dönüldüğünde seçimi temizle
    ).then((_) => setState(() { _selectedCase = null; }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Midnight Confession - Vaka Seçimi'),
      ),
      body: Row(
        children: [
          // Sol Panel: Vaka Listesi
          Expanded(
            flex: 2,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(50),
              child: _isLoadingCases
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _caseList.length,
                      itemBuilder: (context, index) {
                        final vaka = _caseList[index];
                        final isSelected = _selectedCase != null && _selectedCase!['id'] == vaka['id'];
                        return ListTile(
                          tileColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                          title: Text(vaka['title']),
                          subtitle: Text('ID: ${vaka['id']}'),
                          onTap: () => _handleSelectCase(vaka),
                        );
                      },
                    ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Sağ Panel: Karşılama Ekranı
          const Expanded(
            flex: 5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rule_folder_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Düzenlemek için bir vaka seçin.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
