// lib/widgets/node_editor_dialog.dart

import 'package:flutter/material.dart';
// import 'package:midnight_confession_editor/screens/olay_tahtasi_screen.dart'; // Ebeveyn widget'a erişim için - BU SATIR YORUMA ALINDI ÇÜNKÜ KULLANILMIYOR VE HATA VEREBİLİR
import 'package:midnight_confession_editor/widgets/unlock_condition_editor_dialog.dart';

Future<Map<String, dynamic>?> showNodeEditorDialog({
  required BuildContext context,
  required String nodeType,
  Map<String, dynamic>? initialData,
  // DEĞİŞİKLİK: Kilit editörünün ihtiyaç duyacağı tüm verileri alıyoruz
  required List<Map<String, dynamic>> allNodes, 
  required List<Map<String, dynamic>> allRelationships,
}) async {
  final isCreating = initialData == null;
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController(text: initialData?['display_data']?['name']);
  final descriptionController = TextEditingController(text: initialData?['display_data']?['description']);
  final traitsController = TextEditingController(text: (initialData?['engine_data']?['personality_traits'] as List<dynamic>?)?.join(', '));
  
  // Kilit koşullarını bir state'te tut
  Map<String, dynamic> unlockConditions = Map<String, dynamic>.from(initialData?['unlock_conditions'] ?? {'type': 'AND', 'conditions': []});


  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(isCreating ? 'Yeni $nodeType Oluştur' : '$nodeType Düzenle'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: SingleChildScrollView( // Scroll eklendi
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'İsim / Başlık'),
                    validator: (value) => (value?.isEmpty ?? true) ? 'Bu alan boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    maxLines: 3,
                  ),
                  if (nodeType == 'character') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: traitsController,
                      decoration: const InputDecoration(
                        labelText: 'Kişilik Özellikleri',
                        hintText: 'Virgülle ayırın (örn: Yalancı, Panik)',
                      ),
                    ),
                  ],
                  const Divider(height: 20),
                  // DEĞİŞİKLİK: Yeni Kilit Koşulu Butonu
                  if (!isCreating) // Sadece mevcut düğümleri düzenlerken göster
                    TextButton.icon(
                      icon: const Icon(Icons.key),
                      label: const Text('Kilit Koşullarını Düzenle'),
                      onPressed: () async {
                        final newConditions = await showUnlockConditionEditorDialog(
                          context: context, 
                          allNodes: allNodes, 
                          allRelationships: allRelationships,
                          initialConditions: Map<String, dynamic>.from(unlockConditions), // Kopyasını yolla
                        );
                        if (newConditions != null) {
                          // Dialog içindeki state'i güncellemek için setState gerekli değil,
                          // çünkü unlockConditions zaten bu scope'ta.
                          unlockConditions = newConditions;
                        }
                      },
                    )
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final result = {
                  'display_data': { 'name': nameController.text.trim(), 'description': descriptionController.text.trim(), },
                  'engine_data': { 'personality_traits': traitsController.text.split(',').map((e) => e.trim()).where((t) => t.isNotEmpty).toList(), },
                  // DEĞİŞİKLİK: Kilit koşullarını da sonuca ekle
                  'unlock_conditions': unlockConditions,
                };
                Navigator.of(context).pop(result);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      );
    },
  );
}