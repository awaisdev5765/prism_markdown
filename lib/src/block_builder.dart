import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

import 'inline_builder.dart';
import 'style.dart';

/// Converts block-level markdown nodes into a list of Flutter widgets.
class BlockBuilder {
  /// Creates a block builder.
  BlockBuilder({
    required this.style,
    this.onLinkTap,
    this.highlighter,
    this.imageBuilder,
    this.maxLines,
    this.overflow,
  });

  /// Resolved visual style.
  final PrismMarkdownStyle style;

  /// Called when the user taps a link.
  final void Function(String href)? onLinkTap;

  /// Custom syntax highlighter for fenced code blocks.
  final TextSpan Function(String code, String language)? highlighter;

  /// Custom builder for inline images.
  final Widget Function(String src, String alt, Widget fallback)? imageBuilder;

  /// Maximum number of lines for text blocks. See [PrismMarkdown.maxLines].
  final int? maxLines;

  /// How truncated text overflow is handled. See [PrismMarkdown.overflow].
  final TextOverflow? overflow;

  /// Builds a [Text.rich] widget applying the [maxLines]/[overflow]
  /// constraints, if set.
  Text _text(InlineSpan span, TextStyle? style) {
    if (maxLines == null) return Text.rich(span, style: style);
    return Text.rich(
      span,
      style: style,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }

  /// Builds widgets from block [nodes].
  List<Widget> build(List<md.Node> nodes) {
    final widgets = <Widget>[];
    for (final node in nodes) {
      final widget = _visit(node);
      if (widget != null) {
        widgets.add(widget);
      }
    }
    return widgets;
  }

  Widget? _visit(md.Node node) {
    if (node is! md.Element) {
      return null;
    }
    switch (node.tag) {
      case 'h1':
        return _heading(node, 0);
      case 'h2':
        return _heading(node, 1);
      case 'h3':
        return _heading(node, 2);
      case 'h4':
        return _heading(node, 3);
      case 'h5':
        return _heading(node, 4);
      case 'h6':
        return _heading(node, 5);
      case 'p':
        return _paragraph(node);
      case 'blockquote':
        return _blockquote(node);
      case 'pre':
        return _codeBlock(node);
      case 'ul':
        return _list(node, ordered: false);
      case 'ol':
        return _list(node, ordered: true);
      case 'table':
        return _table(node);
      case 'hr':
        return _horizontalRule();
      default:
        return _paragraph(node);
    }
  }

  Widget _heading(md.Element node, int level) {
    final headings = style.headingStyle!;
    final effective = (headings[level] ?? const TextStyle()).merge(
      const TextStyle(height: 1.25),
    );
    return Padding(
      padding: EdgeInsets.only(top: level == 0 ? 8 : 12, bottom: 6),
      child: _text(_inlines(node), effective),
    );
  }

  Widget _paragraph(md.Element node) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _text(_inlines(node), style.textStyle),
    );
  }

  Widget _blockquote(md.Element node) {
    final children = BlockBuilder(
      style: style,
      onLinkTap: onLinkTap,
      highlighter: highlighter,
      imageBuilder: imageBuilder,
    ).build(node.children ?? const []);
    return Container(
      decoration: style.blockquoteDecoration,
      padding: style.blockquotePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _codeBlock(md.Element node) {
    final code = node.children?.firstOrNull;
    var text = '';
    var language = '';
    if (code is md.Element && code.tag == 'code') {
      text = code.textContent;
      language = code.attributes['class']?.replaceAll('language-', '') ?? '';
    } else {
      text = node.textContent;
    }
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
    final highlighted = highlighter?.call(text, language);
    // The container already paints the codeblock background; adding a
    // background Paint on the text would double-paint and clash with
    // highlighter colors. Selection is handled by the ambient SelectionArea.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.codeblockBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: style.codeblockPadding,
      child: Text.rich(
        highlighted ?? TextSpan(text: text, style: style.codeStyle),
      ),
    );
  }

  Widget _list(md.Element node, {required bool ordered}) {
    final items = <Widget>[];
    var index = 0;
    for (final child in node.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'li') {
        index++;
        final marker = ordered ? '$index.' : '\u2022';
        final isTask =
            child.attributes.containsKey('class') &&
            child.attributes['class']!.contains('task-list-item');
        String? checkbox;
        var checked = false;
        var itemChildren = child.children ?? const <md.Node>[];
        if (isTask && itemChildren.isNotEmpty) {
          final first = itemChildren.first;
          if (first is md.Element && first.tag == 'input') {
            // TaskListExtension emits <input type=checkbox checked?> nodes.
            checked = first.attributes['checked'] == 'true' ||
                first.attributes.containsKey('checked');
            checkbox = 'task'; // sentinel: render as a checkbox icon below
            itemChildren = itemChildren.skip(1).toList();
          } else {
            // Legacy fallback: raw "[x]" text prefix.
            final checkboxText = first.textContent;
            checked = checkboxText.trim().startsWith('[x]');
            checkbox = 'task';
            if (first is md.Element && first.tag == 'p') {
              final txt = first.textContent;
              itemChildren = [
                md.Text(txt.replaceFirst(RegExp(r'^\[[ xX]\]\s*'), '')),
                ...itemChildren.skip(1),
              ];
            }
          }
        }
        // Loose list items are wrapped in a paragraph; tight list items
        // keep raw text nodes. Normalize to paragraph-style inline content.
        final contentNodes = <md.Node>[];
        for (final n in itemChildren) {
          if (n is md.Element && n.tag == 'p') {
            contentNodes.addAll(n.children ?? const <md.Node>[]);
          } else {
            contentNodes.add(n);
          }
        }
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: checkbox != null ? 24 : (ordered ? 28 : 16),
                  child: checkbox != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: checked,
                              onChanged: null,
                            ),
                          ),
                        )
                      : Text(marker, style: style.textStyle),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: _text(
                      InlineBuilder(
                        style: style,
                        onLinkTap: onLinkTap,
                        highlighter: highlighter,
                        imageBuilder: imageBuilder,
                      ).build(contentNodes),
                      style.textStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return Padding(
      padding: style.listPadding!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: items,
      ),
    );
  }

  Widget _table(md.Element node) {
    final rows = <TableRow>[];
    for (final child in node.children ?? const <md.Node>[]) {
      if (child is md.Element &&
          (child.tag == 'thead' || child.tag == 'tbody')) {
        for (final tr in child.children ?? const <md.Node>[]) {
          if (tr is md.Element && tr.tag == 'tr') {
            final cells = <Widget>[];
            final isHeader = child.tag == 'thead';
            for (final td in tr.children ?? const <md.Node>[]) {
              if (td is md.Element && (td.tag == 'td' || td.tag == 'th')) {
                cells.add(
                  Container(
                    color: isHeader ? style.tableHeaderBackground : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: _text(
                      _inlines(td),
                      isHeader
                          ? (style.textStyle?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ) ??
                                const TextStyle(fontWeight: FontWeight.bold))
                          : style.textStyle,
                    ),
                  ),
                );
              }
            }
            rows.add(TableRow(children: cells));
          }
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Table(border: style.tableBorder, children: rows),
    );
  }

  Widget _horizontalRule() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        thickness: style.horizontalRuleThickness,
        color: style.horizontalRuleColor,
      ),
    );
  }

  InlineSpan _inlines(md.Element node) => InlineBuilder(
    style: style,
    onLinkTap: onLinkTap,
    highlighter: highlighter,
    imageBuilder: imageBuilder,
  ).build(node.children ?? const []);
}
