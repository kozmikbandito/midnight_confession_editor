import 'package:flutter/material.dart';
import 'detail_panel.dart';

class CaseDetailView extends StatelessWidget {
  // Gerekli veriler ve fonksiyonlar dışarıdan (HomeScreen'den) gelecek.
  final Map<String, dynamic> selectedCase;
  final List<Map<String, dynamic>> characterList;
  final bool isCharactersLoading;
  final List<Map<String, dynamic>> evidenceList;
  final bool isEvidenceLoading;
  final List<Map<String, dynamic>> locationsList;
  final bool isLoadingLocations;
  final VoidCallback onSetCulprit;
  final VoidCallback onDeleteCase;
  final VoidCallback onExportCase;
  final VoidCallback onAddCharacter;
  final void Function(Map<String, dynamic> evidence) onEditEvidence;
  final VoidCallback onAddLocation;
  final void Function(Map<String, dynamic> character) onShowCharacterDetail;

  const CaseDetailView({
    super.key,
    required this.selectedCase,
    required this.characterList,
    required this.isCharactersLoading,
    required this.evidenceList,
    required this.isEvidenceLoading,
    required this.locationsList,
    required this.isLoadingLocations,
    required this.onSetCulprit,
    required this.onDeleteCase,
    required this.onExportCase,
    required this.onAddCharacter,
    required this.onEditEvidence,
    required this.onAddLocation,
    required this.onShowCharacterDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  selectedCase['title'],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.gavel),
                label: const Text("Suçluyu Belirle"),
                onPressed: onSetCulprit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Vakayı Sil',
                onPressed: onDeleteCase,
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            selectedCase['brief'] ?? 'Bu vaka için bir açıklama girilmemiş.',
            style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.grey),
          ),
          const Divider(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Karakterler Paneli
                Expanded(
                  child: DetailPanel(
                    title: 'Karakterler',
                    isLoading: isCharactersLoading,
                    itemCount: characterList.length,
                    onAdd: onAddCharacter,
                    itemBuilder: (index) {
                      final character = characterList[index];
                      final isCulprit = selectedCase['culprit_character_id'] == character['id'];
                      return Card(
                        child: ListTile(
                          onTap: () => onShowCharacterDetail(character),
                          leading: CircleAvatar(child: Text(character['name'][0])),
                          title: Text(character['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: isCulprit ? const Icon(Icons.gavel_rounded, color: Colors.amber) : null,
                        ),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 20, indent: 20, endIndent: 20),
                // Kanıtlar Paneli
                Expanded(
                  child: DetailPanel(
                    title: 'Kanıtlar',
                    isLoading: isEvidenceLoading,
                    itemCount: evidenceList.length,
                    onAdd: () => onEditEvidence({}), // Yeni kanıt için boş harita
                    itemBuilder: (index) {
                      final evidence = evidenceList[index];
                      final bool isRedHerring = evidence['is_red_herring'] ?? false;
                      final String locationName = evidence['locations']?['name'] ?? 'Bilinmiyor';
                      return Card(
                        child: ListTile(
                          onTap: () => onEditEvidence(evidence),
                          leading: CircleAvatar(child: isRedHerring ? const Icon(Icons.question_mark, color: Colors.orange) : const Icon(Icons.description_outlined)),
                          title: Text(evidence['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Mekan: $locationName'),
                        ),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 20, indent: 20, endIndent: 20),
                // Mekanlar Paneli
                Expanded(
                  child: DetailPanel(
                    title: 'Mekanlar',
                    isLoading: isLoadingLocations,
                    itemCount: locationsList.length,
                    onAdd: onAddLocation,
                    itemBuilder: (index) {
                      final location = locationsList[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),
                          title: Text(location['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(location['description'] ?? 'Açıklama yok.', overflow: TextOverflow.ellipsis),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton.icon(
              onPressed: onExportCase,
              icon: const Icon(Icons.download_for_offline_outlined),
              label: const Text("Vakayı JSON Olarak Dışa Aktar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
            ),
          )
        ],
      ),
    );
  }
}
