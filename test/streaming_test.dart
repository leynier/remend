import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('chunked streaming scenarios', () {
    test('should handle nested formatting cut mid-stream', () {
      expect(
        remend('This is **bold with *ital'),
        equals('This is **bold with *ital*'),
      );
      expect(remend('**bold _und'), equals('**bold _und_**'));
    });

    test('should handle headings with incomplete formatting', () {
      expect(
        remend('# Main Title\n## Subtitle with **emph'),
        equals('# Main Title\n## Subtitle with **emph**'),
      );
    });

    test('should handle blockquotes with incomplete formatting', () {
      expect(remend('> Quote with **bold'), equals('> Quote with **bold**'));
    });

    test('should handle tables with incomplete formatting', () {
      expect(
        remend('| Col1 | Col2 |\n|------|------|\n| **dat'),
        equals('| Col1 | Col2 |\n|------|------|\n| **dat**'),
      );
    });

    test('should handle complex nested structures from chunks', () {
      expect(
        remend('1. First item\n   - Nested with `code\n2. Second'),
        equals('1. First item\n   - Nested with `code\n2. Second`'),
      );
    });

    test('should handle multiple incomplete formats in one chunk', () {
      expect(remend('Text **bold `code'), equals('Text **bold `code**`'));
    });
  });

  group('real-world streaming chunks', () {
    test('should handle typical GPT response chunks', () {
      final chunks = [
        'Here is',
        'Here is a **bold',
        'Here is a **bold statement',
        'Here is a **bold statement** about',
        'Here is a **bold statement** about `code',
        'Here is a **bold statement** about `code`.',
      ];
      expect(remend(chunks[0]), equals('Here is'));
      expect(remend(chunks[1]), equals('Here is a **bold**'));
      expect(remend(chunks[2]), equals('Here is a **bold statement**'));
      expect(remend(chunks[3]), equals('Here is a **bold statement** about'));
      expect(
        remend(chunks[4]),
        equals('Here is a **bold statement** about `code`'),
      );
      expect(remend(chunks[5]), equals(chunks[5]));
    });

    test('should handle code explanation chunks', () {
      final chunks = [
        'To use this function',
        'To use this function, call `getData(',
        'To use this function, call `getData()` with',
      ];
      expect(remend(chunks[0]), equals(chunks[0]));
      expect(
        remend(chunks[1]),
        equals('To use this function, call `getData(`'),
      );
      expect(remend(chunks[2]), equals(chunks[2]));
    });
  });
}
