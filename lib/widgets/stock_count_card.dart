import 'package:flutter/material.dart';

import '../data/models.dart';
import 'common.dart';

class StockCountCard extends StatelessWidget {
  const StockCountCard({
    super.key,
    required this.type,
    required this.count,
    required this.threshold,
    required this.onSell,
    required this.onAdd,
  });

  final ItemType type;
  final int count;
  final int threshold;
  final VoidCallback onSell;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final color = stockColor(context, count, threshold);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(type.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(30)),
              child: Text(count == 0 ? 'নেই' : count <= threshold ? 'কম আছে' : 'আছে',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Text(
                count.toString(),
                style: TextStyle(fontSize: 36, height: 1, fontWeight: FontWeight.w900, color: color),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'স্টক যোগ করুন',
              onPressed: onAdd,
              constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
              icon: const Icon(Icons.add_rounded, size: 25),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: count > 0 ? onSell : null,
              icon: const Icon(Icons.remove_rounded),
              label: const Text('বিক্রি'),
              style: FilledButton.styleFrom(minimumSize: const Size(104, 52)),
            ),
          ]),
        ]),
      ),
    );
  }
}
