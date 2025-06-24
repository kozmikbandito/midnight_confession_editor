// lib/widgets/unlock_condition_editor_dialog.dart

import 'package:flutter/material.dart';
import 'package:midnight_confession_editor/widgets/condition_picker_dialog.dart';

Future<Map<String, dynamic>?> showUnlockConditionEditorDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> allNodes,
  required List<Map<String, dynamic>> allRelationships,
  Map<String, dynamic>? initialConditions,
}) async {
  
  List<Map<String, dynamic>> conditions = (initialConditions?['conditions'] as List<dynamic>?)
      ?.map((c) => Map<String, dynamic>.from(c))
      .toList() ?? [];
  String logicType = initialConditions?['type'] ?? 'AND';

  String getConditionText(Map<String, dynamic> condition) {
    if (condition['type'] == 'information_unlocked') {
      final parts = (condition['id'] as String).split(':');
      final relationshipId = parts[0];
      final infoIndex = int.parse(parts[1]);
      
      final relationship = allRelationships.firstWhere((r) => r['id'] == relationshipId, orElse: () => {});
      if (relationship.isEmpty) return 'Bilinmeyen Bilgi';
      
      final infoList = (relationship['relationship_data']?['information'] as List<dynamic>?);
      if (infoList != null && infoList.length > infoIndex) {
        return '"${infoList[infoIndex]}" bilgisi öğrenildiğinde';
      }
    }
    return 'Bilinmeyen koşul: ${condition['id']}';
  }

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Kilit Koşullarını Düzenle'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'AND', label: Text('TÜMÜ karşılansın (AND)')),
                    ButtonSegment(value: 'OR', label: Text('HERHANGİ BİRİ karşılansın (OR)')),
                  ],
                  selected: {logicType},
                  onSelectionChanged: (newSelection) { setDialogState(() { logicType = newSelection.first; }); },
                ),
                const Divider(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: conditions.length,
                    itemBuilder: (context, index) {
                      final condition = conditions[index];
                      return ListTile(
                        leading: const Icon(Icons.key_outlined, color: Colors.amber),
                        title: Text(getConditionText(condition)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () { setDialogState(() { conditions.removeAt(index); }); },
                        ),
                      );
                    },
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Koşul Ekle'),
                  onPressed: () async {
                    // DEĞİŞİKLİK: Artık yeni koşul seçiciyi açıyoruz
                    final newCondition = await showConditionPickerDialog(
                      context: context, 
                      allNodes: allNodes, 
                      allRelationships: allRelationships
                    );

                    if (newCondition != null) {
                      setDialogState(() {
                        conditions.add(newCondition);
                      });
                    }
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                final result = { 'type': logicType, 'conditions': conditions, };
                Navigator.of(context).pop(result);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      });
    },
  );
}