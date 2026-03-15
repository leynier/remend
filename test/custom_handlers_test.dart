import 'package:remend/remend.dart';
import 'package:test/test.dart';

// Regex pattern for joke marker matching (moved to top level for performance)
final _jokeMarkerPattern = RegExp(r'<<<JOKE>>>([^<]*)$');

void main() {
  group('custom handlers', () {
    test('should execute custom handlers', () {
      final handler = RemendHandler(
        name: 'test',
        handle: (text) => text.replaceAll('foo', 'bar'),
      );
      expect(remend('foo', RemendOptions(handlers: [handler])), equals('bar'));
    });

    test(
      'should execute custom handlers after built-in handlers by default',
      () {
        final handler = RemendHandler(name: 'test', handle: (text) => '$text!');
        expect(
          remend('**bold', RemendOptions(handlers: [handler])),
          equals('**bold**!'),
        );
      },
    );

    test('should respect custom handler priority', () {
      final results = <String>[];
      final lowPriority = RemendHandler(
        name: 'low',
        priority: 200,
        handle: (text) {
          results.add('low');
          return text;
        },
      );
      final highPriority = RemendHandler(
        name: 'high',
        priority: 5,
        handle: (text) {
          results.add('high');
          return text;
        },
      );
      remend('test', RemendOptions(handlers: [lowPriority, highPriority]));
      expect(results, equals(['high', 'low']));
    });

    test('should allow custom handlers to run before built-ins', () {
      final results = <String>[];
      final beforeSetext = RemendHandler(
        name: 'beforeSetext',
        priority: -1,
        handle: (text) {
          results.add('custom');
          return text;
        },
      );
      remend('test\n-', RemendOptions(handlers: [beforeSetext]));
      expect(results[0], equals('custom'));
    });

    test('should handle multiple custom handlers', () {
      final handler1 = RemendHandler(
        name: 'replace-a',
        handle: (text) => text.replaceAll('a', 'b'),
      );
      final handler2 = RemendHandler(
        name: 'replace-b',
        handle: (text) => text.replaceAll('b', 'c'),
      );
      expect(
        remend('aaa', RemendOptions(handlers: [handler1, handler2])),
        equals('ccc'),
      );
    });

    test('should handle custom handlers with same priority in order', () {
      final results = <String>[];
      final first = RemendHandler(
        name: 'first',
        priority: 100,
        handle: (text) {
          results.add('first');
          return text;
        },
      );
      final second = RemendHandler(
        name: 'second',
        priority: 100,
        handle: (text) {
          results.add('second');
          return text;
        },
      );
      remend('test', RemendOptions(handlers: [first, second]));
      expect(results, equals(['first', 'second']));
    });

    test('should work with disabled built-in handlers', () {
      final handler = RemendHandler(name: 'test', handle: (text) => '$text!');
      expect(
        remend('**bold', RemendOptions(bold: false, handlers: [handler])),
        equals('**bold!'),
      );
    });

    test('should work with no built-in handlers enabled', () {
      final handler = RemendHandler(
        name: 'uppercase',
        handle: (text) => text.toUpperCase(),
      );
      expect(
        remend(
          'hello',
          RemendOptions(
            bold: false,
            italic: false,
            boldItalic: false,
            inlineCode: false,
            strikethrough: false,
            katex: false,
            links: false,
            images: false,
            setextHeadings: false,
            handlers: [handler],
          ),
        ),
        equals('HELLO'),
      );
    });

    test('should handle empty handlers array', () {
      expect(remend('**bold', RemendOptions(handlers: [])), equals('**bold**'));
    });
  });

  group('exported utilities', () {
    group('isWithinCodeBlock', () {
      test('should detect position inside code block', () {
        const text = '```\ncode\n```';
        expect(isWithinCodeBlock(text, 5), isTrue);
      });

      test('should detect position outside code block', () {
        const text = 'before ```code``` after';
        expect(isWithinCodeBlock(text, 2), isFalse);
      });
    });

    group('isWithinMathBlock', () {
      test('should detect position inside block math', () {
        const text = r'$$x^2$$';
        expect(isWithinMathBlock(text, 3), isTrue);
      });

      test('should detect position outside math', () {
        const text = r'before $x$ after';
        expect(isWithinMathBlock(text, 14), isFalse);
      });
    });

    group('isWithinLinkOrImageUrl', () {
      test('should detect position inside link URL', () {
        const text = '[text](http://example.com)';
        expect(isWithinLinkOrImageUrl(text, 10), isTrue);
      });

      test('should detect position outside link', () {
        const text = 'before [text](url) after';
        expect(isWithinLinkOrImageUrl(text, 2), isFalse);
      });
    });

    group('isWordChar', () {
      test('should identify word characters', () {
        expect(isWordChar('a'), isTrue);
        expect(isWordChar('Z'), isTrue);
        expect(isWordChar('5'), isTrue);
        expect(isWordChar('_'), isTrue);
      });

      test('should identify non-word characters', () {
        expect(isWordChar(' '), isFalse);
        expect(isWordChar('*'), isFalse);
        expect(isWordChar(''), isFalse);
      });
    });
  });

  group('custom handler example: joke marker', () {
    test('should complete joke markers', () {
      final jokeHandler = RemendHandler(
        name: 'joke',
        priority: 80,
        handle: (text) {
          final match = _jokeMarkerPattern.firstMatch(text);
          if (match != null && !text.endsWith('<<</JOKE>>>')) {
            return '$text<<</JOKE>>>';
          }
          return text;
        },
      );
      expect(
        remend(
          '<<<JOKE>>>Why did the chicken',
          RemendOptions(handlers: [jokeHandler]),
        ),
        equals('<<<JOKE>>>Why did the chicken<<</JOKE>>>'),
      );
    });

    test('should not double-complete joke markers', () {
      final jokeHandler = RemendHandler(
        name: 'joke',
        priority: 80,
        handle: (text) {
          final match = _jokeMarkerPattern.firstMatch(text);
          if (match != null && !text.endsWith('<<</JOKE>>>')) {
            return '$text<<</JOKE>>>';
          }
          return text;
        },
      );
      expect(
        remend(
          '<<<JOKE>>>complete<<</JOKE>>>',
          RemendOptions(handlers: [jokeHandler]),
        ),
        equals('<<<JOKE>>>complete<<</JOKE>>>'),
      );
    });
  });
}
