import 'package:flutter/material.dart';

Color stockColor(BuildContext context, int count, int threshold) {
  if (count <= 0) return const Color(0xFFD32F2F);
  if (count <= threshold) return const Color(0xFFED8B00);
  return const Color(0xFF23864A);
}

Widget sectionTitle(String title, {String? trailing}) => Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 16),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
        if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );

Widget emptyState({
  required IconData icon,
  required String title,
  String? subtitle,
}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 22),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 44, color: Colors.grey.shade500),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ]),
    );

void showAppMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? const Color(0xFFB3261E) : null,
    ));
}
