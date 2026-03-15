import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('link handling', () {
    test('should preserve incomplete links with special marker', () {
      expect(
        remend('Text with [incomplete link'),
        equals('Text with [incomplete link](streamdown:incomplete-link)'),
      );
      expect(
        remend('Text [partial'),
        equals('Text [partial](streamdown:incomplete-link)'),
      );
    });

    test('should keep complete links unchanged', () {
      const text = 'Text with [complete link](url)';
      expect(remend(text), equals(text));
    });

    test('should handle multiple complete links', () {
      const text = '[link1](url1) and [link2](url2)';
      expect(remend(text), equals(text));
    });

    test('should handle nested brackets in incomplete links', () {
      expect(
        remend('[outer [nested] text](incomplete'),
        equals('[outer [nested] text](streamdown:incomplete-link)'),
      );
      expect(
        remend('[link with [inner] content](http://incomplete'),
        equals('[link with [inner] content](streamdown:incomplete-link)'),
      );
      expect(
        remend('Text [foo [bar] baz]('),
        equals('Text [foo [bar] baz](streamdown:incomplete-link)'),
      );
    });

    test('should handle nested brackets in complete links', () {
      const text = '[link with [brackets] inside](https://example.com)';
      expect(remend(text), equals(text));
    });

    test('should handle partial link at chunk boundary - #165', () {
      expect(
        remend('Check out [this lin'),
        equals('Check out [this lin](streamdown:incomplete-link)'),
      );
      expect(
        remend('Visit [our site](https://exa'),
        equals('Visit [our site](streamdown:incomplete-link)'),
      );
    });

    test('should handle nested brackets without matching closing bracket', () {
      expect(
        remend('Text [outer [inner'),
        equals('Text [outer [inner](streamdown:incomplete-link)'),
      );
      expect(
        remend('[foo [bar [baz'),
        equals('[foo [bar [baz](streamdown:incomplete-link)'),
      );
      expect(
        remend('Text [outer [inner]'),
        equals('Text [outer [inner]](streamdown:incomplete-link)'),
      );
      expect(
        remend('[link [nested] text'),
        equals('[link [nested] text](streamdown:incomplete-link)'),
      );
    });
  });

  group('link handling with linkMode: text-only', () {
    const textOnlyOptions = RemendOptions(linkMode: LinkMode.textOnly);

    test('should show plain text for incomplete links', () {
      expect(
        remend('Text with [incomplete link', textOnlyOptions),
        equals('Text with incomplete link'),
      );
      expect(
        remend('Text [partial', textOnlyOptions),
        equals('Text partial'),
      );
    });

    test('should keep complete links unchanged', () {
      const text = 'Text with [complete link](url)';
      expect(remend(text, textOnlyOptions), equals(text));
    });

    test('should handle multiple complete links', () {
      const text = '[link1](url1) and [link2](url2)';
      expect(remend(text, textOnlyOptions), equals(text));
    });

    test('should handle nested brackets in incomplete links', () {
      expect(
        remend('[outer [nested] text](incomplete', textOnlyOptions),
        equals('outer [nested] text'),
      );
      expect(
        remend(
          '[link with [inner] content](http://incomplete',
          textOnlyOptions,
        ),
        equals('link with [inner] content'),
      );
      expect(
        remend('Text [foo [bar] baz](', textOnlyOptions),
        equals('Text foo [bar] baz'),
      );
    });

    test('should handle partial link at chunk boundary', () {
      expect(
        remend('Check out [this lin', textOnlyOptions),
        equals('Check out this lin'),
      );
      expect(
        remend('Visit [our site](https://exa', textOnlyOptions),
        equals('Visit our site'),
      );
    });

    test('should handle nested brackets without matching closing bracket', () {
      expect(
        remend('Text [outer [inner', textOnlyOptions),
        equals('Text outer [inner'),
      );
      expect(
        remend('[foo [bar [baz', textOnlyOptions),
        equals('foo [bar [baz'),
      );
      expect(
        remend('Text [outer [inner]', textOnlyOptions),
        equals('Text outer [inner]'),
      );
      expect(
        remend('[link [nested] text', textOnlyOptions),
        equals('link [nested] text'),
      );
    });

    test('should still remove incomplete images', () {
      expect(
        remend('Text ![incomplete image', textOnlyOptions),
        equals('Text '),
      );
      expect(
        remend('Text ![alt](http://partial', textOnlyOptions),
        equals('Text '),
      );
    });
  });
}
