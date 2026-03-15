import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('word-internal underscores', () {
    group('underscores as word separators', () {
      test('should handle single underscore between words', () {
        expect(remend('hello_world'), equals('hello_world'));
      });

      test('should handle multiple underscores between words', () {
        expect(remend('hello_world_test'), equals('hello_world_test'));
      });

      test('should handle CONSTANT_CASE', () {
        expect(remend('MAX_VALUE'), equals('MAX_VALUE'));
      });

      test('should handle multiple snake_case words in text', () {
        const input = 'The user_name and user_email are required';
        expect(remend(input), equals(input));
      });

      test('should handle underscore in URLs', () {
        const input = 'Visit https://example.com/path_with_underscore';
        expect(remend(input), equals(input));
      });

      test('should handle numbers with underscores', () {
        const input = 'The value is 1_000_000';
        expect(remend(input), equals(input));
      });
    });

    group('incomplete italic formatting', () {
      test('should complete italic at word boundary', () {
        expect(remend('_italic text'), equals('_italic text_'));
      });

      test('should complete italic with punctuation', () {
        expect(remend('This is _italic'), equals('This is _italic_'));
      });

      test('should complete italic before newline', () {
        expect(remend('_italic\n'), equals('_italic_\n'));
      });
    });

    group('edge cases', () {
      test('should handle underscore at end of word (ambiguous case)', () {
        expect(remend('word_'), equals('word_'));
      });

      test('should handle leading underscore in identifier', () {
        expect(remend('_privateVariable'), equals('_privateVariable_'));
      });

      test('should handle code with underscores in markdown', () {
        const input = 'Use `variable_name` in your code';
        expect(remend(input), equals(input));
      });

      test('should handle mixed snake_case and italic', () {
        const input = 'The variable_name is _important';
        expect(remend(input), equals('The variable_name is _important_'));
      });

      test('should not modify complete italic pairs', () {
        const input = '_complete italic_ and some_other_text';
        expect(remend(input), equals(input));
      });

      test('should handle underscore in code blocks', () {
        const input = '```\nfunction_name()\n```';
        expect(remend(input), equals(input));
      });

      test('should handle HTML attributes with underscores', () {
        const input = '<div data_attribute="value">';
        expect(remend(input), equals(input));
      });
    });

    group('real-world scenarios', () {
      test('should handle Python-style names', () {
        const input = '__init__ and __main__ are special';
        expect(remend(input), equals(input));
      });

      test('should handle markdown in sentences with snake_case', () {
        const input =
            'The user_id field stores the _unique identifier';
        expect(
          remend(input),
          equals('The user_id field stores the _unique identifier_'),
        );
      });

      test('should handle the original bug report case', () {
        const input = 'hello_world\n\n<a href="example_link"/>';
        final result = remend(input);
        expect(result, equals(input));
        expect(result, isNot(matches(RegExp(r'hello_world_'))));
        expect(result, isNot(matches(RegExp(r'_$'))));
      });
    });
  });
}
