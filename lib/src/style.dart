import 'package:flutter/material.dart';

/// Visual configuration for [PrismMarkdown] widgets.
///
/// Every field is optional; unset fields fall back to values derived from the
/// ambient [ThemeData].
@immutable
class PrismMarkdownStyle {
  /// Creates a style configuration.
  const PrismMarkdownStyle({
    this.headingStyle,
    this.codeStyle,
    this.codeBackground,
    this.codeblockBackground,
    this.codeblockPadding,
    this.blockquoteDecoration,
    this.blockquotePadding,
    this.tableBorder,
    this.tableHeaderBackground,
    this.linkStyle,
    this.listPadding,
    this.horizontalRuleThickness,
    this.horizontalRuleColor,
    this.textStyle,
  });

  /// Base text style applied to paragraph text.
  final TextStyle? textStyle;

  /// Text style applied to headings level 1 through 6 (indexed 0..5).
  /// When an entry is null it is derived from [TextTheme].
  final List<TextStyle?>? headingStyle;

  /// Text style for inline code spans.
  final TextStyle? codeStyle;

  /// Background color behind inline code spans.
  final Color? codeBackground;

  /// Background color of fenced code blocks.
  final Color? codeblockBackground;

  /// Padding around fenced code blocks.
  final EdgeInsetsGeometry? codeblockPadding;

  /// Decoration for blockquotes.
  final Decoration? blockquoteDecoration;

  /// Padding around blockquotes.
  final EdgeInsetsGeometry? blockquotePadding;

  /// Border surrounding GFM tables.
  final TableBorder? tableBorder;

  /// Background color of table header rows.
  final Color? tableHeaderBackground;

  /// Text style applied to link text.
  final TextStyle? linkStyle;

  /// Padding around lists.
  final EdgeInsetsGeometry? listPadding;

  /// Thickness of horizontal rules.
  final double? horizontalRuleThickness;

  /// Color of horizontal rules.
  final Color? horizontalRuleColor;

  /// Returns a copy of this style with the given fields replaced.
  PrismMarkdownStyle copyWith({
    TextStyle? textStyle,
    List<TextStyle?>? headingStyle,
    TextStyle? codeStyle,
    Color? codeBackground,
    Color? codeblockBackground,
    EdgeInsetsGeometry? codeblockPadding,
    Decoration? blockquoteDecoration,
    EdgeInsetsGeometry? blockquotePadding,
    TableBorder? tableBorder,
    Color? tableHeaderBackground,
    TextStyle? linkStyle,
    EdgeInsetsGeometry? listPadding,
    double? horizontalRuleThickness,
    Color? horizontalRuleColor,
  }) {
    return PrismMarkdownStyle(
      textStyle: textStyle ?? this.textStyle,
      headingStyle: headingStyle ?? this.headingStyle,
      codeStyle: codeStyle ?? this.codeStyle,
      codeBackground: codeBackground ?? this.codeBackground,
      codeblockBackground: codeblockBackground ?? this.codeblockBackground,
      codeblockPadding: codeblockPadding ?? this.codeblockPadding,
      blockquoteDecoration: blockquoteDecoration ?? this.blockquoteDecoration,
      blockquotePadding: blockquotePadding ?? this.blockquotePadding,
      tableBorder: tableBorder ?? this.tableBorder,
      tableHeaderBackground:
          tableHeaderBackground ?? this.tableHeaderBackground,
      linkStyle: linkStyle ?? this.linkStyle,
      listPadding: listPadding ?? this.listPadding,
      horizontalRuleThickness:
          horizontalRuleThickness ?? this.horizontalRuleThickness,
      horizontalRuleColor: horizontalRuleColor ?? this.horizontalRuleColor,
    );
  }

  /// Resolves unset fields against the ambient [ThemeData].
  PrismMarkdownStyle resolve(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final codeColor = theme.colorScheme.surfaceContainerHighest;
    final headings = <TextStyle>[
      for (var i = 0; i < 6; i++)
        TextStyle(
          inherit: false,
          color: base.color,
          fontSize: base.fontSize! * (1.75 - 0.13 * i),
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
    ];
    return PrismMarkdownStyle(
      textStyle: textStyle ?? base,
      headingStyle: headingStyle ?? headings,
      codeStyle:
          codeStyle ??
          (base.copyWith(
            fontFamily: 'monospace',
            fontSize: base.fontSize! * 0.9,
            background: Paint()..color = codeColor,
          )),
      codeBackground: codeBackground ?? codeColor,
      codeblockBackground: codeblockBackground ?? codeColor,
      codeblockPadding: codeblockPadding ?? const EdgeInsets.all(12),
      blockquoteDecoration:
          blockquoteDecoration ??
          BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.dividerColor, width: 4),
            ),
          ),
      blockquotePadding:
          blockquotePadding ??
          const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      tableBorder:
          tableBorder ?? TableBorder.all(color: theme.dividerColor, width: 1),
      tableHeaderBackground:
          tableHeaderBackground ?? theme.colorScheme.surfaceContainerHighest,
      linkStyle:
          linkStyle ??
          base.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
      listPadding: listPadding ?? EdgeInsets.zero,
      horizontalRuleThickness: horizontalRuleThickness ?? 1,
      horizontalRuleColor: horizontalRuleColor ?? theme.dividerColor,
    );
  }
}
