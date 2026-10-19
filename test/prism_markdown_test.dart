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
  });
}
