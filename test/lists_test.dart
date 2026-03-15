import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('list handling', () {
    test('should not add asterisk to lists using asterisk markers', () {
      const text = '* Item 1\n* Item 2\n* Item 3';
      expect(remend(text), equals(text));
    });

    test('should not add asterisk to single list item', () {
      const text = '* Single item';
      expect(remend(text), equals(text));
    });

    test('should not add asterisk to nested lists', () {
      const text = '* Parent item\n  * Nested item 1\n  * Nested item 2';
      expect(remend(text), equals(text));
    });

    test('should handle lists with italic text correctly', () {
      const text = '* Item with *italic* text\n* Another item';
      expect(remend(text), equals(text));
    });

    test('should complete incomplete italic even in list items', () {
      const text = '* Item with *incomplete italic\n* Another item';
      expect(
        remend(text),
        equals('* Item with *incomplete italic\n* Another item*'),
      );
    });

    test(
      'should handle mixed list markers and italic formatting',
      () {
        const text = '* First item\n* Second *italic* item\n* Third item';
        expect(remend(text), equals(text));
      },
    );

    test('should handle lists with tabs for indentation', () {
      const text = '*\tItem with tab\n*\tAnother item';
      expect(remend(text), equals(text));
    });

    test('should not interfere with dash lists', () {
      const text = '- Item 1\n- Item 2 with *italic*\n- Item 3';
      expect(remend(text), equals(text));
    });

    test('should handle the Gemini response example from issue', () {
      const geminiResponse = '* user123\n* user456\n* user789';
      expect(remend(geminiResponse), equals(geminiResponse));
    });

    test('should handle lists with incomplete formatting', () {
      expect(
        remend('- Item 1\n- Item 2 with **bol'),
        equals('- Item 1\n- Item 2 with **bol**'),
      );
    });

    test('should handle lists with emphasis character blocks (#97)', () {
      expect(remend('- __'), equals('- __'));
      expect(remend('- **'), equals('- **'));
      expect(remend('- __\n- **'), equals('- __\n- **'));
      expect(remend('\n- __\n- **'), equals('\n- __\n- **'));
      // Multiple list items with emphasis markers
      expect(remend('* __\n* **'), equals('* __\n* **'));
      expect(remend('+ __\n+ **'), equals('+ __\n+ **'));
      // List items with emphasis markers and text should still complete
      expect(remend('- __ text after'), equals('- __ text after__'));
      expect(remend('- ** text after'), equals('- ** text after**'));
      // Mixed list items
      expect(
        remend('- __\n- Normal item\n- **'),
        equals('- __\n- Normal item\n- **'),
      );
      // Lists with other emphasis markers
      expect(remend('- ***'), equals('- ***'));
      expect(remend('- *'), equals('- *'));
      expect(remend('- _'), equals('- _'));
      expect(remend('- ~~'), equals('- ~~'));
      expect(remend('- `'), equals('- `'));
    });

    test(
      'should not complete list items with emphasis markers spanning multiple lines',
      () {
        expect(remend('- **text\nmore text'), equals('- **text\nmore text'));
        expect(
          remend('* **content\n* Another item'),
          equals('* **content\n* Another item'),
        );
      },
    );
  });
}
