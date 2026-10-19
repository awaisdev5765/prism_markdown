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
class PrismMarkdown extends StatefulWidget {
  /// Creates a markdown renderer.
  const PrismMarkdown(
    this.data, {
    super.key,
    this.style,
    this.extensionSet,
    this.onLinkTap,
    this.selectable = true,
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

  @override
  State<PrismMarkdown> createState() => _PrismMarkdownState();
}

class _PrismMarkdownState extends State<PrismMarkdown> {
  List<md.Node>? _parsed;

  List<md.Node> _parse() {
    final document = md.Document(
      extensionSet: widget.extensionSet ?? md.ExtensionSet.gitHubWeb,
    );
    return document.parseLines(
      const LineSplitter().convert(widget.data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        (widget.style ?? const PrismMarkdownStyle()).resolve(context);
    final parsed = _parsed ??= _parse();
    final children = BlockBuilder(
      style: resolvedStyle,
      onLinkTap: widget.onLinkTap,
    ).build(parsed);

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
