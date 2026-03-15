import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('inline code formatting (`)', () {
    test('should complete incomplete inline code', () {
      expect(remend('Text with `code'), equals('Text with `code`'));
      expect(remend('`incomplete'), equals('`incomplete`'));
    });

    test('should keep complete inline code unchanged', () {
      const text = 'Text with `inline code`';
      expect(remend(text), equals(text));
    });

    test('should handle multiple inline code sections', () {
      const text = '`code1` and `code2`';
      expect(remend(text), equals(text));
    });

    test('should not complete backticks inside code blocks', () {
      const text = '```\ncode block with `backtick\n```';
      expect(remend(text), equals(text));
    });

    test('should handle incomplete code blocks correctly', () {
      const text = '```javascript\nconst x = `template';
      expect(remend(text), equals(text));
    });

    test('should handle inline triple backticks correctly', () {
      const text = '```python print("Hello, Sunnyvale!")```';
      expect(remend(text), equals(text));
    });

    test('should handle incomplete inline triple backticks', () {
      const text = '```python print("Hello, Sunnyvale!")``';
      expect(remend(text), equals('```python print("Hello, Sunnyvale!")```'));
    });

    test(
      'should not modify text with complete triple backticks at the end',
      () {
        const text = '```code```';
        expect(remend(text), equals(text));
        const text2 = '```code```\n';
        expect(remend(text2), equals(text2));
        // Even number of triple backticks with newlines are complete
        const text3 = '```\ncode\n```';
        expect(remend(text3), equals(text3));
        // Test the special case where text ends with ``` and has even count
        const text4 = '``````';
        expect(remend(text4), equals(text4));
        const text5 = 'text``````';
        expect(remend(text5), equals(text5));
      },
    );

    test(
      'should handle code block with incomplete inline code after (#302)',
      () {
        expect(
          remend('```\nblock\n```\n`inline'),
          equals('```\nblock\n```\n`inline`'),
        );
      },
    );
  });

  group('escaped backticks in inline code', () {
    test('should not treat escaped backticks as code delimiters', () {
      // \` is not a real backtick delimiter, so **bold should still be completed
      expect(
        remend('\\`not code\\` **bold'),
        equals('\\`not code\\` **bold**'),
      );
    });

    test(
      'should complete emphasis when only escaped backticks are present',
      () {
        expect(remend('\\` *italic'), equals('\\` *italic*'));
      },
    );
  });

  group('emphasis markers inside inline code spans should not leak', () {
    test(
      'should not complete bold/italic/strikethrough if they are inside inline code',
      () {
        expect(remend('`**bold`'), equals('`**bold`'));
        expect(remend('`*italic`'), equals('`*italic`'));
        expect(remend('`~~strikethrough`'), equals('`~~strikethrough`'));
      },
    );

    test('should still complete emphasis markers outside inline code', () {
      expect(remend('**bold'), equals('**bold**'));
      expect(remend('*italic'), equals('*italic*'));
      expect(remend('~~strike'), equals('~~strike~~'));
    });

    test('should complete emphasis after a closed inline code span', () {
      expect(remend('`code` **bold'), equals('`code` **bold**'));
    });
  });
}
