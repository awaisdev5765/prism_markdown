# Changelog

## 0.2.2

- **Docs**: fixed broken "Render every element" code example on pub.dev
  (nested code fence now renders correctly), converted feature list to
  bullets, and corrected the flutter_markdown migration table.


## 0.2.1

- **Docs**: rewritten README with full usage guide, migration table from
  `flutter_markdown`, screenshots section, and FAQ.
- **Docs**: added GitHub repo badges and About/description metadata.


## 0.2.0

- **Fixed**: the widget now re-parses and re-renders when `data` changes
  (previously it kept showing stale content).
- **New**: `highlighter` callback for custom syntax highlighting of fenced
  and inline code, with automatic language detection from the fence info.
- **New**: `imageBuilder` callback to fully customize image rendering
  (e.g. CachedNetworkImage, local assets) with a built-in network fallback.
- **New**: documented first-class support for all Flutter platforms —
  Android, iOS, macOS, Windows, Linux, and web (pure Flutter, no plugins).

## 0.1.1

- Improved README documentation.

## 0.1.0

- Initial release.
- Full CommonMark parsing with GFM extensions (tables, strikethrough, task
  lists, autolinks).
- `PrismMarkdown` widget with selectable text and link tap callbacks.
- `PrismMarkdownStyle` for theming all block and inline elements.
