// Web-only implementation to update browser UI colors at runtime.
// Uses conditional import from web_meta.dart.

import 'package:flutter/material.dart';
import 'dart:html' as html;

String _toHex(Color c) {
  final rgb = (c.value & 0x00FFFFFF).toRadixString(16).padLeft(6, '0');
  return '#$rgb'.toLowerCase();
}

void applyThemeColors(Color color) {
  final hex = _toHex(color);

  // Set <meta name="theme-color"> for Android Chrome UI
  final doc = html.document;
  final head = doc.head;
  if (head != null) {
    html.MetaElement? meta = doc.querySelector('meta[name="theme-color"]') as html.MetaElement?;
    meta ??= html.MetaElement()..name = 'theme-color';
    meta.content = hex;
    if (!head.children.contains(meta)) {
      head.append(meta);
    }
  }

  // Set body background so iOS safe areas match while PWA loads
  doc.body?.style.backgroundColor = hex;
}
