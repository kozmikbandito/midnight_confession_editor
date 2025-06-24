import 'package:flutter/material.dart';

// Bu sınıf, uygulama içindeki tüm diyalog pencerelerini göstermekten sorumludur.
class DialogService {

  // Basit bir onay diyaloğu gösterir ve kullanıcının seçimine göre true/false döndürür.
  Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'SİL',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Yeni karakter ekleme diyaloğunu gösterir.
  // Kullanıcı "Kaydet" derse girilen bilgileri bir Map olarak döndürür, yoksa null döner.
  Future<Map<String, String>?> showAddCharacterDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final promptController = TextEditingController();

    return await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Karakter Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Karakter Adı')),
            const SizedBox(height: 8),
            TextField(controller: promptController, decoration: const InputDecoration(labelText: 'Temel Kişilik (Base Prompt)'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('İptal')),
          ElevatedButton(onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop({
                'name': name,
                'base_prompt': promptController.text.trim(),
              });
            }
          }, child: const Text('Kaydet')),
        ],
      ),
    );
  }

  // Yeni mekan ekleme diyaloğunu gösterir.
  Future<Map<String, String>?> showAddLocationDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    return await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Mekan Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Mekan Adı')),
            const SizedBox(height: 8),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('İptal')),
          ElevatedButton(onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop({
                'name': name,
                'description': descriptionController.text.trim(),
              });
            }
          }, child: const Text('Kaydet')),
        ],
      ),
    );
  }

  // GÜNCELLEME: Hem yeni kanıt ekleme hem de düzenleme için kullanılan diyalog.
  Future<Map<String, dynamic>?> showEditEvidenceDialog({
    required BuildContext context,
    required Map<String, dynamic> evidence,
    required List<Map<String, dynamic>> locations,
  }) async {
    final isNew = evidence.isEmpty;
    final nameController = TextEditingController(text: evidence['name']);
    final descriptionController = TextEditingController(text: evidence['description']);
    int? selectedLocationId = evidence['location_id'];
    bool isRedHerring = evidence['is_red_herring'] ?? false;

    return await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isNew ? 'Yeni Kanıt Ekle' : 'Kanıtı Düzenle'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Kanıt Adı')),
                    const SizedBox(height: 8),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 3),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedLocationId,
                      hint: const Text("Kanıtın Bulunduğu Mekan"),
                      isExpanded: true,
                      items: locations.map<DropdownMenuItem<int>>((location) {
                        return DropdownMenuItem(value: location['id'], child: Text(location['name']));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() { selectedLocationId = value; });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text("Yanıltıcı Kanıt (Red Herring)"),
                      value: isRedHerring,
                      onChanged: (value) {
                        setDialogState(() { isRedHerring = value ?? false; });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('İptal')),
              ElevatedButton(onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop({
                    'id': evidence['id'], // Güncelleme için ID'yi geri döndür.
                    'name': name,
                    'description': descriptionController.text.trim(),
                    'location_id': selectedLocationId,
                    'is_red_herring': isRedHerring,
                  });
                }
              }, child: Text(isNew ? 'Ekle' : 'Güncelle')),
            ],
          );
        });
      },
    );
  }

  // YENİ: Vakanın suçlusunu seçmek için kullanılan diyalog.
  Future<String?> showSetCulpritDialog({
    required BuildContext context,
    required List<Map<String, dynamic>> characters,
    required String? currentCulpritId,
  }) async {
    String? selectedCulpritId = currentCulpritId;
    return await showDialog<String?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Vakanın Suçlusunu Belirle"),
            content: SizedBox(
              width: 300,
              child: characters.isEmpty
                  ? const Text("Suçlu olarak atamak için önce karakter eklemelisiniz.")
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: characters.length,
                itemBuilder: (context, index) {
                  final character = characters[index];
                  return RadioListTile<String>(
                    title: Text(character['name']),
                    value: character['id'],
                    groupValue: selectedCulpritId,
                    onChanged: (value) {
                      setDialogState(() { selectedCulpritId = value; });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('İptal')),
              ElevatedButton(onPressed: () {
                Navigator.of(context).pop(selectedCulpritId);
              }, child: const Text('Kaydet')),
            ],
          );
        });
      },
    );
  }
}
