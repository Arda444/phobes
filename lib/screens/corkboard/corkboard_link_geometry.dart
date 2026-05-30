import 'dart:ui';

import '../../models/corkboard_connection_model.dart';
import '../../models/corkboard_item_model.dart';

/// Live or stored top-left position for link geometry.
Offset corkItemPosition(
  CorkboardItem item, {
  Map<String, Offset>? dragOverrides,
}) {
  final id = item.id;
  if (id != null && dragOverrides != null) {
    final o = dragOverrides[id];
    if (o != null) return o;
  }
  return Offset(item.posX, item.posY);
}

/// Anchor for connection lines (top center of the card).
Offset corkItemLinkAnchor(
  CorkboardItem item, {
  Map<String, Offset>? dragOverrides,
}) {
  final pos = corkItemPosition(item, dragOverrides: dragOverrides);
  return Offset(pos.dx + item.size / 2, pos.dy + 8);
}

Path corkLinkPath(Offset p1, Offset p2) {
  final dist = (p2 - p1).distance;
  final sag = (dist * 0.14).clamp(12.0, 120.0);
  final ctrl = Offset(
    (p1.dx + p2.dx) / 2,
    (p1.dy + p2.dy) / 2 + sag,
  );
  return Path()
    ..moveTo(p1.dx, p1.dy)
    ..quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
}

/// Returns connection id if [point] is near a link curve.
String? hitTestCorkConnection(
  Offset point, {
  required List<CorkboardItem> items,
  required List<CorkboardConnection> connections,
  Map<String, Offset>? dragOverrides,
  double tolerance = 14,
}) {
  for (final c in connections) {
    if (c.id == null) continue;
    final from = items.where((i) => i.id == c.fromId).firstOrNull;
    final to = items.where((i) => i.id == c.toId).firstOrNull;
    if (from == null || to == null) continue;

    final path = corkLinkPath(
      corkItemLinkAnchor(from, dragOverrides: dragOverrides),
      corkItemLinkAnchor(to, dragOverrides: dragOverrides),
    );

    for (final metric in path.computeMetrics()) {
      for (double t = 0; t <= 1; t += 0.05) {
        final tangent = metric.getTangentForOffset(metric.length * t);
        if (tangent == null) continue;
        if ((tangent.position - point).distance <= tolerance) {
          return c.id;
        }
      }
    }
  }
  return null;
}
