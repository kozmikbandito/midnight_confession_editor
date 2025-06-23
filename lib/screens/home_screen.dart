import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// DÜZELTME: dart:html yerine platformdan bağımsız url_launcher kullanıyoruz.
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _caseList = [];
  bool _isLoadingCases = true;
  Map<String, dynamic>? _selectedCase;
  
  List<Map<String, dynamic>> _characterList = [];
  bool _isCharactersLoading = false;

  List<Map<String, dynamic>> _evidenceList = [];
  bool _isEvidenceLoading = false;
  
  List<Map<String, dynamic>> _informationList = [];
  bool _isInformationLoading = false;

  final _titleController = TextEditingController();
  final _briefController = TextEditingController();

  // --- Veri Çekme Fonksiyonları ---

  Future<void> _fetchCases() async {
    setState(() { _isLoadingCases = true; });
    try {
      final data = await _supabase.from('cases').select().order('created_at', ascending: false);
      if (mounted) setState(() { _caseList = data; _isLoadingCases = false; });
    } catch (e) {
      _showErrorSnackBar("Vakalar çekilirken hata oluştu: $e");
      if (mounted) setState(() { _isLoadingCases = false; });
    }
  }
  
  Future<void> _fetchCharacters(int caseId) async {
    setState(() { _isCharactersLoading = true; });
    try {
      final data = await _supabase.from('characters').select().eq('case_id', caseId).order('created_at');
      if (mounted) setState(() { _characterList = data; _isCharactersLoading = false; });
    } catch (e) {
      _showErrorSnackBar("Karakterler çekilirken hata oluştu: $e");
       if (mounted) setState(() { _isCharactersLoading = false; });
    }
  }

  Future<void> _fetchEvidence(int caseId) async {
    setState(() { _isEvidenceLoading = true; });
    try {
      final data = await _supabase.from('evidence').select().eq('case_id', caseId).order('created_at');
      if (mounted) setState(() { _evidenceList = data; _isEvidenceLoading = false; });
    } catch (e) {
      _showErrorSnackBar("Kanıtlar çekilirken hata oluştu: $e");
      if (mounted) setState(() { _isEvidenceLoading = false; });
    }
  }
  
  Future<void> _fetchInformation(String characterId) async {
    setState(() { _isInformationLoading = true; });
    try {
      final data = await _supabase.from('information').select('*, triggers(*, evidence(name))').eq('character_id', characterId);
      if (mounted) setState(() { _informationList = data; _isInformationLoading = false; });
    } catch (e) {
      _showErrorSnackBar("Bilgi blokları çekilirken hata oluştu: $e");
      if (mounted) setState(() { _isInformationLoading = false; });
    }
  }
  
  // --- Veri Ekleme / Silme / Dışa Aktarma ---

  Future<void> _addCase() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) { _showErrorSnackBar("Vaka başlığı boş olamaz!", isWarning: true); return; }
    try {
      await _supabase.from('cases').insert({'title': title, 'brief': _briefController.text.trim()});
      _titleController.clear(); _briefController.clear();
      await _fetchCases();
      _showSuccessSnackBar("Vaka başarıyla kaydedildi!");
    } catch (e) {
      _showErrorSnackBar("Kayıt sırasında bir hata oluştu: $e");
    }
  }

  Future<void> _deleteCase(int caseId) async {
    try {
      await _supabase.from('cases').delete().match({'id': caseId});
      setState(() { _selectedCase = null; _characterList = []; _evidenceList = []; });
      await _fetchCases();
      _showSuccessSnackBar("Vaka başarıyla silindi.", color: Colors.blueGrey);
    } catch(e) {
      _showErrorSnackBar("Vaka silinirken bir hata oluştu: $e");
    }
  }

  Future<void> _exportCaseAsJson() async {
    if (_selectedCase == null) return;
    try {
      final fullCaseData = await _supabase.from('cases').select('*, characters(*, information(*, triggers(*, evidence(id, name)))), evidence(*)').eq('id', _selectedCase!['id']).single();
      const jsonEncoder = JsonEncoder.withIndent('  ');
      final prettyJson = jsonEncoder.convert(fullCaseData);
      
      final bytes = utf8.encode(prettyJson);
      final blob = base64Encode(bytes);
      final url = 'data:application/json;base64,$blob';
      await launchUrl(Uri.parse(url), webOnlyWindowName: 'case_${_selectedCase!['id']}.json');

    } catch (e) {
      _showErrorSnackBar("Vaka dışa aktarılırken hata oluştu: $e");
    }
  }

  // --- Diyalog Gösterme Fonksiyonları ---
  
  void _showAddCharacterDialog() {
    final nameController = TextEditingController();
    final promptController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Yeni Karakter Ekle'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Karakter Adı')), const SizedBox(height: 8), TextField(controller: promptController, decoration: const InputDecoration(labelText: 'Temel Kişilik (Base Prompt)'), maxLines: 3)]), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')), ElevatedButton(onPressed: () async { final name = nameController.text.trim(); if (name.isEmpty) return; try { await _supabase.from('characters').insert({'case_id': _selectedCase!['id'], 'name': name, 'base_prompt': promptController.text.trim(),}); await _fetchCharacters(_selectedCase!['id']); if (!context.mounted) return; Navigator.of(context).pop(); } catch(e) { _showErrorSnackBar("Karakter eklenemedi: $e"); }}, child: const Text('Kaydet'))]));
  }
  
  void _showAddEvidenceDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Yeni Kanıt Ekle'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Kanıt Adı')), const SizedBox(height: 8), TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 3)]), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')), ElevatedButton(onPressed: () async { final name = nameController.text.trim(); if (name.isEmpty) return; try { await _supabase.from('evidence').insert({'case_id': _selectedCase!['id'], 'name': name, 'description': descriptionController.text.trim(),}); await _fetchEvidence(_selectedCase!['id']); if (!context.mounted) return; Navigator.of(context).pop(); } catch(e) { _showErrorSnackBar("Kanıt eklenemedi: $e"); }}, child: const Text('Kaydet'))]));
  }
  
  void _showCharacterDetailDialog(Map<String, dynamic> character) async {
    await _fetchInformation(character['id']);
    if (!mounted) return;
    showDialog(context: context, builder: (context) { 
      return StatefulBuilder(builder: (context, setDialogState) { 
        return AlertDialog(
          title: Text("'${character['name']}' Detayları"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Temel Kişilik:", style: Theme.of(context).textTheme.titleSmall),
                Text(character['base_prompt'] ?? 'Girilmemiş'),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Saklanan Bilgiler (Sırlar)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Yeni Sır Ekle"),
                      onPressed: () => _showAddInformationDialog(character['id'], (newState) {
                        setDialogState(() {
                          _informationList = newState;
                        });
                      }),
                    )
                  ]
                ),
                Expanded(
                  child: _isInformationLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : ListView.builder(
                        itemCount: _informationList.length,
                        itemBuilder: (context, index) {
                          final info = _informationList[index];
                          final triggers = info['triggers'] as List;
                          final triggerEvidence = triggers.isNotEmpty ? triggers[0]['evidence'] : null;
                          return Card(
                            child: ExpansionTile(
                              title: Text(info['description'] ?? 'Açıklama yok'),
                              subtitle: triggerEvidence != null 
                                ? Chip(
                                    avatar: const Icon(Icons.vpn_key_outlined, size: 16),
                                    label: Text('Tetikleyici: ${triggerEvidence['name']}'),
                                    visualDensity: VisualDensity.compact
                                  ) 
                                : const Chip(
                                    label: Text('Tetikleyici atanmamış'),
                                    visualDensity: VisualDensity.compact
                                  ),
                              children: [
                                ListTile(title: const Text("Kilitli Komut"), subtitle: Text(info['locked_prompt'] ?? '')),
                                ListTile(title: const Text("Açık Komut"), subtitle: Text(info['unlocked_prompt'] ?? '')),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Kapat")),
          ],
        );
      });
    });
  }

  void _showAddInformationDialog(String characterId, Function(List<Map<String, dynamic>>) onInfoAdded) {
    final descController = TextEditingController();
    final lockedController = TextEditingController();
    final unlockedController = TextEditingController();
    String? selectedEvidenceId;
    showDialog(context: context, builder: (context) { 
      return AlertDialog(
        title: const Text("Yeni Sır Ekle"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Sırrın Açıklaması (Tasarımcı Notu)')),
              TextField(controller: lockedController, decoration: const InputDecoration(labelText: 'Kilitli Durum Komutu (Locked Prompt)')),
              TextField(controller: unlockedController, decoration: const InputDecoration(labelText: 'Açık Durum Komutu (Unlocked Prompt)')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                hint: const Text("Tetikleyici Kanıtı Seç"),
                isExpanded: true,
                items: _evidenceList.map<DropdownMenuItem<String>>((evidence) {
                  return DropdownMenuItem(
                    value: evidence['id'] as String,
                    child: Text(evidence['name'])
                  );
                }).toList(),
                onChanged: (value) {
                  selectedEvidenceId = value;
                },
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("İptal")),
          ElevatedButton(
            child: const Text("Sırrı ve Tetikleyiciyi Kaydet"),
            onPressed: () async {
              final desc = descController.text.trim();
              if (desc.isEmpty || selectedEvidenceId == null) {
                _showErrorSnackBar("Açıklama ve Tetikleyici Kanıt seçilmelidir!", isWarning: true);
                return;
              }
              try {
                final newInfo = await _supabase.from('information').insert({'character_id': characterId, 'description': desc, 'locked_prompt': lockedController.text.trim(), 'unlocked_prompt': unlockedController.text.trim()}).select().single();
                await _supabase.from('triggers').insert({'information_id': newInfo['id'], 'evidence_id': selectedEvidenceId});
                await _fetchInformation(characterId);
                onInfoAdded(_informationList);
                if (context.mounted) Navigator.of(context).pop();
              } catch(e) { _showErrorSnackBar("Sır eklenemedi: $e"); }
            },
          ),
        ],
      );
    });
  }
  
  // --- UI İnşa Fonksiyonları ---

  @override
  void initState() { super.initState(); _caseList = []; _fetchCases(); }
  @override
  void dispose() { _titleController.dispose(); _briefController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Midnight Confession - Editör'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Yeni Vaka Oluştur',
            onPressed: () { setState(() { _selectedCase = null; _characterList = []; _evidenceList = []; }); }
          )
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black12,
              child: _isLoadingCases 
                ? const Center(child: CircularProgressIndicator()) 
                : ListView.builder(
                    itemCount: _caseList.length,
                    itemBuilder: (context, index) {
                      final vaka = _caseList[index];
                      final isSelected = _selectedCase != null && _selectedCase!['id'] == vaka['id'];
                      return ListTile(
                        tileColor: isSelected ? Colors.indigo.withAlpha(77) : null,
                        title: Text(vaka['title']),
                        subtitle: Text('ID: ${vaka['id']}'),
                        onTap: () {
                          setState(() { _selectedCase = vaka; });
                          _fetchCharacters(vaka['id']);
                          _fetchEvidence(vaka['id']);
                        },
                      );
                    },
                  )
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 5,
            child: _selectedCase == null ? _buildNewCaseForm() : _buildCaseDetailView()
          ),
        ],
      ),
    );
  }

  Widget _buildNewCaseForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yeni Vaka Oluştur', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Vaka Başlığı', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _briefController, decoration: const InputDecoration(labelText: 'Kısa Açıklama (Brief)', border: OutlineInputBorder()), maxLines: 5),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _addCase,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16), textStyle: const TextStyle(fontSize: 16)),
            child: const Text('Vakayı Kaydet')
          )
        ]
      )
    );
  }

  Widget _buildCaseDetailView() {
    final vaka = _selectedCase!;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  vaka['title'],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                )
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Vakayı Sil',
                onPressed: () => _showDeleteConfirmation(vaka)
              )
            ]
          ),
          const Divider(height: 20),
          Text(vaka['brief'] ?? 'Bu vaka için bir açıklama girilmemiş.', style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.grey)),
          const Divider(height: 30),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCharacterColumn()),
                const VerticalDivider(width: 30),
                Expanded(child: _buildEvidenceColumn())
              ]
            )
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _exportCaseAsJson,
              icon: const Icon(Icons.download_for_offline_outlined),
              label: const Text("Vakayı JSON Olarak Dışa Aktar"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)
              )
            )
          )
        ]
      )
    );
  }

  Widget _buildCharacterColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Karakterler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            TextButton.icon(icon: const Icon(Icons.add), label: const Text('Ekle'), onPressed: _showAddCharacterDialog)
          ]
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isCharactersLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _characterList.isEmpty 
              ? Center(child: Text('Karakter eklenmemiş.', style: TextStyle(color: Colors.grey.shade400))) 
              : ListView.builder(
                  itemCount: _characterList.length,
                  itemBuilder: (context, index) {
                    final character = _characterList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _showCharacterDetailDialog(character),
                        leading: CircleAvatar(child: Text(character['name'][0])),
                        title: Text(character['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(character['base_prompt'] ?? 'Kişilik bilgisi yok.', overflow: TextOverflow.ellipsis)
                      )
                    );
                  }
                )
        )
      ]
    );
  }

  Widget _buildEvidenceColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Kanıtlar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            TextButton.icon(icon: const Icon(Icons.add), label: const Text('Ekle'), onPressed: _showAddEvidenceDialog)
          ]
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isEvidenceLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _evidenceList.isEmpty 
              ? Center(child: Text('Kanıt eklenmemiş.', style: TextStyle(color: Colors.grey.shade400))) 
              : ListView.builder(
                  itemCount: _evidenceList.length,
                  itemBuilder: (context, index) {
                    final evidence = _evidenceList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.description_outlined)),
                        title: Text(evidence['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(evidence['description'] ?? 'Açıklama yok.', overflow: TextOverflow.ellipsis)
                      )
                    );
                  }
                )
        )
      ]
    );
  }
  
  void _showDeleteConfirmation(Map<String, dynamic> vaka) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Vakayı Sil'), content: Text('"${vaka['title']}" adlı vakayı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve vakaya bağlı TÜM KARAKTERLER, KANITLAR ve BİLGİLER de silinir.'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')), TextButton(onPressed: () {Navigator.of(context).pop(); _deleteCase(vaka['id']);}, child: const Text('SİL', style: TextStyle(color: Colors.red)))]));
  }

  void _showErrorSnackBar(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isWarning ? Colors.orange : Colors.red));
  }

  void _showSuccessSnackBar(String message, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
