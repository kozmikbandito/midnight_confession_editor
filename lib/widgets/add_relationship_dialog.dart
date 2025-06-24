// lib/widgets/add_relationship_dialog.dart

import 'package:flutter/material.dart';

Future<String?> showAddRelationshipDialog({
  required BuildContext context,
  required List<String> availableTypes,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      String? selectedType = availableTypes.isNotEmpty ? availableTypes[0] : null;
      return AlertDialog(
        title: const Text('İlişki Türü Seç'),
        content: DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          items: availableTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              selectedType = value;
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(selectedType);
            },
            child: const Text('Oluştur'),
          ),
        ],
      );
    },
  );
}