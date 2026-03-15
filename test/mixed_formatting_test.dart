import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('mixed formatting', () {
    test('should handle multiple formatting types', () {
      const text = '**bold** and *italic* and `code` and ~~strike~~';
      expect(remend(text), equals(text));
    });

    test('should complete multiple incomplete formats', () {
      expect(remend('**bold and *italic'), equals('**bold and *italic*'));
    });

    test('should handle nested formatting', () {
      const text = '**bold with *italic* inside**';
      expect(remend(text), equals(text));
    });

    test(
      'should prioritize link/image preservation over formatting completion',
      () {
        expect(
          remend('Text with [link and **bold'),
          equals('Text with [link and **bold](streamdown:incomplete-link)'),
        );
      },
    );

    test('should handle complex real-world markdown', () {
      const text =
          '# Heading\n\n**Bold text** with *italic* and `code`.\n\n- List item\n- Another item with ~~strike~~';
      expect(remend(text), equals(text));
    });

    test('should handle bold inside italic', () {
      expect(remend('*italic with **bold'), equals('*italic with **bold***'));
    });

    test('should handle code inside bold', () {
      expect(remend('**bold with `code'), equals('**bold with `code**`'));
    });

    test('should handle strikethrough with other formatting', () {
      expect(
        remend('~~strike with **bold'),
        equals('~~strike with **bold**~~'),
      );
    });

    test('should handle dollar sign inside other formatting', () {
      expect(remend(r'**bold with $x^2'), equals(r'**bold with $x^2**'));
    });

    test('should handle deeply nested incomplete formatting', () {
      expect(
        remend('**bold *italic `code ~~strike'),
        equals('**bold *italic `code ~~strike*`'),
      );
    });

    test('should preserve complete nested formatting', () {
      const text = '**bold *italic* text** and `code`';
      expect(remend(text), equals(text));
    });

    test('should handle mixed bold-italic formatting (#265)', () {
      expect(
        remend('**bold and *bold-italic***'),
        equals('**bold and *bold-italic***'),
      );
    });

    test('should close nested underscore italic before bold (#302)', () {
      expect(
        remend('combined **_bold and italic'),
        equals('combined **_bold and italic_**'),
      );
      expect(remend('**_text'), equals('**_text_**'));
      expect(remend('_italic and **bold'), equals('_italic and **bold**_'));
    });
  });
}
