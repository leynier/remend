import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('incomplete HTML tag stripping', () {
    test('should strip incomplete opening tags at end', () {
      expect(remend('Hello <div'), equals('Hello'));
      expect(remend('Hello <custom'), equals('Hello'));
      expect(remend('Hello <casecard'), equals('Hello'));
      expect(remend('Text <MyComponent'), equals('Text'));
    });

    test('should strip incomplete closing tags at end', () {
      expect(remend('Hello </div'), equals('Hello'));
      expect(remend('Hello </custom'), equals('Hello'));
      expect(remend('<div>content</di'), equals('<div>content'));
    });

    test('should strip incomplete tags with partial attributes', () {
      expect(remend('Hello <div class="foo'), equals('Hello'));
      expect(remend('Hello <div class='), equals('Hello'));
      expect(remend('Hello <a href="https://example.com'), equals('Hello'));
      expect(remend('<custom data-id'), equals(''));
    });

    test('should keep complete tags unchanged', () {
      expect(remend('Hello <div>'), equals('Hello <div>'));
      expect(remend('<div>content</div>'), equals('<div>content</div>'));
      expect(remend('<br/>'), equals('<br/>'));
      expect(remend("<img src='test'>"), equals("<img src='test'>"));
    });

    test('should not strip < followed by space or number', () {
      expect(remend('3 < 5'), equals('3 < 5'));
      expect(remend('x < y'), equals('x < y'));
      expect(remend('if a <'), equals('if a <'));
      expect(remend('value <1'), equals('value <1'));
    });

    test('should not strip inside code blocks', () {
      expect(remend('```\n<div\n```'), equals('```\n<div\n```'));
      expect(remend('```html\n<custom'), equals('```html\n<custom'));
    });

    test('should not strip inside inline code', () {
      expect(remend('`<div`'), equals('`<div`'));
    });

    test('should handle tag at start of text', () {
      expect(remend('<div'), equals(''));
      expect(remend('<custom'), equals(''));
      expect(remend('</div'), equals(''));
    });

    test('should strip only the incomplete tag, preserving prior content', () {
      expect(remend('Some text here\n\n<casecard'), equals('Some text here'));
      expect(
        remend('# Heading\n\nParagraph <custom'),
        equals('# Heading\n\nParagraph'),
      );
    });

    test('should handle complete tag followed by incomplete tag', () {
      expect(remend('<div>Hello</div> <span'), equals('<div>Hello</div>'));
    });

    test(
      'should not add trailing underscore for HTML attributes with underscores',
      () {
        expect(
          remend('<a target="_blank" href="https://link.com">word</a>'),
          equals('<a target="_blank" href="https://link.com">word</a>'),
        );
        expect(
          remend('<a target="_blank">link</a>'),
          equals('<a target="_blank">link</a>'),
        );
        expect(
          remend('<iframe src="x" sandbox="allow_scripts">'),
          equals('<iframe src="x" sandbox="allow_scripts">'),
        );
      },
    );

    test('should be disabled when htmlTags option is false', () {
      expect(
        remend('Hello <div', RemendOptions(htmlTags: false)),
        equals('Hello <div'),
      );
    });
  });
}
