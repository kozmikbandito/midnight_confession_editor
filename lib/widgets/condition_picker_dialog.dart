// lib/widgets/condition_picker_dialog.dart

import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showConditionPickerDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> allNodes,
  required List<Map<String, dynamic>> allRelationships,
}) async {

  List<Map<String, dynamic>> availableTriggers = [];

  // Tüm ilişkileri gez ve içindeki 'bilgi paketçiklerini' bul
  for (var relationship in allRelationships) {
    final infoList = (relationship['relationship_data']?['information'] as List<dynamic>?);
    if (infoList != null) {
      for (int i = 0; i < infoList.length; i++) {
        final infoText = infoList[i].toString();
        // Her bir bilgi paketçiğini, daha sonra tanıyabilmek için eşsiz bir ID ile listeye ekle
        availableTriggers.add({
          'type': 'information_unlocked',
          // ID'yi şu formatta oluşturuyoruz: "iliski_id:bilginin_indeksi"
          'id': '${relationship['id']}:$i',
          'displayText': infoText,
          'sourceRelationship': relationship, // Hangi ilişkiden geldiğini de saklayalım
        });
      }
    }
  }

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Tetikleyici Olay Seç'),
        content: SizedBox(
          width: 500,
          child: availableTriggers.isEmpty
              ? const Center(child: Text('Koşul olarak eklenecek bir "bilgi" bulunamadı.\nÖnce ilişkilere bilgi ekleyin.'))
              : ListView.builder(
                  itemCount: availableTriggers.length,
                  itemBuilder: (context, index) {
                    final trigger = availableTriggers[index];
                    final relationship = trigger['sourceRelationship'];
                    final sourceNode = allNodes.firstWhere((n) => n['id'] == relationship['source_node_id']);
                    final targetNode = allNodes.firstWhere((n) => n['id'] == relationship['target_node_id']);
                    
                    return Card(
                      child: ListTile(
                        title: Text('"${trigger['displayText']}"'),
                        subtitle: Text(
                          'Kaynak: ${sourceNode['display_data']['name']} -> ${targetNode['display_data']['name']}',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                        onTap: () {
                          // Seçilen koşulu geri döndür
                          Navigator.of(context).pop({
                            'type': trigger['type'],
                            'id': trigger['id'],
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
        ],
      );
    },
  );
}