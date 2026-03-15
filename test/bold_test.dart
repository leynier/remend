import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('bold formatting (**)', () {
    test('should complete incomplete bold formatting', () {
      expect(remend('Text with **bold'), equals('Text with **bold**'));
      expect(remend('**incomplete'), equals('**incomplete**'));
    });

    test('should keep complete bold formatting unchanged', () {
      const text = 'Text with **bold text**';
      expect(remend(text), equals(text));
    });

    test('should handle multiple bold sections', () {
      const text = '**bold1** and **bold2**';
      expect(remend(text), equals(text));
    });

    test('should complete odd number of bold markers', () {
      expect(
        remend('**first** and **second'),
        equals('**first** and **second**'),
      );
    });

    test('should handle partial bold text at chunk boundary', () {
      expect(
        remend('Here is some **bold tex'),
        equals('Here is some **bold tex**'),
      );
    });

    test('should complete half-complete bold closing marker (#313)', () {
      // When streaming **bold**, the closing marker arrives char by char
      // **bold text* is a half-complete closing marker, not bold+asterisk
      expect(remend('**xxx*'), equals('**xxx**'));
      expect(remend('**bold text*'), equals('**bold text**'));
      expect(remend('Text with **bold*'), equals('Text with **bold**'));
      expect(remend('This is **bold text*'), equals('This is **bold text**'));
    });
  });
}
