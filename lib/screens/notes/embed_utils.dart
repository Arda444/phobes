import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

Widget embedError(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: cs.errorContainer.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: cs.error.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        Icon(Icons.broken_image_outlined, size: 16, color: cs.error),
        const SizedBox(width: 8),
        Text('İçerik yüklenemedi',
            style: TextStyle(fontSize: 12, color: cs.error),),
      ],
    ),
  );
}

({int offset, Embed node})? getCustomEmbedNode(QuillController controller, int offset) {
  var currOffset = 0;
  for (final op in controller.document.toDelta().toList()) {
    final opLen = op.length ?? 1;
    if (currOffset <= offset && offset < currOffset + opLen) {
      if (op.data is Map) {
        try {
          final mapData = Map<String, dynamic>.from(op.data as Map);
          final embeddable = Embeddable.fromJson(mapData);
          return (offset: currOffset, node: Embed(embeddable));
        } catch (_) {
          return null;
        }
      }
    }
    currOffset += opLen;
  }
  return null;
}
