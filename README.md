# prism_markdown

A fast, plugin-free Markdown widget for Flutter with full **CommonMark** and
**GFM** support — the maintained replacement for the discontinued
`flutter_markdown` package.

## Features

- ✅ Full CommonMark parsing (via the battle-tested [`markdown` package](https://pub.dev/packages/markdown))
- ✅ GFM extensions: tables, strikethrough, task lists, autolinks
- ✅ Pure Flutter rendering — no web views, no platform channels
- ✅ Selectable text
- ✅ Link tap callbacks
- ✅ Rich theming via `PrismMarkdownStyle`

## Installation

```yaml
dependencies:
  prism_markdown: ^0.1.0
```

## Usage

```dart
import 'package:prism_markdown/prism_markdown.dart';

PrismMarkdown(
  '''
# Hello Prism

A paragraph with **bold**, *italic*, ~~strikethrough~~, and `code`.

- [x] Task list item
- [ ] Another one

| Col A | Col B |
| ----- | ----- |
| 1     | 2     |
''',
  onLinkTap: (href) => print('Link: $href'),
)
```

### Theming

```dart
PrismMarkdown(
  '# Custom heading',
  style: PrismMarkdownStyle(
    headingStyle: [
      const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
      // ...levels 2-6
    ],
  ),
)
```

## Why another markdown package?

Google discontinued `flutter_markdown` in April 2025 with no migration path.
`prism_markdown` fills that gap with active maintenance, full CommonMark
conformance, and zero platform dependencies.

## License

MIT — see [LICENSE](LICENSE).
