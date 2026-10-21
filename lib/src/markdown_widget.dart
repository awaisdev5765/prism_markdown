import 'dart:convert';
import 'dart:isolate';

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
    this.maxLines,
    this.overflow,
    this.asyncParsing = false,
    this.placeholder,
    this.parseRunner,
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

  /// Maximum number of lines a text block (heading, paragraph, list item, or
  /// table cell) may occupy before being truncated.
  ///
  /// When set, text that wraps beyond [maxLines] is truncated using
  /// [overflow] (defaults to [TextOverflow.ellipsis] when [maxLines] is set
  /// but [overflow] is not). Code blocks are never truncated.
  ///
  /// Useful for card previews, list tiles, and chat bubbles that render
  /// markdown content within fixed-height containers.
  final int? maxLines;

  /// How visual overflow of truncated text should be handled.
  ///
  /// Only applied when [maxLines] is set. Defaults to
  /// [TextOverflow.ellipsis].
  final TextOverflow? overflow;

  /// Whether to parse the markdown off the UI thread in a background
  /// isolate.
  ///
  /// When true, parsing runs via [Isolate.run] so long documents do not
  /// block the UI thread — useful for `ListView`s that build many
  /// `PrismMarkdown` widgets, where synchronous parsing causes scroll
  /// jitter (see flutter/flutter#81772). While parsing, [placeholder] is
  /// displayed. Defaults to `false` (synchronous parsing, no isolate
  /// overhead) which is faster for short documents.
  final bool asyncParsing;

  /// Widget shown while async parsing is in progress.
  ///
  /// Only used when [asyncParsing] is true. Defaults to an empty box.
  final Widget? placeholder;

  /// Overrides the async parse executor. Null by default, in which case
  /// parsing runs in a background isolate via [Isolate.run].
  ///
  /// Provided for testing (widget tests cannot spawn real isolates) and for
  /// custom scheduling (e.g. a shared worker pool). The returned future must
  /// complete with the parsed node list for [data].
  final Future<List<md.Node>> Function(
    String data,
    md.ExtensionSet? extensionSet,
  )? parseRunner;

  @override
  State<PrismMarkdown> createState() => _PrismMarkdownState();
}

class _PrismMarkdownState extends State<PrismMarkdown> {
  List<md.Node> _parsed = const [];
  String _parsedFrom = '';
  bool _parsing = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _parsedFrom = widget.data;
    if (widget.asyncParsing) {
      _startAsyncParse(widget.data);
    } else {
      _parsed = _parse(widget.data);
    }
  }

  @override
  void didUpdateWidget(covariant PrismMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != _parsedFrom) {
      _parsedFrom = widget.data;
      if (widget.asyncParsing) {
        _startAsyncParse(widget.data);
      } else {
        _parsed = _parse(widget.data);
        _parsing = false;
      }
    }
  }

  void _startAsyncParse(String data) {
    final extensionSet = widget.extensionSet;
    final generation = ++_generation;
    _parsing = true;
    final runner =
        widget.parseRunner ??
        (String d, md.ExtensionSet? ext) =>
            Isolate.run(() => _parseDocument(d, ext));
    runner(data, extensionSet).then((result) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _parsed = result;
        _parsing = false;
      });
    });
  }

  List<md.Node> _parse(String data) {
    return _parseDocument(data, widget.extensionSet);
  }

  static List<md.Node> _parseDocument(
    String data,
    md.ExtensionSet? extensionSet,
  ) {
    final document = md.Document(
      extensionSet: extensionSet ?? md.ExtensionSet.gitHubWeb,
    );
    return document.parseLines(const LineSplitter().convert(data));
  }

  @override
  Widget build(BuildContext context) {
    if (_parsing) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    final resolvedStyle = (widget.style ?? const PrismMarkdownStyle()).resolve(
      context,
    );
    final children = BlockBuilder(
      style: resolvedStyle,
      onLinkTap: widget.onLinkTap,
      highlighter: widget.highlighter,
      imageBuilder: widget.imageBuilder,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
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
}) => InlineBuilder(style: style, onLinkTap: onLinkTap).build(nodes);
