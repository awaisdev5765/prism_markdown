<h1 align="center">prism_markdown</h1>

<p align="center">
  <a href="https://pub.dev/packages/prism_markdown"><img alt="pub.dev" src="https://img.shields.io/pub/v/prism_markdown.svg"></a>
  <a href="https://github.com/awaisdev5765/prism_markdown"><img alt="GitHub stars" src="https://img.shields.io/github/stars/awaisdev5765/prism_markdown?style=social"></a>
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</p>

<p align="center">
  A <b>fast, plugin-free Markdown widget for Flutter</b> with full <b>CommonMark</b> and <b>GFM</b> support.<br>
  The actively maintained replacement for the discontinued <code>flutter_markdown</code> package.
</p>

<p align="center">
  Android · iOS · macOS · Windows · Linux · Web — one widget, every platform.
</p>

---

## Table of contents

- [Why prism_markdown?](#why-prism_markdown)
- [Features](#features)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Render every element](#render-every-element)
- [Make text selectable](#make-text-selectable)
- [Handle link taps](#handle-link-taps)
- [Theme everything](#theme-everything)
- [Syntax highlighting for code](#syntax-highlighting-for-code)
- [Custom images](#custom-images)
- [Supported Markdown syntax](#supported-markdown-syntax)
- [Migrating from flutter_markdown](#migrating-from-flutter_markdown)
- [API reference](#api-reference)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## Why prism_markdown?

Google **discontinued `flutter_markdown` in April 2025** with no migration
path. Thousands of apps still need to render Markdown: changelogs, help
centers, AI chat responses, README previews, comment fields, documentation
views, and chat bots.

`prism_markdown` fills that gap with:

- **Pure Flutter rendering** — no web views, no platform channels, no native
  code to compile. Drop it into any existing app.
- **Correctness first** — parsing is handled by the battle-tested
  [`markdown`](https://pub.dev/packages/markdown) package (full CommonMark),
  with GFM extensions enabled.
- **Zero configuration** — sensible defaults that match your app's
  `TextTheme` out of the box, yet every visual detail is overridable.

## Features

- ✅ Full CommonMark parsing — headings, lists, blockquotes, code fences, tables
- ✅ GFM extensions — tables, strikethrough, task lists, autolinks
- ✅ Pure Flutter rendering — no web views, no platform channels
- ✅ Selectable text (toggle with a single flag)
- ✅ Link tap callbacks for custom navigation
- ✅ Rich theming via `PrismMarkdownStyle`
- ✅ Syntax highlighting hook (`highlighter`) for fenced code blocks
- ✅ Custom image rendering (`imageBuilder`) with graceful fallbacks
- ✅ All six Flutter platforms: Android, iOS, macOS, Windows, Linux, Web
- ✅ Efficient — Markdown is parsed once, only re-parsed when the text changes

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  prism_markdown: ^0.2.1
```

Then install:

```bash
flutter pub get
```

No platform-specific setup, no `Info.plist` changes, no Gradle edits — it
just works.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:prism_markdown/prism_markdown.dart';

class SimpleExample extends StatelessWidget {
  const SimpleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PrismMarkdown(
      '''
# Hello Prism

A paragraph with **bold**, *italic*, ~~strikethrough~~, and `inline code`.

- [x] Task list item
- [ ] Another one
''',
    );
  }
}
```

That's it — one widget, zero configuration.

## Render every element

````dart
PrismMarkdown(
  '''
# Heading 1
## Heading 2
### Heading 3

A paragraph with **bold**, *italic*, ~~strikethrough~~, and `code`.

- Bullet list item
- Another bullet

1. Numbered item
2. Second item

- [x] Task done
- [ ] Task pending

> A blockquote for emphasis or citations.

```dart
void main() {
  print('Hello, world!');
}
```

| Col A | Col B |
| ----- | ----- |
| 1     | 2     |

[Prism on pub.dev](https://pub.dev/packages/prism_markdown)

![An image](https://example.com/logo.png)

---
''',
);
````

## Make text selectable

Allow users to copy text (useful for chat apps, changelogs, or AI responses):

```dart
PrismMarkdown(
  'Chat response from an AI assistant…',
  selectable: true, // default
);
```

Set `selectable: false` when you don't need selection (e.g. static docs) for
slightly better performance.

## Handle link taps

By default, links are tappable but do nothing (so you can choose how to open
them). Wire them up to `url_launcher`:

```yaml
dependencies:
  url_launcher: ^6.3.0
```

```dart
import 'package:url_launcher/url_launcher.dart';

PrismMarkdown(
  'Check out [Flutter](https://flutter.dev) for more.',
  onLinkTap: (href) {
    launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
  },
);
```

## Theme everything

`PrismMarkdownStyle` gives you full control. Unset fields fall back to your
app's `TextTheme`, so the widget looks right out of the box.

```dart
PrismMarkdown(
  '# Custom heading\n\n`code example`',
  style: PrismMarkdownStyle(
    // Per-level heading styles (H1–H6).
    headingStyles: [
      const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
      const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
      // … H3–H6
    ],
    textStyle: const TextStyle(fontSize: 16, height: 1.5),
    codeStyle: const TextStyle(
      fontFamily: 'JetBrains Mono',
      color: Colors.pink,
    ),
    codeblockBackground: Colors.grey.shade100,
    blockquoteStyle: const TextStyle(fontStyle: FontStyle.italic),
    tableBorderStyle: const BorderSide(color: Colors.grey),
  ),
);
```

## Syntax highlighting for code

Pass a `highlighter` callback to colorize fenced code blocks. The callback
receives the raw code text and the detected language (from the fence info
string, e.g. ```` ```dart ````).

```dart
// With a highlighter library like `highlight`:
import 'package:highlight/highlight.dart' as hl;

TextSpan highlighter(String code, String language) {
  final result = hl.highlight(code, language: language);
  // Convert `result.nodes` to Flutter TextSpans…
  return TextSpan(text: code, style: const TextStyle(fontFamily: 'monospace'));
}

PrismMarkdown(
  '''```dart
void main() {
  print('Hello, Prism!');
}
```''',
  highlighter: highlighter,
);
```

Works with any highlighting library — `highlight`, `flutter_highlight`,
`highlighter`, or your own custom logic.

## Custom images

Control how Markdown images are rendered — e.g. add caching, sizing, or
rounding:

```dart
PrismMarkdown(
  '![Logo](https://example.com/logo.png)',
  imageBuilder: (src, alt, fallback) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(src, fit: BoxFit.cover),
    );
  },
);
```

The third argument is a ready-made fallback widget with graceful loading and
error states — use it as-is or ignore it entirely.

## Supported Markdown syntax

| Feature | Supported | Notes |
| --- | :---: | --- |
| Headings (ATX `#` and Setext `===`) | ✅ | Levels 1–6 |
| Paragraphs & emphasis | ✅ | `*italic*`, `**bold**`, `***both***` |
| Strikethrough | ✅ | `~~text~~` (GFM) |
| Inline code | ✅ | `` `code` `` |
| Fenced code blocks | ✅ | With language detection |
| Blockquotes | ✅ | Including nested |
| Bullet lists | ✅ | `-`, `*`, `+` |
| Ordered lists | ✅ | `1.`, `1)`, nested |
| Task lists | ✅ | `- [x]`, `- [ ]` (GFM) |
| Tables | ✅ | GFM pipe tables with alignment |
| Links & autolinks | ✅ | `[text](url)`, `<https://…>`, bare URLs (GFM) |
| Images | ✅ | Network images with fallbacks |
| Horizontal rules | ✅ | `---`, `***`, `___` |
| HTML blocks | ❌ | Sanitized; not rendered (by design) |

## Migrating from flutter_markdown

| flutter_markdown (discontinued) | prism_markdown |
| --- | --- |
| `MarkdownBody(data: '…')` | `PrismMarkdown('…')` |
| `onTapLink(href)` | `onLinkTap: (href) => …` |
| `styleSheet: MarkdownStyleSheet(...)` | `style: PrismMarkdownStyle(...)` |
| `selectable: true` | `selectable: true` (same) |
| `MarkdownStyleSheet.fromTheme(…)` | Automatic — falls back to your `TextTheme` |

The API shape is deliberately close so migration is mostly a rename. Like
`flutter_markdown`, this package is pure Flutter — no web views, no platform
channels.

## API reference

Full documentation is on
[pub.dev](https://pub.dev/packages/prism_markdown). Key members:

- **`PrismMarkdown(data, {style, extensionSet, onLinkTap, selectable, highlighter, imageBuilder})`** — the rendering widget.
- **`PrismMarkdownStyle`** — all visual knobs: `textStyle`, `headingStyles`, `codeStyle`, `codeblockBackground`, `blockquoteStyle`, `tableBorderStyle`, and more.
- **`extensionSet`** — pass a custom `markdown` package `ExtensionSet` for advanced parsing needs (defaults to GitHub-Web-flavored Markdown).

## FAQ

**Does it work on all Flutter platforms?**
Yes — Android, iOS, macOS, Windows, Linux, and Web. It's pure Flutter
rendering with no platform channels or native code.

**Is HTML inside Markdown rendered?**
No, HTML is sanitized and skipped. This keeps the widget safe (no XSS) and
consistent across platforms.

**Can I use my own syntax highlighting library?**
Yes — pass any `TextSpan Function(String code, String language)` as
`highlighter`. See [Syntax highlighting](#syntax-highlighting-for-code).

**How do I open links in a browser?**
Use `onLinkTap` with `url_launcher`. See [Handle link taps](#handle-link-taps).

**Is it really a drop-in replacement for `flutter_markdown`?**
Functionally yes for most apps — see the
[migration table](#migrating-from-flutter_markdown). Some niche
`MarkdownStyleSheet` properties have equivalents under slightly different
names.

**Why is the package called "prism"?**
Like a prism refracts light into a full spectrum, this package takes
Markdown source text and renders it into a full, colorful widget tree. It's
also a nod to the popular Prism.js syntax highlighter.

## Contributing

Contributions are welcome! Open an issue to discuss a feature or bug first,
then submit a pull request with tests for any behavior you add or change.

## License

MIT — see [LICENSE](LICENSE).
