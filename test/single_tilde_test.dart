import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('single tilde escape (#445)', () {
    test('should escape single ~ between numbers', () {
      expect(remend('20~25°C'), equals('20\\~25°C'));
    });

    test('should escape multiple single tildes between numbers', () {
      expect(remend('20~25°C。20~25°C'), equals('20\\~25°C。20\\~25°C'));
    });

    test('should escape single ~ between letters', () {
      expect(remend('foo~bar'), equals('foo\\~bar'));
    });

    test('should not escape ~~ (double tilde strikethrough)', () {
      expect(remend('~~strikethrough~~'), equals('~~strikethrough~~'));
    });

    test('should not escape ~ at start or end of text', () {
      expect(remend('~hello'), equals('~hello'));
      expect(remend('hello~'), equals('hello~'));
    });

    test('should not escape ~ surrounded by spaces', () {
      expect(remend('hello ~ world'), equals('hello ~ world'));
    });

    test('should not escape ~ inside code blocks', () {
      expect(remend('```\n20~25\n```'), equals('```\n20~25\n```'));
    });

    test('should not escape ~ inside inline code', () {
      expect(remend('`20~25`'), equals('`20~25`'));
    });

    test(
      'should handle incomplete strikethrough separately from single tilde',
      () {
        expect(remend('20~25 and ~~strike'), equals('20\\~25 and ~~strike~~'));
      },
    );

    test('can be disabled via options', () {
      expect(
        remend('20~25°C', RemendOptions(singleTilde: false)),
        equals('20~25°C'),
      );
    });
  });
}
