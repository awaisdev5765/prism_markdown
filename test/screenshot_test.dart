import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_markdown/prism_markdown.dart';

/// Screenshot generator — renders the showcase into `doc/screenshot.png`.
///
/// Run with:
/// ```sh
/// flutter test test/screenshot_test.dart
/// ```
/// Skipped in CI unless the SCREENSHOTS env var is set, so the normal test
/// run stays hermetic.
void main() {
  const key = ValueKey('screenshot');

  /// Registers real fonts so the render uses actual glyphs (otherwise
  /// the test environment draws every glyph as a solid box).
  Future<void> loadFonts() async {
    final dir = Directory('test/fonts');
    if (!dir.existsSync()) return;
    final families = <String, List<Uint8List>>{};
    for (final file in dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf'))) {
      final name = file.uri.pathSegments.last.replaceAll('.ttf', '');
      final family = name.startsWith('RobotoMono')
          ? 'monospace' // matches PrismMarkdownStyle's default code font
          : name.substring(0, name.indexOf('-'));
      (families[family] ??= []).add(file.readAsBytesSync());
    }
    for (final entry in families.entries) {
      final loader = FontLoader(entry.key);
      // Register every variant under the same family so bold/italic
      // resolve correctly.
      for (final bytes in entry.value) {
        loader.addFont(Future.value(bytes.buffer.asByteData()));
      }
      await loader.load();
    }
    // Material Icons render as tofu in tests unless the icon font is loaded.
    final flutterRoot = File(Platform.resolvedExecutable)
        .parent // dart-sdk/bin
        .parent // dart-sdk
        .parent // cache
        .parent // bin
        .parent // flutter
        .path;
    final iconFont = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
    );
    if (iconFont.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(iconFont.readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
  }

  testWidgets(
    'capture showcase screenshot',
    (tester) async {
      await loadFonts();
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: const Text(
                  'prism_markdown',
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
              ),
              body: SingleChildScrollView(
                child: PrismMarkdown(
                  '''
# Hello Prism

A paragraph with **bold**, *italic*, ~~strikethrough~~, and `inline code`.
It renders with your app's [TextTheme](https://api.flutter.dev) by default.

## Lists

- [x] Full CommonMark parsing
- [x] GFM tables and task lists
- [ ] Syntax highlighting (via `highlighter`)

1. Numbered item
2. Second item

> Blockquotes work too — great for emphasis or citations.

## Tables

| Feature | Status |
| ------- | :----: |
| CommonMark | yes |
| GFM extensions | yes |
| Pure Flutter | yes |

## Code

```dart
void main() {
  print('Hello, prism_markdown!');
}
```
''',
                  selectable: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData =
            await image.toByteData(format: ImageByteFormat.png);
        final file = File('doc/screenshot.png');
        await file.create(recursive: true);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
      });
    },
    skip: !Platform.environment.containsKey('SCREENSHOTS'),
  );
}
