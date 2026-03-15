import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('horizontal rule handling', () {
    test('should preserve complete horizontal rules with hyphens', () {
      expect(remend('---'), equals('---'));
      expect(remend('----'), equals('----'));
      expect(remend('-----'), equals('-----'));
    });

    test('should preserve complete horizontal rules with asterisks', () {
      expect(remend('***'), equals('***'));
      expect(remend('****'), equals('****'));
      expect(remend('*****'), equals('*****'));
    });

    test('should preserve complete horizontal rules with underscores', () {
      expect(remend('___'), equals('___'));
      expect(remend('____'), equals('____'));
      expect(remend('_____'), equals('_____'));
    });

    test('should preserve horizontal rules with spaces', () {
      expect(remend('- - -'), equals('- - -'));
      expect(remend('* * *'), equals('* * *'));
      expect(remend('_ _ _'), equals('_ _ _'));
    });

    test('should preserve horizontal rules with mixed spacing', () {
      expect(remend('-  -  -'), equals('-  -  -'));
      expect(remend('*   *   *'), equals('*   *   *'));
      expect(remend('_    _    _'), equals('_    _    _'));
    });

    test('should not confuse horizontal rules with emphasis', () {
      expect(
        remend('Text before\n***\nText after'),
        equals('Text before\n***\nText after'),
      );
      expect(
        remend('Text before\n___\nText after'),
        equals('Text before\n___\nText after'),
      );
    });

    test('should handle horizontal rules at the end of text', () {
      expect(remend('Some text\n\n---'), equals('Some text\n\n---'));
      expect(remend('Some text\n\n***'), equals('Some text\n\n***'));
      expect(remend('Some text\n\n___'), equals('Some text\n\n___'));
    });

    test('should handle horizontal rules at the start of text', () {
      expect(remend('---\n\nSome text'), equals('---\n\nSome text'));
      expect(remend('***\n\nSome text'), equals('***\n\nSome text'));
      expect(remend('___\n\nSome text'), equals('___\n\nSome text'));
    });

    test('should handle multiple horizontal rules', () {
      expect(
        remend('Section 1\n\n---\n\nSection 2\n\n---\n\nSection 3'),
        equals('Section 1\n\n---\n\nSection 2\n\n---\n\nSection 3'),
      );
    });

    test('should not confuse two asterisks with horizontal rule start', () {
      expect(remend('Text with **bold'), equals('Text with **bold**'));
    });

    test('should not confuse two hyphens with horizontal rule', () {
      expect(remend('Text with --'), equals('Text with --'));
    });

    test('should handle horizontal rules after lists', () {
      const text = '- Item 1\n- Item 2\n\n---\n\nNew section';
      expect(remend(text), equals(text));
    });

    test('should handle horizontal rules before headings', () {
      const text = '---\n\n# Heading';
      expect(remend(text), equals(text));
    });

    test('should handle partial horizontal rules during streaming', () {
      expect(remend('--'), equals('--'));
      expect(remend('**'), equals('**'));
      expect(remend('__'), equals('__'));
      expect(remend('Text\n\n--'), equals('Text\n\n--'));
    });

    test(
      'should not add closing markers to standalone asterisk sequences that could be rules',
      () {
        expect(remend('****'), equals('****'));
        expect(remend('*****'), equals('*****'));
      },
    );

    test('should handle horizontal rules with leading whitespace', () {
      expect(remend('   ---'), equals('   ---'));
      expect(remend('  ***'), equals('  ***'));
      expect(remend(' ___'), equals(' ___'));
    });

    test('should handle horizontal rule-like patterns in text', () {
      expect(
        remend('This is not a --- horizontal rule'),
        equals('This is not a --- horizontal rule'),
      );
    });

    test(
      'should not complete emphasis when asterisks form potential horizontal rule',
      () {
        expect(remend('Text\n***'), equals('Text\n***'));
      },
    );

    test('should handle horizontal rules in complex markdown', () {
      const text =
          '# Title\n\nSome content with **bold** text.\n\n---\n\n## Section 2\n\nMore content.';
      expect(remend(text), equals(text));
    });
  });
}
