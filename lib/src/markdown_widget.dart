import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

import 'block_builder.dart';
import 'inline_builder.dart';
import 'style.dart';

export 'style.dart';

/// A widget that renders markdown text as rich, selectable Flutter UI.
///
/// Supports the full CommonMark spec plus GFM extensions: tables,
/// strikethrough, task lists, and autolinks. No web views, no platform
/// plugins — pure Flutter rendering.
///
/// ```dart
/// PrismMarkdown('# Hello\n\nWorld with **bold** text.')
/// ```
///
/// This is a pure-Flutter widget with no platform channels, so it works on
/// every Flutter platform: Android, iOS, macOS, Windows, Linux, and web.
class PrismMarkdown extends StatefulWidget {
  /// Creates a markdown renderer.
  const PrismMarkdown(
    this.data, {
    super.key,
    this.style,
    this.extensionSet,
    this.onLinkTap,
    this.selectable = true,
    this.highlighter,
    this.imageBuilder,
  });

  /// The markdown source to render.
  final String data;

  /// Visual styling. Unset fields are derived from the ambient [ThemeData].
  final PrismMarkdownStyle? style;

  /// Markdown extension set applied during parsing. Defaults to
  /// [md.ExtensionSet.gitHubWeb] when null.
  final md.ExtensionSet? extensionSet;

  /// Called when a link is tapped.
  final void Function(String href)? onLinkTap;

  /// Whether text can be selected.
  final bool selectable;

  /// Custom syntax highlighter for fenced code blocks.
  ///
  /// Receives the raw code text and the fence's info string (e.g. `dart`),
  /// and returns highlighted [TextSpan]s. If null, code is rendered with
  /// [PrismMarkdownStyle.codeStyle] without highlighting.
  ///
  /// ```dart
  /// PrismMarkdown(
  ///   '```dart\nvoid main() {}\n```',
  ///   highlighter: (code, language) => myHighlighter(code, language),
  /// )
  /// ```
  final TextSpan Function(String code, String language)? highlighter;

  /// Custom builder for inline images (`![alt](src)`).
  ///
  /// Receives the image source, alternate text, and the default fallback
  /// widget. Return any widget, e.g. `CachedNetworkImage` or a local
  /// asset loader. If null, images load from the network via [Image.network].
  final Widget Function(String src, String alt, Widget fallback)? imageBuilder;

  @override
  State<PrismMarkdown> createState() => _PrismMarkdownState();
}

class _PrismMarkdownState extends State<PrismMarkdown> {
  List<md.Node> _parsed = const [];
  String _parsedFrom = '';

  @override
  void initState() {
    super.initState();
    _parsed = _parse(widget.data);
    _parsedFrom = widget.data;
  }

  @override
  void didUpdateWidget(covariant PrismMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != _parsedFrom) {
      _parsed = _parse(widget.data);
      _parsedFrom = widget.data;
    }
  }

  List<md.Node> _parse(String data) {
    final document = md.Document(
      extensionSet: widget.extensionSet ?? md.ExtensionSet.gitHubWeb,
    );
    return document.parseLines(
      const LineSplitter().convert(data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        (widget.style ?? const PrismMarkdownStyle()).resolve(context);
    final children = BlockBuilder(
      style: resolvedStyle,
      onLinkTap: widget.onLinkTap,
      highlighter: widget.highlighter,
      imageBuilder: widget.imageBuilder,
    ).build(_parsed);

    if (widget.selectable) {
      return SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// Exposed for advanced use: builds inline spans directly.
InlineSpan buildInlineSpans(
  List<md.Node> nodes,
  PrismMarkdownStyle style, {
  void Function(String href)? onLinkTap,
}) =>
    InlineBuilder(style: style, onLinkTap: onLinkTap).build(nodes);
