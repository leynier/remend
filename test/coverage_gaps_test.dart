import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('empty string through handler pipeline', () {
    test('should handle single space input', () {
      expect(remend(' '), equals(''));
    });
  });

  group('half-complete double underscore closing', () {
    test('should complete __content_ to __content__', () {
      expect(remend('__content_'), equals('__content__'));
    });
  });

  group('underscore with trailing double asterisks', () {
    test('should close underscore when trailing ** is unrelated', () {
      expect(remend('_text**'), equals('_text**_'));
    });
  });

  group('bold-italic inside code block', () {
    test('should not complete *** markers inside code blocks', () {
      expect(remend('```\n***bold'), equals('```\n***bold'));
    });

    test('should complete *** outside code block with *** inside', () {
      expect(
        remend('```\n***\n```\n***text'),
        equals('```\n***\n```\n***text***'),
      );
    });
  });

  group('countTripleAsterisks', () {
    test('should count trailing *** at end of text', () {
      expect(countTripleAsterisks('text***'), equals(1));
    });

    test('should skip *** inside code blocks', () {
      expect(countTripleAsterisks('```\n***\n```'), equals(0));
    });

    test('should count *** outside but not inside code blocks', () {
      expect(countTripleAsterisks('```\n***\n```\n***'), equals(1));
    });

    test('should flush pending asterisks before code block toggle', () {
      expect(countTripleAsterisks('***```code```'), equals(1));
    });
  });

  group('single underscore counting with code blocks', () {
    test('should skip _ inside fenced code blocks', () {
      expect(
        remend('```\n_code\n```\n_text'),
        equals('```\n_code\n```\n_text_'),
      );
    });
  });

  group('setext heading with equals sign edge cases', () {
    test('should not modify equals when previous line is empty', () {
      expect(remend('\n='), equals('\n='));
    });

    test('should not modify double equals when previous line is empty', () {
      expect(remend('\n=='), equals('\n=='));
    });
  });

  group('strikethrough even tilde pairs', () {
    test('should not close when tilde pairs are balanced', () {
      expect(remend('a~~b~~text'), equals('a~~b~~text'));
    });

    test('should not close half-complete tilde when pairs are balanced', () {
      expect(remend('a~~b~~c~'), equals('a~~b~~c~'));
    });
  });

  group('double underscore counting with code blocks', () {
    test('should skip __ inside fenced code blocks', () {
      expect(
        remend('```\n__code\n```\n__text'),
        equals('```\n__code\n```\n__text__'),
      );
    });
  });

  group('link handler edge cases', () {
    test('should handle ]( without matching opening bracket', () {
      expect(remend('](partial'), equals('](partial'));
    });

    test('should skip image brackets in text-only mode', () {
      expect(
        remend('![img [text', RemendOptions(linkMode: LinkMode.textOnly)),
        equals('![img text'),
      );
    });

    test('should skip complete links in text-only mode', () {
      expect(
        remend(
          '[link](url) [incomplete',
          RemendOptions(linkMode: LinkMode.textOnly),
        ),
        equals('[link](url) incomplete'),
      );
    });

    test(
      'should handle complete bracket pair without link in text-only mode',
      () {
        expect(
          remend(
            '[text] [incomplete',
            RemendOptions(linkMode: LinkMode.textOnly),
          ),
          equals('[text] incomplete'),
        );
      },
    );
  });

  group('isBeforeClosingParen edge cases', () {
    test('should return false when newline found before )', () {
      expect(isWithinLinkOrImageUrl('[t](_\nmore)', 4), isFalse);
    });

    test('should return false when text ends without ) or newline', () {
      expect(isWithinLinkOrImageUrl('[t](_noclose', 4), isFalse);
    });
  });

  group('isWithinLinkOrImageUrl — ) found before (', () {
    test('should return false when ) precedes the position', () {
      expect(isWithinLinkOrImageUrl('[text](url) _after', 12), isFalse);
    });

    test('should handle underscore after complete link', () {
      expect(remend('[link](url) _word'), equals('[link](url) _word_'));
    });
  });

  group('isWithinLinkOrImageUrl edge cases', () {
    test('should return false for bare ( not preceded by ]', () {
      expect(isWithinLinkOrImageUrl('func(arg)', 5), isFalse);
    });

    test('should handle underscore after bare parenthesis', () {
      expect(remend('func(_arg'), equals('func(_arg_'));
    });
  });

  group('isWithinHtmlTag edge cases', () {
    test('should return false when > is found first', () {
      expect(isWithinHtmlTag('div>text', 5), isFalse);
    });

    test('should return false for invalid tag start after <', () {
      expect(isWithinHtmlTag('3<5 text', 4), isFalse);
    });

    test('should return false when newline found before < or >', () {
      expect(isWithinHtmlTag('<div\ntext', 6), isFalse);
    });

    test('should handle underscore after > character', () {
      expect(remend('div> _text'), equals('div> _text_'));
    });

    test('should handle underscore near < with invalid tag start', () {
      expect(remend('3<5 _text'), equals('3<5 _text_'));
    });

    test('should handle underscore on new line after HTML element', () {
      expect(remend('<div>\n_text'), equals('<div>\n_text_'));
    });

    test('should return true for uppercase tag', () {
      expect(isWithinHtmlTag("<DIV class='_test'>", 13), isTrue);
    });

    test('should return true for closing tag with /', () {
      expect(isWithinHtmlTag('</div _attr>', 6), isTrue);
    });

    test('should return false when < is at end of text', () {
      expect(isWithinHtmlTag('text<', 5), isFalse);
    });
  });

  group('underscore inside link URL', () {
    test('should not close underscore that is part of a link URL', () {
      expect(remend('[link](a_b) _word'), equals('[link](a_b) _word_'));
    });
  });

  group('isWithinMathBlock branch coverage', () {
    test(r'should ignore single $ inside block math', () {
      expect(isWithinMathBlock(r'$$x$y$$z', 5), isTrue);
    });
  });

  group('double underscore half-complete in code block', () {
    test('should not complete __content_ inside code block', () {
      expect(remend('```\n__content_'), equals('```\n__content_'));
    });
  });

  group('double underscore half-complete with even pairs', () {
    test('should not complete when __ pairs are balanced', () {
      expect(remend('__a__ __b__content_'), equals('__a__ __b__content_'));
    });
  });

  group('findFirstIncompleteBracket with incomplete URL', () {
    test('should handle [text]( without ) before incomplete bracket', () {
      expect(
        remend(
          '[a]( b](c [incomplete',
          RemendOptions(linkMode: LinkMode.textOnly),
        ),
        equals('[a]( b](c incomplete'),
      );
    });
  });

  group('isHorizontalRule branch coverage', () {
    test('should detect horizontal rule with spaces between markers', () {
      expect(isHorizontalRule('* * *', 0, '*'), isTrue);
    });

    test('should detect horizontal rule with tabs between markers', () {
      expect(isHorizontalRule('*\t*\t*', 0, '*'), isTrue);
    });
  });
}
