import 'package:flutter/material.dart';

class DetailPanel extends StatelessWidget {
  final String title;
  final bool isLoading;
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final VoidCallback onAdd;

  const DetailPanel({
    super.key,
    required this.title,
    required this.isLoading,
    required this.itemCount,
    required this.itemBuilder,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias, // Kartın içeriğinin kenarlardan taşmasını engeller
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.teal, size: 28),
                  tooltip: '$title Ekle',
                  onPressed: onAdd,
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : itemCount == 0
                      ? Center(child: Text('$title eklenmemiş.', style: TextStyle(color: Colors.grey.shade400)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: itemCount,
                          itemBuilder: (context, index) => itemBuilder(index),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
