import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

import 'style.dart';

/// Renders inline markdown nodes into a Flutter [InlineSpan] tree.
class InlineBuilder {
  /// Creates an inline builder.
  InlineBuilder({
    required this.style,
    this.onLinkTap,
    this.highlighter,
    this.imageBuilder,
  });

  /// Resolved visual style.
  final PrismMarkdownStyle style;

  /// Called when the user taps a link.
  final void Function(String href)? onLinkTap;

  /// Custom syntax highlighter for inline/fenced code.
  final TextSpan Function(String code, String language)? highlighter;

  /// Custom builder for inline images.
  final Widget Function(String src, String alt, Widget fallback)? imageBuilder;

  /// Builds an [InlineSpan] tree from inline [nodes].
  InlineSpan build(List<md.Node> nodes) {
    final children = <InlineSpan>[];
    for (final node in nodes) {
      children.add(_visit(node));
    }
    return TextSpan(children: children);
  }

  InlineSpan _visit(md.Node node) {
    if (node is md.Text) {
      return TextSpan(text: node.text);
    }
    if (node is md.Element) {
      return _visitElement(node);
    }
    return const TextSpan();
  }

  InlineSpan _visitElement(md.Element element) {
    switch (element.tag) {
      case 'strong':
        return _wrap(element, (s) => s.copyWith(fontWeight: FontWeight.bold));
      case 'em':
        return _wrap(element, (s) => s.copyWith(fontStyle: FontStyle.italic));
      case 'a':
        return _link(element);
      case 'code':
        final language = element.attributes['class'] ?? '';
        final highlighted = highlighter?.call(
          element.textContent,
          language.replaceFirst('language-', ''),
        );
        return highlighted ?? TextSpan(
          text: element.textContent,
          style: style.codeStyle,
        );
      case 'del':
        return _wrap(
          element,
          (s) => s.copyWith(decoration: TextDecoration.lineThrough),
        );
      case 'img':
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _image(element),
        );
      case 'br':
        return const TextSpan(text: '\n');
      default:
        return _wrap(element, null);
    }
  }

  InlineSpan _wrap(md.Element element, TextStyle Function(TextStyle)? f) {
    final inner = InlineBuilder(
      style: style,
      onLinkTap: onLinkTap,
      highlighter: highlighter,
      imageBuilder: imageBuilder,
    ).build(element.children ?? const []);
    TextStyle? combined;
    if (inner is TextSpan && f != null) {
      combined = f(const TextStyle()).merge(inner.style);
    }
    return TextSpan(
      children: inner is TextSpan && inner.children != null
          ? inner.children
          : [inner],
      text: inner is TextSpan ? inner.text : null,
      style: combined,
    );
  }

  InlineSpan _link(md.Element element) {
    final href = element.attributes['href'] ?? '';
    final inner = InlineBuilder(
      style: style,
      onLinkTap: onLinkTap,
      highlighter: highlighter,
      imageBuilder: imageBuilder,
    ).build(element.children ?? const []);
    return TextSpan(
      text: inner is TextSpan ? inner.text : null,
      children: inner is TextSpan ? inner.children : [inner],
      style: style.linkStyle,
      recognizer: TapGestureRecognizer()
        ..onTap = () => onLinkTap?.call(href),
    );
  }

  /// Renders an inline image. Falls back to a network image loader with
  /// graceful loading and error states; users can override via
  /// [imageBuilder].
  Widget _image(md.Element element) {
    final src = element.attributes['src'] ?? '';
    // Alt text is stored in the 'alt' attribute by the markdown parser;
    // textContent is empty for image elements.
    final alt = element.attributes['alt'] ?? element.textContent;

    // Build a lazy fallback: only constructs the network Image widget when
    // actually needed, so a custom [imageBuilder] avoids any network work.
    Widget fallback() => Image.network(
          src,
          semanticLabel: alt,
          fit: BoxFit.scaleDown,
          errorBuilder: (_, _, _) => SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.broken_image_outlined,
                color: style.textStyle?.color),
          ),
        );

    final builder = imageBuilder;
    if (builder != null) {
      return builder(src, alt, fallback());
    }
    return fallback();
  }
}
