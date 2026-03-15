import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('setext heading handling', () {
    test(
      'should prevent partial list items from being interpreted as setext headings',
      () {
        const text = 'here is a list\n-';
        final result = remend(text);
        expect(result, equals('here is a list\n-\u200B'));
      },
    );

    test('should handle double dash that could be setext heading', () {
      const text = 'Some text\n--';
      final result = remend(text);
      expect(result, equals('Some text\n--\u200B'));
    });

    test('should handle single equals that could be setext heading', () {
      const text = 'Some text\n=';
      final result = remend(text);
      expect(result, equals('Some text\n=\u200B'));
    });

    test('should handle double equals that could be setext heading', () {
      const text = 'Some text\n==';
      final result = remend(text);
      expect(result, equals('Some text\n==\u200B'));
    });

    test('should NOT modify valid horizontal rules with three dashes', () {
      const text = 'Some text\n---';
      final result = remend(text);
      expect(result, equals('Some text\n---'));
    });

    test('should NOT modify valid setext headings with three equals', () {
      const text = 'Heading\n===';
      final result = remend(text);
      expect(result, equals('Heading\n==='));
    });

    test("should NOT modify when there's no previous content", () {
      const text = '-';
      final result = remend(text);
      expect(result, equals('-'));
    });

    test('should NOT modify when previous line is empty', () {
      const text = '\n-';
      final result = remend(text);
      expect(result, equals('\n-'));
    });

    test('should handle the streaming list scenario', () {
      final scenarios = [
        ('here is a list\n-', 'here is a list\n-\u200B'),
        ('here is a list\n- ', 'here is a list\n-\u200B'),
        ('here is a list\n- list item 1', 'here is a list\n- list item 1'),
      ];
      for (final (input, expected) in scenarios) {
        expect(remend(input), equals(expected));
      }
    });

    test(
      'should handle multiple lines with potential setext heading at end',
      () {
        const text = 'Line 1\nLine 2\nLine 3\n-';
        final result = remend(text);
        expect(result, equals('Line 1\nLine 2\nLine 3\n-\u200B'));
      },
    );

    test('should handle text with whitespace before dash', () {
      const text = 'Some text\n  -';
      final result = remend(text);
      expect(result, equals('Some text\n  -\u200B'));
    });

    test('should NOT modify complete list items', () {
      const text = 'Some text\n- Item 1\n- Item 2';
      final result = remend(text);
      expect(result, equals(text));
    });

    test('should NOT modify when last line has other characters', () {
      const text = 'Some text\n-x';
      final result = remend(text);
      expect(result, equals(text));
    });

    test('should handle four or more dashes (horizontal rule)', () {
      const text = 'Some text\n----';
      final result = remend(text);
      expect(result, equals(text));
    });

    test('should handle mixed whitespace and dashes', () {
      const text = 'Some text\n- ';
      final result = remend(text);
      expect(result, equals('Some text\n-\u200B'));
    });

    test('should handle the original issue example precisely', () {
      final streaming1 = remend('here is a list');
      expect(streaming1, equals('here is a list'));
      final streaming2 = remend('here is a list\n');
      expect(streaming2, equals('here is a list\n'));
      final streaming3 = remend('here is a list\n-');
      expect(streaming3, equals('here is a list\n-\u200B'));
      final streaming4 = remend('here is a list\n- list item 1');
      expect(streaming4, equals('here is a list\n- list item 1'));
    });

    test('should handle setext heading with equals signs during streaming', () {
      final streaming1 = remend('This is a title\n=');
      expect(streaming1, equals('This is a title\n=\u200B'));
      final streaming2 = remend('This is a title\n==');
      expect(streaming2, equals('This is a title\n==\u200B'));
      final streaming3 = remend('This is a title\n===');
      expect(streaming3, equals('This is a title\n==='));
    });

    test('should not interfere with other markdown syntax', () {
      const text1 = '**bold text**\n-';
      expect(remend(text1), equals('**bold text**\n-\u200B'));
      const text2 = '*italic text*\n-';
      expect(remend(text2), equals('*italic text*\n-\u200B'));
      const text3 = '`code`\n-';
      expect(remend(text3), equals('`code`\n-\u200B'));
    });

    test('should handle multiple potential setext headings in sequence', () {
      const text = 'Text 1\n-\nText 2\n-';
      final result = remend(text);
      expect(result, equals('Text 1\n-\nText 2\n-\u200B'));
    });
  });
}
