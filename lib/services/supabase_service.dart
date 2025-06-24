// lib/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // --- YENİ SİSTEM ---

  /// Belirli bir vakaya ait tüm düğümleri (şahıs, mekan vb.) çeker.
  Future<List<Map<String, dynamic>>> fetchNodesForCase(int caseId) async {
    return await _supabase
        .from('nodes')
        .select()
        .eq('case_id', caseId)
        .order('created_at', ascending: true);
  }

  // TODO: Düğümler arasındaki ilişkileri çekecek fonksiyonu buraya ekleyeceğiz.
  // Future<List<Map<String, dynamic>>> fetchRelationshipsForCase(int caseId) async { ... }
/// Belirli bir vakaya ait tüm ilişkileri (çizgileri) çeker.
  Future<List<Map<String, dynamic>>> fetchRelationshipsForCase(int caseId) async {
    return await _supabase
        .from('relationships')
        .select()
        .eq('case_id', caseId);
  }

  /// Veritabanına yeni bir düğüm (şahıs, mekan vb.) ekler.
  Future<void> addNode({
    required int caseId,
    required String nodeType,
    required Map<String, dynamic> displayData,
    required Map<String, dynamic> engineData,
  }) async {
    await _supabase.from('nodes').insert({
      'case_id': caseId,
      'node_type': nodeType,
      'display_data': displayData,
      'engine_data': engineData,
    });
  }

  /// Veritabanına yeni bir ilişki (çizgi) ekler.
  Future<void> addRelationship({
    required int caseId,
    required String sourceNodeId,
    required String targetNodeId,
    required String relationshipType,
    Map<String, dynamic>? relationshipData,
  }) async {
    await _supabase.from('relationships').insert({
      'case_id': caseId,
      'source_node_id': sourceNodeId,
      'target_node_id': targetNodeId,
      'relationship_type': relationshipType,
      'relationship_data': relationshipData,
    });
  }
/// Veritabanındaki bir ilişkinin verilerini günceller.
  Future<void> updateRelationship({
    required String relationshipId,
    required Map<String, dynamic> relationshipData,
  }) async {
    await _supabase.from('relationships').update({
      'relationship_data': relationshipData
    }).match({'id': relationshipId});
  }
/// Veritabanındaki bir düğümün verilerini günceller.
  Future<void> updateNode({
    required String nodeId,
    required Map<String, dynamic> data, // Artık tüm güncellemeyi tek bir map'te alıyoruz
  }) async {
    await _supabase.from('nodes').update(data).match({'id': nodeId});
  }


  // --- ESKİ SİSTEM (Hala İhtiyacımız Olanlar) ---

  /// Vaka listesini çeker. Bu fonksiyon hala geçerli.
  Future<List<Map<String, dynamic>>> fetchCases() async {
    return await _supabase.from('cases').select().order('created_at', ascending: false);
  }

  /// Yeni vaka ekler. Bu fonksiyon hala geçerli.
  Future<void> addCase(String title, String brief) async {
    await _supabase.from('cases').insert({'title': title, 'brief': brief});
  }
  
  /// Vakayı siler. Bu fonksiyon hala geçerli.
  Future<void> deleteCase(int caseId) async {
    await _supabase.from('cases').delete().match({'id': caseId});
  }

  /// Dışa aktarma için tüm vaka verilerini çeker.
  /// BU FONKSİYONU DAHA SONRA YENİ SİSTEME GÖRE GÜNCELLEYECEĞİZ.
  Future<Map<String, dynamic>> getFullCaseDataForExport(int caseId) async {
    // 1. Ana vaka bilgisini çek
    final caseData = await _supabase
        .from('cases')
        .select()
        .eq('id', caseId)
        .single();

    // 2. Vakaya ait tüm düğümleri ve ilişkileri paralel olarak çek
    final results = await Future.wait([
      fetchNodesForCase(caseId),
      fetchRelationshipsForCase(caseId),
    ]);
    
    final nodes = results[0];
    final relationships = results[1];

    // 3. Final JSON yapısını oluşturmaya başla
    final finalJson = <String, dynamic>{
      '_comment': 'Bu vaka dosyası Midnight Confession Editor v2.0 tarafından oluşturulmuştur.',
      'case_info': {
        '_comment': 'Vaka hakkındaki temel bilgiler.',
        'id': caseData['id'],
        'title': caseData['title'],
        'brief': caseData['brief'],
        'culprit_character_id': caseData['culprit_character_id']
      },
      'nodes': {
        '_comment': 'Olay Tahtası\'\'ndaki tüm düğümler (şahıslar, mekanlar, kanıtlar).',
        // Düğümleri tiplerine göre gruplayalım
        'characters': nodes.where((n) => n['node_type'] == 'character').toList(),
        'locations': nodes.where((n) => n['node_type'] == 'location').toList(),
        'evidence': nodes.where((n) => n['node_type'] == 'evidence').toList(),
        'information_nodes': nodes.where((n) => n['node_type'] == 'information').toList(),
      },
      'relationships': {
        '_comment': 'Düğümler arasındaki tüm ilişkileri ve bu ilişkilere ait verileri içerir.',
        'connections': relationships,
      }
    };

    return finalJson;
  }
}
