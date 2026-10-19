import 'package:flutter/material.dart';
import 'package:prism_markdown/prism_markdown.dart';

void main() {
  runApp(const PrismDemoApp());
}

const sample = '''
# prism_markdown

A **fast**, *plugin-free* Markdown widget with full CommonMark + GFM support.

## Features

- [x] CommonMark conformance
- [x] GFM tables
- [ ] Syntax highlighting (coming soon)

## Table

| Feature | Status |
| ------- | ------ |
| Tables  | ✅     |
| Tasks   | ✅     |

## Code

```dart
void main() {
  print('hello prism');
}
```

> Blockquotes work too.

[Links are tappable.](https://pub.dev)

---

~~Goodbye, flutter_markdown.~~ Hello, prism_markdown.
''';

class PrismDemoApp extends StatelessWidget {
  const PrismDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'prism_markdown demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('prism_markdown demo')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PrismMarkdown(
            sample,
            onLinkTap: (href) {
              // In a real app use url_launcher.
              // ignore: avoid_print
              print('Tapped: $href');
            },
          ),
        ),
      ),
    );
  }
}
