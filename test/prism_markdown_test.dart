import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_markdown/prism_markdown.dart';

void main() {
  group('PrismMarkdown rendering', () {
    Future<void> pumpMd(
      WidgetTester tester,
      String md, {
      void Function(String)? onLinkTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PrismMarkdown(md, onLinkTap: onLinkTap),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders headings', (tester) async {
      await pumpMd(tester, '# Big Title\n\n### Small Title');
      expect(find.text('Big Title'), findsOneWidget);
      expect(find.text('Small Title'), findsOneWidget);
    });

    testWidgets('renders bold and italic', (tester) async {
      await pumpMd(tester, 'Some **bold** and *italic* text');
      final text = tester.widget<Text>(find.byType(Text).first);
      final spans = text.textSpan! as TextSpan;
      final children = spans.children!;
      expect(
        children.any(
          (s) => s is TextSpan && s.style?.fontWeight == FontWeight.bold,
        ),
        isTrue,
      );
      expect(
        children.any(
          (s) => s is TextSpan && s.style?.fontStyle == FontStyle.italic,
        ),
        isTrue,
      );
    });

    testWidgets('renders lists', (tester) async {
      await pumpMd(tester, '- one\n- two\n\n1. first\n2. second');
      expect(find.textContaining('one'), findsOneWidget);
      expect(find.textContaining('two'), findsOneWidget);
      expect(find.textContaining('1.'), findsOneWidget);
      expect(find.textContaining('2.'), findsOneWidget);
    });

    testWidgets('renders tables', (tester) async {
      await pumpMd(tester, '| A | B |\n| - | - |\n| 1 | 2 |');
      expect(find.text('A'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('renders code blocks', (tester) async {
      await pumpMd(tester, '```\nvoid main() {}\n```');
      expect(find.text('void main() {}'), findsOneWidget);
    });

    testWidgets('renders blockquotes', (tester) async {
      await pumpMd(tester, '> quoted line');
      expect(find.text('quoted line'), findsOneWidget);
    });

    testWidgets('renders horizontal rules', (tester) async {
      await pumpMd(tester, 'before\n\n---\n\nafter');
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('link tap fires callback', (tester) async {
      String? tapped;
      await pumpMd(
        tester,
        '[click me](https://example.com)',
        onLinkTap: (href) => tapped = href,
      );
      final text = tester.widget<Text>(find.byType(Text).first);
      final root = text.textSpan! as TextSpan;
      TapGestureRecognizer? findRecognizer(TextSpan span) {
        if (span.recognizer is TapGestureRecognizer) {
          return span.recognizer! as TapGestureRecognizer;
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          if (child is TextSpan) {
            final found = findRecognizer(child);
            if (found != null) {
              return found;
            }
          }
        }
        return null;
      }

      final recognizer = findRecognizer(root);
      expect(recognizer, isA<TapGestureRecognizer>());
      recognizer!.onTap!();
      expect(tapped, 'https://example.com');
    });

    testWidgets('re-renders when data changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PrismMarkdown('Before **old**'))),
      );
      expect(find.textContaining('old'), findsOneWidget);

      // Simulate parent rebuilding with new data via a stateful wrapper.
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PrismMarkdown('After **new**'))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('old'), findsNothing);
      expect(find.textContaining('new'), findsOneWidget);
    });

    testWidgets('highlighter callback is used for fenced code', (tester) async {
      TextSpan highlighter(String code, String language) => TextSpan(
        text: code,
        style: TextStyle(color: language == 'dart' ? Colors.amber : null),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrismMarkdown(
              '```dart\nvoid main() {}\n```',
              highlighter: highlighter,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Find the RichText rendered by the code block and verify the
      // highlighter's style was applied (amber color for 'dart').
      final richTexts = tester
          .widgetList<RichText>(find.byType(RichText))
          .where((rt) => rt.text.toPlainText().contains('void main()'))
          .toList();
      expect(richTexts, isNotEmpty);
      // The highlighter's span is nested as a child of the root code-block
      // span, so walk the tree looking for the amber color.
      bool hasAmber(InlineSpan span) {
        if (span.style?.color == Colors.amber) return true;
        return span is TextSpan && (span.children?.any(hasAmber) ?? false);
      }

      expect(richTexts.any((rt) => hasAmber(rt.text)), isTrue);
    });

    testWidgets('imageBuilder callback receives src and alt', (tester) async {
      Widget build(String src, String alt, Widget fallback) =>
          Text('IMG:$src|$alt');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrismMarkdown(
              '![alt text](https://example.com/a.png)',
              imageBuilder: build,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('IMG:https://example.com/a.png|alt text'),
        findsOneWidget,
      );
    });
  });

  group('maxLines / overflow truncation', () {
    Future<void> pumpMd(
      WidgetTester tester,
      String md, {
      int? maxLines,
      TextOverflow? overflow,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PrismMarkdown(
                md,
                maxLines: maxLines,
                overflow: overflow,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Text? findFirstRichTextText() {
      final rich = find.byType(Text).evaluate().toList();
      for (final element in rich) {
        final widget = element.widget as Text;
        if (widget.maxLines != null) return widget;
      }
      return null;
    }

    testWidgets('paragraph without maxLines is unconstrained', (tester) async {
      await pumpMd(tester, 'Hello world');
      final text = tester.widget<Text>(find.text('Hello world'));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
    });

    testWidgets('paragraph with maxLines gets constraint and default ellipsis', (
      tester,
    ) async {
      await pumpMd(tester, 'Hello world', maxLines: 2);
      final text = findFirstRichTextText();
      expect(text, isNotNull);
      expect(text!.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('custom overflow is passed through', (tester) async {
      await pumpMd(
        tester,
        'Hello world',
        maxLines: 1,
        overflow: TextOverflow.fade,
      );
      final text = findFirstRichTextText();
      expect(text!.maxLines, 1);
      expect(text.overflow, TextOverflow.fade);
    });

    testWidgets('headings respect maxLines', (tester) async {
      await pumpMd(tester, '# Heading', maxLines: 1);
      final headings = find
          .byType(Text)
          .evaluate()
          .map((e) => e.widget as Text)
          .where((w) => w.maxLines == 1)
          .toList();
      expect(headings, isNotEmpty);
    });

    testWidgets('list items respect maxLines', (tester) async {
      await pumpMd(tester, '- item one\n- item two', maxLines: 3);
      final constrained = find
          .byType(Text)
          .evaluate()
          .map((e) => e.widget as Text)
          .where((w) => w.maxLines == 3)
          .toList();
      expect(constrained.length, 2);
    });

    testWidgets('code blocks are never truncated', (tester) async {
      await pumpMd(
        tester,
        '```dart\nvoid main() { print("hello"); }\n```',
        maxLines: 1,
      );
      final codeTexts = find
          .byType(Text)
          .evaluate()
          .map((e) => e.widget as Text)
          .where((w) => w.data != null && w.data!.contains('print'))
          .toList();
      for (final t in codeTexts) {
        expect(t.maxLines, isNull,
            reason: 'code blocks must not be constrained by maxLines');
      }
    });
  });
}
