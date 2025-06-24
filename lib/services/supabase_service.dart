import 'package:supabase_flutter/supabase_flutter.dart';

// Bu sınıf, Supabase ile ilgili tüm veritabanı işlemlerini tek bir yerde toplar.
class SupabaseService {
  final _supabase = Supabase.instance.client;

  // --- Veri Çekme (SELECT) Fonksiyonları ---

  Future<List<Map<String, dynamic>>> fetchCases() async {
    return await _supabase.from('cases').select().order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchCharacters(int caseId) async {
    return await _supabase.from('characters').select().eq('case_id', caseId).order('created_at');
  }

  Future<List<Map<String, dynamic>>> fetchEvidence(int caseId) async {
    // GÜNCELLEME: Kanıtları çekerken bağlı olduğu mekanın adını da alıyoruz.
    return await _supabase.from('evidence').select('*, locations(name)').eq('case_id', caseId).order('created_at');
  }

  Future<List<Map<String, dynamic>>> fetchLocations(int caseId) async {
    return await _supabase.from('locations').select().eq('case_id', caseId).order('id');
  }

  Future<List<Map<String, dynamic>>> fetchInformation(String characterId) async {
    // GÜNCELLEME: Sırları çekerken, tetikleyici kanıtı ve açtığı mekanı da alıyoruz.
    return await _supabase.from('information').select('*, triggers(*, evidence(name)), locations(name)').eq('character_id', characterId);
  }

  // --- Veri Ekleme (INSERT) Fonksiyonları ---

  Future<void> addCase(String title, String brief) async {
    await _supabase.from('cases').insert({'title': title, 'brief': brief});
  }

  Future<void> addCharacter(int caseId, String name, String basePrompt) async {
    await _supabase.from('characters').insert({'case_id': caseId, 'name': name, 'base_prompt': basePrompt});
  }

  Future<void> addLocation(int caseId, String name, String description) async {
    await _supabase.from('locations').insert({'case_id': caseId, 'name': name, 'description': description});
  }

  // GÜNCELLEME: Hem yeni kanıt ekleme hem de güncelleme için tek bir fonksiyon.
  // Bu fonksiyon DialogService tarafından kullanılacak.
  Future<void> saveEvidence(int caseId, Map<String, dynamic> data) async {
    final evidenceId = data['id'];
    if (evidenceId == null) {
      // ID yoksa, bu yeni bir kanıttır. case_id'yi ekleyip insert yap.
      data['case_id'] = caseId;
      await _supabase.from('evidence').insert(data);
    } else {
      // ID varsa, bu mevcut bir kanıttır. update yap.
      await _supabase.from('evidence').update(data).eq('id', evidenceId);
    }
  }

  // --- Veri Silme (DELETE) Fonksiyonları ---

  Future<void> deleteCase(int caseId) async {
    await _supabase.from('cases').delete().match({'id': caseId});
  }

  // --- Veri Güncelleme (UPDATE) Fonksiyonları ---

  // YENİ: Vakanın suçlusunu güncelleyen fonksiyon.
  Future<Map<String, dynamic>> setCulprit(int caseId, String characterId) async {
    return await _supabase
        .from('cases')
        .update({'culprit_character_id': characterId})
        .eq('id', caseId)
        .select()
        .single();
  }

  // --- Kompleks Fonksiyonlar ---

  Future<Map<String, dynamic>> getFullCaseDataForExport(int caseId) async {
    return await _supabase
        .from('cases')
        .select('*, characters!case_id(*, information!character_id(*, triggers(*, evidence(id, name, is_red_herring)), locations(name))), evidence(*, locations(name)), locations(*)')
        .eq('id', caseId)
        .single();
  }
}
