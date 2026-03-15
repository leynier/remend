import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('isWordChar', () {
    test('should return false for empty string', () {
      expect(isWordChar(''), isFalse);
    });

    test('should return true for ASCII word characters', () {
      expect(isWordChar('a'), isTrue);
      expect(isWordChar('Z'), isTrue);
      expect(isWordChar('5'), isTrue);
      expect(isWordChar('_'), isTrue);
    });

    test('should return false for non-word characters', () {
      expect(isWordChar(' '), isFalse);
      expect(isWordChar('*'), isFalse);
      expect(isWordChar('-'), isFalse);
    });

    test('should handle unicode word characters', () {
      expect(isWordChar('é'), isTrue);
      expect(isWordChar('ñ'), isTrue);
    });
  });

  group('findMatchingOpeningBracket', () {
    test('should return -1 when no matching opening bracket exists', () {
      const text = 'some text]';
      expect(findMatchingOpeningBracket(text, 9), equals(-1));
    });

    test('should find matching opening bracket for simple case', () {
      const text = '[text]';
      expect(findMatchingOpeningBracket(text, 5), equals(0));
    });

    test('should handle nested brackets', () {
      const text = '[outer [inner] text]';
      expect(findMatchingOpeningBracket(text, 19), equals(0));
      expect(findMatchingOpeningBracket(text, 13), equals(7));
    });
  });

  group('findMatchingClosingBracket', () {
    test('should return -1 when no matching closing bracket exists', () {
      const text = '[some text';
      expect(findMatchingClosingBracket(text, 0), equals(-1));
    });

    test('should find matching closing bracket for simple case', () {
      const text = '[text]';
      expect(findMatchingClosingBracket(text, 0), equals(5));
    });

    test('should handle nested brackets', () {
      const text = '[outer [inner] text]';
      expect(findMatchingClosingBracket(text, 0), equals(19));
      expect(findMatchingClosingBracket(text, 7), equals(13));
    });
  });
}
