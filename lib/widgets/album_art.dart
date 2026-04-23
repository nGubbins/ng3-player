import 'dart:typed_data';

import 'package:flutter/material.dart';

class AlbumArt extends StatelessWidget {
  final Uint8List? data;
  /// Pass a finite size for fixed dimensions, or double.infinity to fill
  /// available space (parent must provide bounded constraints).
  final double size;
  final double borderRadius;

  const AlbumArt({super.key, this.data, required this.size, this.borderRadius = 4});

  @override
  Widget build(BuildContext context) {
    final expand = !size.isFinite;
    final iconSize = expand ? 32.0 : size * 0.5;

    Widget placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.music_note, size: iconSize, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );

    if (!expand) {
      placeholder = SizedBox(width: size, height: size, child: placeholder);
    }

    Widget content = data == null
        ? placeholder
        : Image.memory(
            data!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
          );

    content = ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: content);

    if (!expand) {
      content = SizedBox(width: size, height: size, child: content);
    }

    return content;
  }
}
