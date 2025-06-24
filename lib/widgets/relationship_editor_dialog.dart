// lib/widgets/relationship_editor_dialog.dart

import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showRelationshipEditorDialog({
  required BuildContext context,
  required String relationshipType,
  Map<String, dynamic>? initialData,
}) async {
  List<TextEditingController> controllers = [];
  final informationList = (initialData?['information'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

  for (var info in informationList) {
    controllers.add(TextEditingController(text: info));
  }

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('İlişkiyi Düzenle: $relationshipType'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: controllers.isEmpty
                        ? const Center(child: Text('Henüz bilgi eklenmemiş.'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: controllers.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controllers[index],
                                        decoration: InputDecoration(labelText: 'Bilgi #${index + 1}'),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () {
                                        setDialogState(() {
                                          controllers.removeAt(index);
                                        });
                                      },
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Bilgi Ekle'),
                    onPressed: () {
                      setDialogState(() {
                        controllers.add(TextEditingController());
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
              ElevatedButton(
                onPressed: () {
                  final result = {
                    'information': controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
                  };
                  Navigator.of(context).pop(result);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      );
    },
  );
}