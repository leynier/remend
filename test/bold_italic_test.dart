import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('bold-italic formatting (***)', () {
    test('should complete incomplete bold-italic formatting', () {
      expect(
        remend('Text with ***bold-italic'),
        equals('Text with ***bold-italic***'),
      );
      expect(remend('***incomplete'), equals('***incomplete***'));
    });

    test('should keep complete bold-italic formatting unchanged', () {
      const text = 'Text with ***bold and italic text***';
      expect(remend(text), equals(text));
    });

    test('should handle multiple bold-italic sections', () {
      const text = '***first*** and ***second***';
      expect(remend(text), equals(text));
    });

    test('should complete odd number of triple asterisk markers', () {
      expect(
        remend('***first*** and ***second'),
        equals('***first*** and ***second***'),
      );
    });

    test('should not confuse triple asterisks with single or double', () {
      expect(
        remend('*italic* **bold** ***both'),
        equals('*italic* **bold** ***both***'),
      );
    });

    test('should handle triple asterisks at start of text', () {
      expect(
        remend('***Starting bold-italic'),
        equals('***Starting bold-italic***'),
      );
    });

    test('should handle nested formatting with triple asterisks', () {
      expect(
        remend('***bold-italic with `code'),
        equals('***bold-italic with `code***`'),
      );
    });

    test('should handle bold-italic chunks', () {
      final chunks = [
        'This is',
        'This is ***very',
        'This is ***very important',
        'This is ***very important***',
        'This is ***very important*** to know',
      ];
      expect(remend(chunks[0]), equals('This is'));
      expect(remend(chunks[1]), equals('This is ***very***'));
      expect(remend(chunks[2]), equals('This is ***very important***'));
      expect(remend(chunks[3]), equals(chunks[3]));
      expect(remend(chunks[4]), equals(chunks[4]));
    });

    test('should handle text ending with multiple consecutive asterisks', () {
      // Test the case where text ends with trailing asterisks (>= 3)
      expect(remend('text ***'), equals('text ***'));
      expect(remend('text ****'), equals('text ****'));
      expect(remend('text *****'), equals('text *****'));
      expect(remend('text ******'), equals('text ******'));
      // Test text that ends without any space
      expect(remend('text***'), equals('text***'));
      expect(remend('word****'), equals('word****'));
      expect(remend('end******'), equals('end******'));
      // Test cases where countTripleAsterisks is called with trailing asterisks
      expect(remend('***start***end***'), equals('***start***end***'));
      expect(remend('***text***'), equals('***text***'));
      expect(remend('***incomplete'), equals('***incomplete***'));
      expect(remend('***word text***'), equals('***word text***'));
    });

    test(
      'should not add closing markers to overlapping bold and italic (#302)',
      () {
        // When we have **bold and *italic***, the *** is closing both ** and *
        // It's not a bold-italic marker, so we shouldn't add closing ***
        expect(
          remend('Combined **bold and *italic*** text'),
          equals('Combined **bold and *italic*** text'),
        );
        expect(
          remend('**bold and *italic*** more text'),
          equals('**bold and *italic*** more text'),
        );
        expect(
          remend('test **bold and *italic*** end'),
          equals('test **bold and *italic*** end'),
        );
        expect(
          remend('- Combined **bold and *italic*** text'),
          equals('- Combined **bold and *italic*** text'),
        );
      },
    );
  });
}
