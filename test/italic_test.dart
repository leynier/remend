import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('italic formatting with underscores (__)', () {
    test(
      'should complete incomplete italic formatting with double underscores',
      () {
        expect(remend('Text with __italic'), equals('Text with __italic__'));
        expect(remend('__incomplete'), equals('__incomplete__'));
      },
    );

    test('should keep complete italic formatting unchanged', () {
      const text = 'Text with __italic text__';
      expect(remend(text), equals(text));
    });

    test('should handle odd number of double underscore pairs', () {
      expect(
        remend('__first__ and __second'),
        equals('__first__ and __second__'),
      );
    });

    test('should complete half-complete __ closing marker (#313)', () {
      // When streaming __bold__, the closing marker arrives char by char
      // __bold text_ is a half-complete closing marker
      expect(remend('__xxx_'), equals('__xxx__'));
      expect(remend('__bold text_'), equals('__bold text__'));
      expect(remend('Text with __bold_'), equals('Text with __bold__'));
      expect(remend('This is __bold text_'), equals('This is __bold text__'));
    });
  });

  group('italic formatting with asterisks (*)', () {
    test(
      'should complete incomplete italic formatting with single asterisks',
      () {
        expect(remend('Text with *italic'), equals('Text with *italic*'));
        expect(remend('*incomplete'), equals('*incomplete*'));
      },
    );

    test('should keep complete italic formatting unchanged', () {
      const text = 'Text with *italic text*';
      expect(remend(text), equals(text));
    });

    test('should not confuse single asterisks with bold markers', () {
      expect(remend('**bold** and *italic'), equals('**bold** and *italic*'));
    });

    test(
      'should not treat asterisks in the middle of words as italic markers - #189',
      () {
        expect(remend('234234*123'), equals('234234*123'));
        expect(remend('hello*world'), equals('hello*world'));
        expect(remend('test*123*test'), equals('test*123*test'));
        // Test with mix of word-internal and formatting asterisks
        expect(
          remend('*italic with some*var*name inside'),
          equals('*italic with some*var*name inside*'),
        );
        expect(
          remend('test*var and *incomplete italic'),
          equals('test*var and *incomplete italic*'),
        );
      },
    );

    test(
      'should handle escaped asterisks correctly in countSingleAsterisks',
      () {
        // Test: escaped asterisks should be skipped
        expect(
          remend('\\*escaped asterisk and *italic'),
          equals('\\*escaped asterisk and *italic*'),
        );
        expect(
          remend('*start \\* middle \\* end'),
          equals('*start \\* middle \\* end*'),
        );
      },
    );

    test('should handle asterisks between letters and numbers', () {
      expect(remend('abc*123'), equals('abc*123'));
      expect(remend('123*abc'), equals('123*abc'));
    });

    test(
      'should still complete italic formatting with asterisks when not word-internal',
      () {
        expect(remend('This is *italic'), equals('This is *italic*'));
        expect(remend('*word* and more text'), equals('*word* and more text'));
      },
    );
  });

  group('italic formatting with single underscores (_)', () {
    test(
      'should complete incomplete italic formatting with single underscores',
      () {
        expect(remend('Text with _italic'), equals('Text with _italic_'));
        expect(remend('_incomplete'), equals('_incomplete_'));
      },
    );

    test('should keep complete italic formatting unchanged', () {
      const text = 'Text with _italic text_';
      expect(remend(text), equals(text));
    });

    test(
      'should not confuse single underscores with double underscore markers',
      () {
        expect(remend('__bold__ and _italic'), equals('__bold__ and _italic_'));
      },
    );

    test('should handle escaped single underscores', () {
      const text = 'Text with \\_escaped underscore';
      expect(remend(text), equals(text));
      const text2 = 'some\\_text_with_underscores';
      expect(remend(text2), equals('some\\_text_with_underscores'));
    });

    test('should handle mixed escaped and unescaped underscores correctly', () {
      expect(
        remend('\\_escaped\\_ and _unescaped'),
        equals('\\_escaped\\_ and _unescaped_'),
      );
      expect(
        remend('Start \\_escaped\\_ middle _incomplete'),
        equals('Start \\_escaped\\_ middle _incomplete_'),
      );
      expect(remend('\\_fully\\_escaped\\_'), equals('\\_fully\\_escaped\\_'));
      expect(
        remend('\\_escaped\\_ _complete_ pair'),
        equals('\\_escaped\\_ _complete_ pair'),
      );
    });

    test('should handle underscores with unicode word characters', () {
      expect(remend('café_price'), equals('café_price'));
      expect(remend('naïve_approach'), equals('naïve_approach'));
    });

    test(
      'should not count word-internal single underscores in countSingleUnderscores',
      () {
        expect(remend('some_variable_name'), equals('some_variable_name'));
        expect(remend('test_123_value'), equals('test_123_value'));
        expect(
          remend('_start with underscore'),
          equals('_start with underscore_'),
        );
        // Test with mix of word-internal and formatting underscores
        expect(
          remend('_italic with some_var_name inside'),
          equals('_italic with some_var_name inside_'),
        );
        expect(
          remend('test_var and _incomplete italic'),
          equals('test_var and _incomplete italic_'),
        );
      },
    );

    test(
      'should handle incomplete single underscore with trailing newlines',
      () {
        expect(remend('Text with _italic\n'), equals('Text with _italic_\n'));
        expect(remend('_incomplete\n\n'), equals('_incomplete_\n\n'));
        expect(remend('Start _text\n'), equals('Start _text_\n'));
      },
    );
  });
}
