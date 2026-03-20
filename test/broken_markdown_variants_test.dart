import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  // 1. Rapid successive formatting switches
  group('rapid successive formatting switches', () {
    test(
      'should close italic and strikethrough but not bold when asterisk in content',
      () {
        // Bold pattern can't match when there's a * in content between ** and end
        // Only italic (*) and strikethrough (~~) close
        final result = remend('**bold then *italic then ~~strike');
        expect(result, equals('**bold then *italic then ~~strike*~~'));
      },
    );
    test('should close italic and strikethrough when bold pattern blocked', () {
      // Bold pattern blocked by * in content; italic and strikethrough close
      final result = remend('~~strike **bold *italic');
      expect(result, equals('~~strike **bold *italic*~~'));
    });
    test(
      'should close handlers in priority order (bold before strikethrough before code)',
      () {
        // Bold can't match (asterisk in content), italic appends *, boldItalic appends ***,
        // then inline code appends `, then strikethrough appends ~~
        final result = remend('*italic **bold ~~strike `code');
        expect(result, equals('*italic **bold ~~strike `code***`~~'));
      },
    );
    test('should close bold before strikethrough (priority order)', () {
      // Bold handler (priority 35) runs before strikethrough (priority 60)
      final result = remend('**bold ~~strike');
      expect(result, equals('**bold ~~strike**~~'));
    });
    test('should close italic then bold via bold-italic handler', () {
      final result = remend('*italic **bold');
      expect(result, equals('*italic **bold***'));
    });
  });

  // 2. Formatting cut mid-marker
  group('formatting cut mid-marker', () {
    test('should not close single asterisk at end (ambiguous)', () {
      // Single trailing * could be start of ** - not meaningful content after it
      final result = remend('text*');
      expect(result, equals('text*'));
    });
    test('should not close single tilde at end (not a valid marker alone)', () {
      final result = remend('text~');
      expect(result, equals('text~'));
    });
    test('should not close single dollar at end without inlineKatex', () {
      final result = remend(r'text$');
      expect(result, equals(r'text$'));
    });
    test('should close single dollar at end with inlineKatex enabled', () {
      // countSingleDollars sees 1 (odd), appends $
      final result = remend(r'text$', const RemendOptions(inlineKatex: true));
      expect(result, equals(r'text$$'));
    });
    test('should handle opening marker + single char of closing', () {
      // **bold* is a half-complete bold closing
      expect(remend('**bold*'), equals('**bold**'));
      // ~~strike~ is a half-complete strikethrough closing
      expect(remend('~~strike~'), equals('~~strike~~'));
      // $$formula$ is a half-complete block katex closing
      expect(remend(r'$$formula$'), equals(r'$$formula$$'));
    });
  });

  // 3. Backslash escapes + incomplete formatting
  group('backslash escapes with incomplete formatting', () {
    test('should not close escaped asterisks', () {
      // \\* means escaped backslash + real asterisk
      final result = remend('\\*not italic');
      expect(result, equals('\\*not italic'));
    });
    test('should not close double-escaped backslash before asterisk', () {
      // remend sees the char before * as \ (the second backslash) and treats it as escaped
      final result = remend('\\\\*actually italic');
      expect(result, equals('\\\\*actually italic'));
    });
    test(
      'should close escaped double asterisks (remend does not track escape depth)',
      () {
        // remend doesn't understand that \** has the first * escaped;
        // it sees ** and closes bold
        final result = remend('\\**not bold');
        expect(result, equals('\\**not bold**'));
      },
    );
    test('should handle mixed escaped and real formatting', () {
      // \\* is escaped, but the later *real* is valid
      final result = remend('\\*escaped\\* but *real italic');
      expect(result, equals('\\*escaped\\* but *real italic*'));
    });
  });

  // 4. Multiple incomplete links
  group('multiple incomplete links', () {
    test('should handle two incomplete links', () {
      final result = remend('[link1 and [link2');
      expect(result, equals('[link1 and [link2](streamdown:incomplete-link)'));
    });
    test('should handle one complete and one incomplete link', () {
      final result = remend('[first](url1) and [second');
      expect(
        result,
        equals('[first](url1) and [second](streamdown:incomplete-link)'),
      );
    });
    test('should handle nested incomplete brackets', () {
      final result = remend('[outer [inner]');
      // [inner] is complete, [outer has no closing ]
      expect(result, equals('[outer [inner]](streamdown:incomplete-link)'));
    });
    test('should handle incomplete link in text-only mode', () {
      final result = remend(
        '[incomplete link',
        const RemendOptions(linkMode: LinkMode.textOnly),
      );
      expect(result, equals('incomplete link'));
    });
    test('should handle two incomplete links in text-only mode', () {
      final result = remend(
        '[link1 and [link2',
        const RemendOptions(linkMode: LinkMode.textOnly),
      );
      expect(result, equals('link1 and [link2'));
    });
  });

  // 5. Link text containing formatting markers
  group('link text with formatting markers', () {
    test('should handle bold inside incomplete link URL', () {
      final result = remend('[**bold link**](incomplete-url');
      expect(result, equals('[**bold link**](streamdown:incomplete-link)'));
    });
    test('should handle italic inside incomplete link URL', () {
      final result = remend('[*italic link*](incomplete');
      expect(result, equals('[*italic link*](streamdown:incomplete-link)'));
    });
    test('should handle code inside incomplete link URL', () {
      final result = remend('[`code link`](incomplete');
      expect(result, equals('[`code link`](streamdown:incomplete-link)'));
    });
    test('should handle incomplete formatting inside incomplete link text', () {
      // Link handler runs first (priority 20), early returns
      final result = remend('[**bold link');
      expect(result, equals('[**bold link](streamdown:incomplete-link)'));
    });
  });

  // 6. Nested blockquotes with formatting
  group('nested blockquotes with formatting', () {
    test('should close bold in deeply nested blockquote', () {
      expect(
        remend('> > **deeply nested bold'),
        equals('> > **deeply nested bold**'),
      );
    });
    test('should close bold in blockquote with list', () {
      expect(remend('> * list with **bold'), equals('> * list with **bold**'));
    });
    test('should close italic in triple nested blockquote', () {
      expect(
        remend('> > > triple nested *italic'),
        equals('> > > triple nested *italic*'),
      );
    });
    test('should close strikethrough in blockquote', () {
      expect(remend('> ~~struck text'), equals('> ~~struck text~~'));
    });
  });

  // 7. Task lists with formatting
  group('task lists with formatting', () {
    test('should close bold in unchecked task', () {
      expect(remend('- [ ] **bold task'), equals('- [ ] **bold task**'));
    });
    test('should keep complete strikethrough in checked task', () {
      expect(
        remend('- [x] completed ~~struck~~'),
        equals('- [x] completed ~~struck~~'),
      );
    });
    test('should close italic in unchecked task', () {
      expect(remend('- [ ] *italic task'), equals('- [ ] *italic task*'));
    });
    test('should close inline code in task', () {
      expect(remend('- [ ] `code task'), equals('- [ ] `code task`'));
    });
  });

  // 8. Formatting inside table cells
  group('formatting inside table cells', () {
    test('should close bold that appears to span cell boundary', () {
      // The ** has content after it, so it should be closed
      expect(remend('| **bold | next |'), equals('| **bold | next |**'));
    });
    test('should close inline code that spans cell boundary', () {
      expect(remend('| `code | next |'), equals('| `code | next |`'));
    });
    test('should handle complete formatting in table cell', () {
      const text = '| **bold** | next |';
      expect(remend(text), equals(text));
    });
  });

  // 9. HTML comments and special HTML
  group('HTML comments and special HTML', () {
    test('should not strip HTML comment (pattern requires <[a-zA-Z/])', () {
      // <!-- starts with <! which doesn't match the handler's /^<[a-zA-Z/]/ pattern
      expect(
        remend('text <!-- incomplete comment'),
        equals('text <!-- incomplete comment'),
      );
    });
    test('should not strip complete script tag with trailing text', () {
      // <script> is a complete tag (has >), so the handler doesn't strip it
      expect(remend("text <script>alert('"), equals("text <script>alert('"));
    });
    test('should strip incomplete div with attributes', () {
      expect(remend('text <div class="test'), equals('text'));
    });
    test('should keep complete HTML tags', () {
      expect(remend('text <br>'), equals('text <br>'));
    });
    test('should keep complete HTML comments', () {
      expect(remend('text <!-- comment -->'), equals('text <!-- comment -->'));
    });
  });

  // 10. KaTeX with complex content
  group('KaTeX with complex content', () {
    test('should close block katex with braces inside', () {
      // remend just appends $$, it doesn't complete LaTeX braces
      expect(remend(r'$$\frac{x}{y'), equals(r'$$\frac{x}{y$$'));
    });
    test('should close block katex with latex environments', () {
      expect(remend(r'$$\begin{matrix} a'), equals(r'$$\begin{matrix} a$$'));
    });
    test('should close inline katex when enabled', () {
      expect(
        remend(r'$x^2 + y^2', const RemendOptions(inlineKatex: true)),
        equals(r'$x^2 + y^2$'),
      );
    });
    test('should not treat currency as katex without inlineKatex', () {
      const text = r'The price is $50 and $100';
      expect(remend(text), equals(text));
    });
    test('should close odd inline katex with currency-like text', () {
      // With inlineKatex enabled, $50 and $100 look like two single $ signs (even count)
      final result = remend(
        r'The price is $50 and $100',
        const RemendOptions(inlineKatex: true),
      );
      expect(result, equals(r'The price is $50 and $100'));
    });
    test('should close multiline block katex with complex content', () {
      expect(
        remend('\$\$\n\\sum_{i=0}^{n} x_i'),
        equals('\$\$\n\\sum_{i=0}^{n} x_i\n\$\$'),
      );
    });
  });

  // 11. Consecutive completed + incomplete
  group('consecutive completed + incomplete formatting', () {
    test('should close second bold after complete bold', () {
      expect(remend('**bold** then **more'), equals('**bold** then **more**'));
    });
    test('should close second inline code after complete code', () {
      expect(remend('`code` then `more'), equals('`code` then `more`'));
    });
    test('should close second strikethrough after complete strikethrough', () {
      expect(
        remend('~~done~~ and ~~undone'),
        equals('~~done~~ and ~~undone~~'),
      );
    });
    test('should close second italic after complete italic', () {
      expect(remend('*first* and *second'), equals('*first* and *second*'));
    });
    test('should close second bold-italic after complete bold-italic', () {
      expect(
        remend('***first*** and ***second'),
        equals('***first*** and ***second***'),
      );
    });
  });

  // 12. Formatting at paragraph boundaries
  group('formatting at paragraph boundaries', () {
    test('should close bold after paragraph break', () {
      expect(remend('paragraph1\n\n**bold'), equals('paragraph1\n\n**bold**'));
    });
    test('should close italic after paragraph break', () {
      expect(remend('line1\n\n*italic text'), equals('line1\n\n*italic text*'));
    });
    test('should close formatting after multiple newlines', () {
      expect(remend('text\n\n\n**bold'), equals('text\n\n\n**bold**'));
    });
    test('should close inline code across paragraph', () {
      expect(remend('text\n\n`code'), equals('text\n\n`code`'));
    });
  });

  // 13. Deeply nested formatting (4+ levels)
  group('deeply nested formatting', () {
    test(
      'should close handlers in priority order with deeply nested formatting',
      () {
        // Bold can't match (asterisk in content), italic appends *,
        // inline code appends `, strikethrough appends ~~
        final result = remend('**bold *italic ~~strike `code');
        expect(result, equals('**bold *italic ~~strike `code*`~~'));
      },
    );
    test('should close bold-italic then code then strikethrough', () {
      // BoldItalic (priority 30) appends ***, then inline code (50) appends `,
      // then strikethrough (60) appends ~~
      final result = remend('***bold-italic ~~strike `code');
      expect(result, equals('***bold-italic ~~strike `code***`~~'));
    });
    test(
      'should close italic but not bold when asterisk blocks bold pattern',
      () {
        // Bold handler can't match when * appears in content after **
        // Italic handler closes the *, leaving ** unclosed
        final result = remend('**bold and *italic');
        expect(result, equals('**bold and *italic*'));
      },
    );
  });

  // 14. CJK and Unicode with formatting
  group('CJK and Unicode with formatting', () {
    test('should close bold with Chinese text', () {
      expect(
        remend('**\u4e2d\u6587\u7c97\u4f53'),
        equals('**\u4e2d\u6587\u7c97\u4f53**'),
      );
    });
    test('should close italic with Japanese text', () {
      expect(remend('*\u65e5\u672c\u8a9e'), equals('*\u65e5\u672c\u8a9e*'));
    });
    test('should close inline code with Korean text', () {
      expect(
        remend('`\ud55c\uad6d\uc5b4 \ucf54\ub4dc'),
        equals('`\ud55c\uad6d\uc5b4 \ucf54\ub4dc`'),
      );
    });
    test('should close strikethrough with emoji content', () {
      expect(
        remend('~~\u{1f389} celebration'),
        equals('~~\u{1f389} celebration~~'),
      );
    });
    test('should close bold with mixed CJK and Latin', () {
      expect(remend('**Hello \u4e16\u754c'), equals('**Hello \u4e16\u754c**'));
    });
  });

  // 15. Formatting after structural elements
  group('formatting after structural elements', () {
    test('should close bold after horizontal rule', () {
      expect(
        remend('---\n**bold after rule'),
        equals('---\n**bold after rule**'),
      );
    });
    test('should close bold after heading', () {
      expect(remend('# Heading\n**bold'), equals('# Heading\n**bold**'));
    });
    test('should close bold after blockquote', () {
      expect(remend('> quote\n**bold'), equals('> quote\n**bold**'));
    });
    test('should close italic after code block', () {
      expect(
        remend('```\ncode\n```\n*italic'),
        equals('```\ncode\n```\n*italic*'),
      );
    });
  });

  // 16. Reference-style links and footnotes
  group('reference-style links and footnotes', () {
    test('should handle reference-style link with complete brackets', () {
      const text = '[text][ref]';
      expect(remend(text), equals(text));
    });
    test('should handle footnote reference', () {
      const text = '[^1]';
      expect(remend(text), equals(text));
    });
    test('should handle incomplete reference link', () {
      final result = remend('[text][');
      expect(result, equals('[text][](streamdown:incomplete-link)'));
    });
    test('should keep complete footnote definition', () {
      const text = '[^1]: footnote text';
      expect(remend(text), equals(text));
    });
  });

  // 17. Indented code blocks
  group('indented code blocks', () {
    test('should still close asterisks in indented text (not fenced)', () {
      // remend only tracks fenced code blocks, so indented code is treated as normal text
      expect(
        remend('    *asterisks in indented'),
        equals('    *asterisks in indented*'),
      );
    });
    test('should close bold in indented text', () {
      expect(
        remend('    **bold in indented'),
        equals('    **bold in indented**'),
      );
    });
  });

  // 18. Back-to-back code blocks
  group('back-to-back code blocks', () {
    test('should handle formatting after closed code block', () {
      expect(
        remend('```\ncode\n```\n**bold'),
        equals('```\ncode\n```\n**bold**'),
      );
    });
    test('should not close formatting inside open code block', () {
      // Second ``` opens a new code block that isn't closed
      const text = '```\ncode\n```\n```\nmore';
      expect(remend(text), equals(text));
    });
    test('should handle inline code after code block', () {
      expect(
        remend('```\nblock\n```\n`inline'),
        equals('```\nblock\n```\n`inline`'),
      );
    });
  });

  // 19. Confusing asterisk sequences
  group('confusing asterisk sequences', () {
    test('should handle four asterisks (bold-italic handler appends ***)', () {
      // BoldItalic sees odd triple-asterisk count and markers not balanced, appends ***
      final result = remend('****text');
      expect(result, equals('****text***'));
    });
    test('should handle five asterisks (bold-italic handler appends ***)', () {
      final result = remend('*****text');
      expect(result, equals('*****text***'));
    });
    test('should handle mixed asterisk counts', () {
      // *a**b: single * then ** - each handler works independently
      final result = remend('*a**b');
      expect(result, equals('*a**b***'));
    });
  });

  // 20. Whitespace edge cases
  group('whitespace edge cases', () {
    test('should close bold with tabs in content', () {
      expect(remend('**bold\twith\ttabs'), equals('**bold\twith\ttabs**'));
    });
    test('should close bold with CRLF', () {
      expect(remend('**bold\r\nwith CRLF'), equals('**bold\r\nwith CRLF**'));
    });
    test('should close bold after many leading newlines', () {
      expect(remend('\n\n\n**bold'), equals('\n\n\n**bold**'));
    });
    test('should trim trailing single space', () {
      expect(remend('text '), equals('text'));
    });
    test('should preserve trailing double space', () {
      expect(remend('text  '), equals('text  '));
    });
    test('should close bold and trim trailing space', () {
      expect(remend('**bold '), equals('**bold**'));
    });
  });

  // 21. Options/disabled handlers
  group('disabled handlers via options', () {
    test('should not close bold when bold is disabled', () {
      expect(
        remend('**bold text', const RemendOptions(bold: false)),
        equals('**bold text'),
      );
    });
    test('should close italic even when bold is disabled', () {
      expect(
        remend('**bold *italic', const RemendOptions(bold: false)),
        equals('**bold *italic*'),
      );
    });
    test('should not close anything when all are disabled', () {
      final result = remend(
        '**bold *italic `code ~~strike',
        const RemendOptions(
          bold: false,
          italic: false,
          inlineCode: false,
          strikethrough: false,
          boldItalic: false,
        ),
      );
      expect(result, equals('**bold *italic `code ~~strike'));
    });
    test(
      'should not close bold when asterisk in content blocks pattern (italic disabled)',
      () {
        // Bold pattern can't match when * appears in content; italic is disabled
        // So nothing closes
        expect(
          remend('**bold *italic', const RemendOptions(italic: false)),
          equals('**bold *italic'),
        );
      },
    );
    test('should close strikethrough but not bold when bold is disabled', () {
      expect(
        remend('**bold ~~strike', const RemendOptions(bold: false)),
        equals('**bold ~~strike~~'),
      );
    });
    test(
      'should still close links when only links disabled (images defaults to true)',
      () {
        // The links handler is enabled when EITHER links or images option is true
        // Since images defaults to true, disabling only links doesn't disable the handler
        expect(
          remend('[link text', const RemendOptions(links: false)),
          equals('[link text](streamdown:incomplete-link)'),
        );
      },
    );
    test('should not close links when both links and images disabled', () {
      expect(
        remend('[link text', const RemendOptions(links: false, images: false)),
        equals('[link text'),
      );
    });
    test('should not close katex when katex disabled', () {
      expect(
        remend(r'$$formula', const RemendOptions(katex: false)),
        equals(r'$$formula'),
      );
    });
  });

  // 22. Real-world AI streaming patterns
  group('real-world AI streaming patterns', () {
    test('should handle code explanation with incomplete code block', () {
      const text = "Here's how to use it:\n\n```typescript\nconst x = 1";
      // Inside an incomplete fenced code block - should not modify
      expect(remend(text), equals(text));
    });
    test('should handle markdown list being built with bold', () {
      expect(
        remend('1. First\n2. **Second item with bold'),
        equals('1. First\n2. **Second item with bold**'),
      );
    });
    test('should handle mixed inline code and bold', () {
      expect(
        remend('The function `getData` returns a **Promise'),
        equals('The function `getData` returns a **Promise**'),
      );
    });
    test('should handle incomplete link in explanation', () {
      expect(
        remend('Check the [documentation'),
        equals('Check the [documentation](streamdown:incomplete-link)'),
      );
    });
    test('should handle code block followed by explanation', () {
      expect(
        remend('```js\nconst x = 1;\n```\n\nThis creates a **variable'),
        equals('```js\nconst x = 1;\n```\n\nThis creates a **variable**'),
      );
    });
    test('should handle bullet list with inline code', () {
      expect(
        remend('- Use `map` to transform\n- Use `filter'),
        equals('- Use `map` to transform\n- Use `filter`'),
      );
    });
    test('should handle heading with incomplete italic', () {
      expect(remend('## Important *note'), equals('## Important *note*'));
    });
    test(
      'should handle incomplete image (preserves newlines before removed image)',
      () {
        expect(
          remend("Here's the diagram:\n\n![architecture"),
          equals("Here's the diagram:\n\n"),
        );
      },
    );
    test(
      'should handle incomplete image with partial URL (preserves trailing space)',
      () {
        // Image is removed, leaving "See " - the trailing space remains
        // because remend only trims single trailing space at the very start
        // before handlers run, and the handler produces new trailing space
        expect(remend('See ![diagram](http://example.com/img'), equals('See '));
      },
    );
    test('should handle link with incomplete formatting after it', () {
      expect(
        remend('[click here](https://example.com) for **more'),
        equals('[click here](https://example.com) for **more**'),
      );
    });
  });
}
