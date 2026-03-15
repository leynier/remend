import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('image handling', () {
    test('should remove incomplete images', () {
      expect(remend('Text with ![incomplete image'), equals('Text with '));
      expect(remend('![partial'), equals(''));
    });

    test('should keep complete images unchanged', () {
      const text = 'Text with ![alt text](image.png)';
      expect(remend(text), equals(text));
    });

    test('should handle partial image at chunk boundary', () {
      expect(remend('See ![the diag'), equals('See '));
      // Images with partial URLs should be removed (images can't show skeleton)
      expect(remend('![logo](./assets/log'), equals(''));
    });

    test('should handle nested brackets in incomplete images', () {
      expect(remend('Text ![outer [inner]'), equals('Text '));
      expect(remend('![nested [brackets] text'), equals(''));
      expect(remend('Start ![foo [bar] baz'), equals('Start '));
    });

    test(
      'should not add trailing underscore for images with underscores in URL (#284)',
      () {
        const markdown =
            'textContent ![image](https://img.alicdn.com/imgextra/i4/6000000003603/O1CN01ApW8bQ1cUE8LduPra_!!6000000003603-2-skyky.png)';
        expect(remend(markdown), equals(markdown));
        // Should also work with links containing underscores
        const linkMarkdown =
            'textContent [link](https://example.com/path_name!!test)';
        expect(remend(linkMarkdown), equals(linkMarkdown));
        // Multiple images should also work
        const multipleImages =
            'textContent ![image1](https://example.com/path_1!!test.png) ![image2](https://example.com/path_2!!test.png)';
        expect(remend(multipleImages), equals(multipleImages));
      },
    );
  });
}
