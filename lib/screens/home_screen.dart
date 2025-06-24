import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:html' as html;

// YENİ: Oluşturduğumuz servisleri ve widget'ları import ediyoruz.
import '../services/supabase_service.dart';
import '../services/dialog_service.dart';
import '../widgets/case_detail_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Servis sınıflarımızdan birer nesne oluşturuyoruz.
  final SupabaseService _supabaseService = SupabaseService();
  final DialogService _dialogService = DialogService();

  // State Değişkenleri
  List<Map<String, dynamic>> _caseList = [];
  bool _isLoadingCases = true;
  Map<String, dynamic>? _selectedCase;

  List<Map<String, dynamic>> _characterList = [];
  bool _isCharactersLoading = false;

  List<Map<String, dynamic>> _evidenceList = [];
  bool _isEvidenceLoading = false;

  List<Map<String, dynamic>> _locationsList = [];
  bool _isLoadingLocations = false;

  // Bilgi blokları ve diyaloglar için state'ler burada kalmaya devam ediyor,
  // çünkü bunlar doğrudan bu ekranın anlık durumuyla ilgili.
  List<Map<String, dynamic>> _informationList = [];
  bool _isInformationLoading = false;

  final _titleController = TextEditingController();
  final _briefController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _handleFetchCases();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _briefController.dispose();
    super.dispose();
  }

  // --- Ana Mantık Fonksiyonları (Handler'lar) ---
  // Bu fonksiyonlar artık arayüz (DialogService) ve veri (SupabaseService) arasında köprü görevi görüyor.

  Future<void> _handleFetchCases() async {
    setState(() { _isLoadingCases = true; });
    try {
      final data = await _supabaseService.fetchCases();
      if (mounted) setState(() { _caseList = data; });
    } catch (e) {
      _showErrorSnackBar("Vakalar çekilirken hata oluştu: $e");
    } finally {
      if (mounted) setState(() { _isLoadingCases = false; });
    }
  }

  Future<void> _handleSelectCase(Map<String, dynamic> vaka) async {
    setState(() {
      _selectedCase = vaka;
      // Diğer listeleri temizleyerek eski verilerin görünmesini engelle
      _characterList = [];
      _evidenceList = [];
      _locationsList = [];
    });
    final caseId = vaka['id'];
    // Tüm verileri aynı anda, paralel olarak çekiyoruz.
    await Future.wait([
      _handleFetchCharacters(caseId),
      _handleFetchEvidence(caseId),
      _handleFetchLocations(caseId),
    ]);
  }

  Future<void> _handleFetchCharacters(int caseId) async {
    setState(() { _isCharactersLoading = true; });
    try {
      final data = await _supabaseService.fetchCharacters(caseId);
      if (mounted) setState(() { _characterList = data; });
    } catch (e) {
      _showErrorSnackBar("Karakterler çekilirken hata oluştu: $e");
    } finally {
      if (mounted) setState(() { _isCharactersLoading = false; });
    }
  }

  Future<void> _handleFetchEvidence(int caseId) async {
    setState(() { _isEvidenceLoading = true; });
    try {
      final data = await _supabaseService.fetchEvidence(caseId);
      if (mounted) setState(() { _evidenceList = data; });
    } catch (e) {
      _showErrorSnackBar("Kanıtlar çekilirken hata oluştu: $e");
    } finally {
      if (mounted) setState(() { _isEvidenceLoading = false; });
    }
  }

  Future<void> _handleFetchLocations(int caseId) async {
    setState(() { _isLoadingLocations = true; });
    try {
      final data = await _supabaseService.fetchLocations(caseId);
      if (mounted) setState(() { _locationsList = data; });
    } catch (e) {
      _showErrorSnackBar("Mekanlar çekilirken hata oluştu: $e");
    } finally {
      if (mounted) setState(() { _isLoadingLocations = false; });
    }
  }

  Future<void> _handleAddCase() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showErrorSnackBar("Vaka başlığı boş olamaz!", isWarning: true);
      return;
    }
    try {
      await _supabaseService.addCase(title, _briefController.text.trim());
      _titleController.clear();
      _briefController.clear();
      await _handleFetchCases();
      _showSuccessSnackBar("Vaka başarıyla kaydedildi!");
    } catch (e) {
      _showErrorSnackBar("Kayıt sırasında bir hata oluştu: $e");
    }
  }

  Future<void> _handleDeleteCase() async {
    if (_selectedCase == null) return;
    final confirmed = await _dialogService.showConfirmationDialog(
        context: context,
        title: 'Vakayı Sil',
        content: '"${_selectedCase!['title']}" adlı vakayı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve vakaya bağlı TÜM veriler de silinir.'
    );

    if (confirmed) {
      try {
        await _supabaseService.deleteCase(_selectedCase!['id']);
        setState(() {
          _selectedCase = null;
          _characterList = [];
          _evidenceList = [];
          _locationsList = [];
        });
        await _handleFetchCases();
        _showSuccessSnackBar("Vaka başarıyla silindi.", color: Colors.blueGrey);
      } catch(e) {
        _showErrorSnackBar("Vaka silinirken bir hata oluştu: $e");
      }
    }
  }

  Future<void> _handleAddCharacter() async {
    if (_selectedCase == null) return;
    final result = await _dialogService.showAddCharacterDialog(context);
    if(result != null) {
      try {
        await _supabaseService.addCharacter(_selectedCase!['id'], result['name']!, result['base_prompt']!);
        await _handleFetchCharacters(_selectedCase!['id']);
      } catch (e) {
        _showErrorSnackBar("Karakter eklenemedi: $e");
      }
    }
  }

  Future<void> _handleAddLocation() async {
    if (_selectedCase == null) return;
    final result = await _dialogService.showAddLocationDialog(context);
    if(result != null) {
      try {
        await _supabaseService.addLocation(_selectedCase!['id'], result['name']!, result['description']!);
        await _handleFetchLocations(_selectedCase!['id']);
      } catch (e) {
        _showErrorSnackBar("Mekan eklenemedi: $e");
      }
    }
  }

  Future<void> _handleExportCase() async {
    if (_selectedCase == null) return;
    try {
      final fullCaseData = await _supabaseService.getFullCaseDataForExport(_selectedCase!['id']);
      const jsonEncoder = JsonEncoder.withIndent('  ');
      final prettyJson = jsonEncoder.convert(fullCaseData);

      final bytes = utf8.encode(prettyJson);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'case_${_selectedCase!['id']}.json';

      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

    } catch (e) {
      _showErrorSnackBar("Vaka dışa aktarılırken hata oluştu: $e");
    }
  }

  // GÜNCELLEME: Artık DialogService ve SupabaseService'i kullanıyoruz.
  Future<void> _handleEditEvidence(Map<String, dynamic> evidence) async {
    if (_selectedCase == null) return;
    final result = await _dialogService.showEditEvidenceDialog(
      context: context,
      evidence: evidence,
      locations: _locationsList,
    );
    if(result != null) {
      try {
        await _supabaseService.saveEvidence(_selectedCase!['id'], result);
        await _handleFetchEvidence(_selectedCase!['id']);
      } catch (e) {
        _showErrorSnackBar("Kanıt kaydedilemedi: $e");
      }
    }
  }

  // GÜNCELLEME: Artık DialogService ve SupabaseService'i kullanıyoruz.
  Future<void> _handleSetCulprit() async {
    if (_selectedCase == null) return;
    final result = await _dialogService.showSetCulpritDialog(
        context: context,
        characters: _characterList,
        currentCulpritId: _selectedCase!['culprit_character_id']
    );

    if (result != null) {
      try {
        final updatedCase = await _supabaseService.setCulprit(_selectedCase!['id'], result);
        setState(() {
          _selectedCase = updatedCase;
        });
        _showSuccessSnackBar("Suçlu başarıyla atandı!");
      } catch (e) {
        _showErrorSnackBar("Suçlu atanırken bir hata oluştu: $e");
      }
    }
  }

  // Henüz yeni servisleri kullanmayan diyaloglar burada kalabilir veya taşınabilir.
  // Bu, projenin ilerleyen aşamalarında karar verilecek bir detaydır.
  // Şimdilik bu fonksiyonları olduğu gibi bırakıyoruz.
  void _showCharacterDetailDialog(Map<String, dynamic> character) {
    // Bu fonksiyonun içeriği DialogService'e taşınabilir.
  }

  // --- UI İnşa Fonksiyonları ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Midnight Confession - Editör'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Yeni Vaka Oluştur',
            onPressed: () {
              setState(() { _selectedCase = null; });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sol Panel: Vaka Listesi
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
                    onTap: () => _handleSelectCase(vaka),
                  );
                },
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Sağ Panel: Detaylar veya Yeni Vaka Formu
          Expanded(
            flex: 5,
            child: _selectedCase == null
                ? _buildNewCaseForm()
                : CaseDetailView(
              selectedCase: _selectedCase!,
              characterList: _characterList,
              isCharactersLoading: _isCharactersLoading,
              evidenceList: _evidenceList,
              isEvidenceLoading: _isEvidenceLoading,
              locationsList: _locationsList,
              isLoadingLocations: _isLoadingLocations,
              onSetCulprit: _handleSetCulprit,
              onDeleteCase: _handleDeleteCase,
              onExportCase: _handleExportCase,
              onAddCharacter: _handleAddCharacter,
              onEditEvidence: _handleEditEvidence,
              onAddLocation: _handleAddLocation,
              onShowCharacterDetail: _showCharacterDetailDialog,
            ),
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
            onPressed: _handleAddCase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
            child: const Text('Vakayı Kaydet'),
          )
        ],
      ),
    );
  }

  // --- Yardımcı Fonksiyonlar ---
  void _showErrorSnackBar(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isWarning ? Colors.orange : Colors.red,
    ));
  }

  void _showSuccessSnackBar(String message, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }
}
