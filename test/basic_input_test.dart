import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('basic input handling', () {
    // Note: The TypeScript version tests null/undefined/number inputs,
    // but Dart's type system prevents passing non-String values.

    test('should return empty string unchanged', () {
      expect(remend(''), equals(''));
    });

    test('should return regular text unchanged', () {
      const text = 'This is plain text without any markdown';
      expect(remend(text), equals(text));
    });
  });
}
