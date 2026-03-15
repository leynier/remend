import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('comparison operators in list items (#376)', () {
    test('should escape > followed by a digit in dash list items', () {
      expect(remend('- > 25: rich'), equals('- \\> 25: rich'));
    });

    test('should escape > followed by a digit in asterisk list items', () {
      expect(remend('* > 25: rich'), equals('* \\> 25: rich'));
    });

    test('should escape > followed by a digit in plus list items', () {
      expect(remend('+ > 25: rich'), equals('+ \\> 25: rich'));
    });

    test('should escape > in ordered list items', () {
      expect(remend('1. > 25: rich'), equals('1. \\> 25: rich'));
      expect(remend('2) > 10: high'), equals('2) \\> 10: high'));
    });

    test('should escape > in indented (nested) list items', () {
      expect(remend('  - > 25: rich'), equals('  - \\> 25: rich'));
      expect(remend('    - > 5: expensive'), equals('    - \\> 5: expensive'));
    });

    test('should escape >= comparison operators', () {
      expect(remend('- >= 10: high'), equals('- \\>= 10: high'));
    });

    test('should escape > before dollar amounts', () {
      expect(remend(r'- > $100: expensive'), equals(r'- \> $100: expensive'));
    });

    test('should handle the issue example correctly', () {
      final input = [
        '- < 10: potentially cheap.',
        '- 10–20: reasonable/normal zone.',
        '- > 25–30: rich; you need strong growth + quality to justify.',
      ].join('\n');
      final expected = [
        '- < 10: potentially cheap.',
        '- 10–20: reasonable/normal zone.',
        '- \\> 25–30: rich; you need strong growth + quality to justify.',
      ].join('\n');
      expect(remend(input), equals(expected));
    });

    test('should handle multiple comparison operators in a list', () {
      final input = ['- > 5: expensive', '- > 25: very expensive'].join('\n');
      final expected = [
        '- \\> 5: expensive',
        '- \\> 25: very expensive',
      ].join('\n');
      expect(remend(input), equals(expected));
    });

    test('should not escape > in actual blockquotes (no list marker)', () {
      expect(remend('> Some blockquote'), equals('> Some blockquote'));
      expect(remend('> 25 is a number'), equals('> 25 is a number'));
    });

    test('should not escape > when followed by non-digit text', () {
      expect(remend('- > Some quoted text'), equals('- > Some quoted text'));
      expect(
        remend('- > Read more about this'),
        equals('- > Read more about this'),
      );
    });

    test(
      'should not escape > without a space before digit (no list marker)',
      () {
        expect(remend('>25'), equals('>25'));
      },
    );

    test('should not escape > inside code blocks', () {
      const input = '```\n- > 25: in code\n```';
      expect(remend(input), equals(input));
    });

    test('should handle > with no space before digit in list items', () {
      expect(remend('- >25: rich'), equals('- \\>25: rich'));
    });

    test('should be disabled when comparisonOperators option is false', () {
      expect(
        remend('- > 25: rich', RemendOptions(comparisonOperators: false)),
        equals('- > 25: rich'),
      );
    });

    test('should work alongside other remend handlers', () {
      const input = '- > 25: **bold';
      final result = remend(input);
      expect(result, equals('- \\> 25: **bold**'));
    });

    test('should handle the full issue example with nested lists', () {
      final input = [
        '*P/E*',
        '  - < 10: potentially cheap.',
        '  - 10–20: reasonable/normal zone.',
        '  - > 25–30: rich; you need strong growth.',
        '',
        '*P/S*',
        '  - < 1: often cheap for mature businesses.',
        '  - 1–3: okay range.',
        '  - > 5: expensive unless high-margin.',
      ].join('\n');
      final expected = [
        '*P/E*',
        '  - < 10: potentially cheap.',
        '  - 10–20: reasonable/normal zone.',
        '  - \\> 25–30: rich; you need strong growth.',
        '',
        '*P/S*',
        '  - < 1: often cheap for mature businesses.',
        '  - 1–3: okay range.',
        '  - \\> 5: expensive unless high-margin.',
      ].join('\n');
      expect(remend(input), equals(expected));
    });
  });
}
