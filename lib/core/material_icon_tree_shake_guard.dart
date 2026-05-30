import 'package:flutter/material.dart';

import 'generated/material_icon_manifest.g.dart';

/// Retains every app [Icons] glyph in release web builds without
/// `--no-tree-shake-icons` (see [MaterialIconManifest]).
class MaterialIconTreeShakeGuard extends StatelessWidget {
  const MaterialIconTreeShakeGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Offstage(child: _ManifestIconStrip()),
      ],
    );
  }
}

class _ManifestIconStrip extends StatelessWidget {
  const _ManifestIconStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final icon in MaterialIconManifest.all)
          Icon(icon, size: 0.01),
      ],
    );
  }
}
