import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('edge cases', () {
    test('should handle text ending with formatting characters', () {
      expect(remend('Text ending with *'), equals('Text ending with *'));
      expect(remend('Text ending with **'), equals('Text ending with **'));
    });

    test('should handle empty formatting markers', () {
      expect(remend('****'), equals('****'));
      expect(remend('``'), equals('``'));
    });

    test('should handle standalone emphasis characters (#90)', () {
      // Standalone markers should not be auto-closed
      expect(remend('**'), equals('**'));
      expect(remend('__'), equals('__'));
      expect(remend('***'), equals('***'));
      expect(remend('*'), equals('*'));
      expect(remend('_'), equals('_'));
      expect(remend('~~'), equals('~~'));
      expect(remend('`'), equals('`'));
      // Multiple standalone markers on the same line
      expect(remend('** __'), equals('** __'));
      expect(remend('\n** __\n'), equals('\n** __\n'));
      expect(remend('* _ ~~ `'), equals('* _ ~~ `'));
      // Standalone markers with only whitespace
      expect(remend('** '), equals('**')); // Trailing single space removed
      expect(remend(' **'), equals(' **'));
      expect(
        remend('  **  '),
        equals('  **  '),
      ); // Trailing double space preserved as line break
      // But markers with actual content should still be closed
      expect(remend('**text'), equals('**text**'));
      expect(remend('__text'), equals('__text__'));
      expect(remend('*text'), equals('*text*'));
      expect(remend('_text'), equals('_text_'));
      expect(remend('~~text'), equals('~~text~~'));
      expect(remend('`text'), equals('`text`'));
    });

    test('should handle very long text', () {
      final longText = '${'a' * 10000} **bold';
      final expected = '${'a' * 10000} **bold**';
      expect(remend(longText), equals(expected));
    });

    test('should handle text with only formatting characters', () {
      expect(remend('*'), equals('*'));
      expect(remend('**'), equals('**'));
      expect(remend('`'), equals('`'));
    });

    test('should handle escaped characters', () {
      const text = 'Text with \\* escaped asterisk';
      expect(remend(text), equals(text));
    });

    test('should handle markdown at very end of string', () {
      expect(remend('text**'), equals('text**'));
      expect(remend('text*'), equals('text*'));
      expect(remend('text`'), equals('text`'));
      expect(remend(r'text$'), equals(r'text$'));
      expect(remend('text~~'), equals('text~~'));
    });

    test('should handle whitespace before incomplete markdown', () {
      expect(remend('text **bold'), equals('text **bold**'));
      expect(remend('text\n**bold'), equals('text\n**bold**'));
      expect(remend('text\t`code'), equals('text\t`code`'));
    });

    test('should handle unicode characters in incomplete markdown', () {
      expect(remend('**émoji \u{1F389}'), equals('**émoji \u{1F389}**'));
      expect(remend('`código'), equals('`código`'));
    });

    test('should handle HTML entities in incomplete markdown', () {
      expect(remend('**&lt;tag&gt;'), equals('**&lt;tag&gt;**'));
      expect(remend('`&amp;'), equals('`&amp;`'));
    });

    test(
      'should not treat asterisks flanked by whitespace as emphasis markers (#370)',
      () {
        expect(remend('3 + 2 - 5 * 0 = ?'), equals('3 + 2 - 5 * 0 = ?'));
        expect(remend('5 * 0'), equals('5 * 0'));
        expect(remend('x * y'), equals('x * y'));
        expect(remend('a * b = c'), equals('a * b = c'));
        // Even count of space-flanked asterisks should also be fine
        expect(remend('2 * 3 * 4'), equals('2 * 3 * 4'));
        // Mixed: space-flanked operator + real italic should still work
        expect(remend('5 * 0 and *italic'), equals('5 * 0 and *italic*'));
      },
    );
  });
}
