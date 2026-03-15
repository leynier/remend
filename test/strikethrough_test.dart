import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('strikethrough formatting (~~)', () {
    test('should complete incomplete strikethrough', () {
      expect(remend('Text with ~~strike'), equals('Text with ~~strike~~'));
      expect(remend('~~incomplete'), equals('~~incomplete~~'));
    });

    test('should keep complete strikethrough unchanged', () {
      const text = 'Text with ~~strikethrough text~~';
      expect(remend(text), equals(text));
    });

    test('should handle multiple strikethrough sections', () {
      const text = '~~strike1~~ and ~~strike2~~';
      expect(remend(text), equals(text));
    });

    test('should complete odd number of strikethrough markers', () {
      expect(
        remend('~~first~~ and ~~second'),
        equals('~~first~~ and ~~second~~'),
      );
    });

    test('should complete half-complete ~~ closing marker (#313)', () {
      // When streaming ~~strike~~, the closing marker arrives char by char
      // ~~strike~ is a half-complete closing marker
      expect(remend('~~xxx~'), equals('~~xxx~~'));
      expect(remend('~~strike text~'), equals('~~strike text~~'));
      expect(remend('Text with ~~strike~'), equals('Text with ~~strike~~'));
      expect(
        remend('This is ~~strikethrough~'),
        equals('This is ~~strikethrough~~'),
      );
    });
  });
}
