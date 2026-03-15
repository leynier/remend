import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group(r'KaTeX block formatting ($$)', () {
    test('should complete incomplete block KaTeX', () {
      expect(remend(r'Text with $$formula'), equals(r'Text with $$formula$$'));
      expect(remend(r'$$incomplete'), equals(r'$$incomplete$$'));
    });

    test('should keep complete block KaTeX unchanged', () {
      const text = r'Text with $$E = mc^2$$';
      expect(remend(text), equals(text));
    });

    test('should handle multiple block KaTeX sections', () {
      const text = r'$$formula1$$ and $$formula2$$';
      expect(remend(text), equals(text));
    });

    test('should complete odd number of block KaTeX markers', () {
      expect(
        remend(r'$$first$$ and $$second'),
        equals(r'$$first$$ and $$second$$'),
      );
    });

    test('should handle block KaTeX at start of text', () {
      expect(remend(r'$$x + y = z'), equals(r'$$x + y = z$$'));
    });

    test(r'should complete partial closing $ without duplicating it', () {
      expect(remend(r'$$formula$'), equals(r'$$formula$$'));
      expect(remend(r'$$x = y$'), equals(r'$$x = y$$'));
    });

    test('should handle multiline block KaTeX', () {
      expect(
        remend('\$\$\nx = 1\ny = 2'),
        equals('\$\$\nx = 1\ny = 2\n\$\$'),
      );
    });
  });

  group(r'KaTeX inline formatting ($)', () {
    test('should NOT complete single dollar signs (likely currency)', () {
      expect(remend(r'Text with $formula'), equals(r'Text with $formula'));
      expect(remend(r'$incomplete'), equals(r'$incomplete'));
    });

    test('should keep text with paired dollar signs unchanged', () {
      const text = r'Text with $x^2 + y^2 = z^2$';
      expect(remend(text), equals(text));
    });

    test('should handle multiple inline KaTeX sections', () {
      const text = r'$a = 1$ and $b = 2$';
      expect(remend(text), equals(text));
    });

    test('should NOT complete odd number of dollar signs', () {
      expect(
        remend(r'$first$ and $second'),
        equals(r'$first$ and $second'),
      );
    });

    test(r'should not complete single $ but should complete block $$', () {
      expect(
        remend(r'$$block$$ and $inline'),
        equals(r'$$block$$ and $inline'),
      );
    });

    test('should NOT complete dollar sign at start of text', () {
      expect(remend(r'$x + y = z'), equals(r'$x + y = z'));
    });

    test('should handle escaped dollar signs', () {
      const text = r'Price is \$100';
      expect(remend(text), equals(text));
    });

    test('should handle multiple consecutive dollar signs correctly', () {
      expect(remend(r'$$$'), equals(r'$$$$$'));
      expect(remend(r'$$$$'), equals(r'$$$$'));
    });

    test('should handle mathematical expression chunks', () {
      final chunks = [
        r'The formula',
        r'The formula $E',
        r'The formula $E = mc',
        r'The formula $E = mc^2',
        r'The formula $E = mc^2$ shows',
      ];
      expect(remend(chunks[0]), equals(chunks[0]));
      expect(remend(chunks[1]), equals(r'The formula $E'));
      expect(remend(chunks[2]), equals(r'The formula $E = mc'));
      expect(remend(chunks[3]), equals(r'The formula $E = mc^2'));
      expect(remend(chunks[4]), equals(chunks[4]));
    });
  });

  group(r'KaTeX inline formatting ($) — opt-in via inlineKatex: true', () {
    const opts = RemendOptions(inlineKatex: true);

    test('should complete incomplete inline math', () {
      expect(
        remend(r'Text with $formula', opts),
        equals(r'Text with $formula$'),
      );
      expect(remend(r'$incomplete', opts), equals(r'$incomplete$'));
    });

    test('should keep already-complete inline math unchanged', () {
      const text = r'Text with $x^2 + y^2 = z^2$';
      expect(remend(text, opts), equals(text));
    });

    test('should complete the third unpaired dollar sign', () {
      expect(
        remend(r'$first$ and $second', opts),
        equals(r'$first$ and $second$'),
      );
    });

    test(r'should complete inline $ but not affect complete block $$', () {
      expect(
        remend(r'$$block$$ and $inline', opts),
        equals(r'$$block$$ and $inline$'),
      );
    });

    test('should handle streaming chunks of inline math', () {
      final chunks = [
        r'The formula',
        r'The formula $E',
        r'The formula $E = mc',
        r'The formula $E = mc^2',
        r'The formula $E = mc^2$ shows',
      ];
      expect(remend(chunks[0], opts), equals(chunks[0]));
      expect(remend(chunks[1], opts), equals(r'The formula $E$'));
      expect(remend(chunks[2], opts), equals(r'The formula $E = mc$'));
      expect(remend(chunks[3], opts), equals(r'The formula $E = mc^2$'));
      expect(remend(chunks[4], opts), equals(chunks[4]));
    });

    test('should not complete escaped dollar signs', () {
      const text = r'Price is \$100';
      expect(remend(text, opts), equals(text));
    });

    test(r'should not complete $ inside inline code', () {
      const text = r'Use `$var` for variables and $formula';
      expect(
        remend(text, opts),
        equals(r'Use `$var` for variables and $formula$'),
      );
    });

    test('should handle multiple complete inline math expressions', () {
      const text = r'$a = 1$ and $b = 2$';
      expect(remend(text, opts), equals(text));
    });

    test('should handle mixed inline and block math', () {
      const text = r'Inline $x$ and block $$y$$';
      expect(remend(text, opts), equals(text));
    });

    test(r'should not complete $ inside a complete block math expression', () {
      const text = r'$$x_1 + y_2 = z_3$$';
      expect(remend(text, opts), equals(text));
    });

    test(r'should handle $$ followed by an unmatched $', () {
      expect(
        remend(r'$$block$$ then $x + y', opts),
        equals(r'$$block$$ then $x + y$'),
      );
    });

    test(
      r'should not produce extra $ when block katex and inline katex both run',
      () {
        expect(remend(r'$$formula$', opts), equals(r'$$formula$$'));
        expect(remend(r'$$x = y$', opts), equals(r'$$x = y$$'));
      },
    );
  });

  group('math blocks with underscores', () {
    test('should not complete underscores within inline math blocks', () {
      const text = r'The variable $x_1$ represents the first element';
      expect(remend(text), equals(text));
      const text2 = r'Formula: $a_b + c_d = e_f$';
      expect(remend(text2), equals(text2));
    });

    test('should not complete underscores within block math', () {
      const text = r'$$x_1 + y_2 = z_3$$';
      expect(remend(text), equals(text));
      const text2 = '\$\$\na_1 + b_2\nc_3 + d_4\n\$\$';
      expect(remend(text2), equals(text2));
    });

    test(
      'should not add underscore when math block has incomplete underscore',
      () {
        const text = r'Math expression $x_';
        expect(remend(text), equals(r'Math expression $x_'));
        const text2 = r'$$formula_';
        expect(remend(text2), equals(r'$$formula_$$'));
      },
    );

    test('should handle underscores outside math blocks normally', () {
      const text = r'Text with _italic_ and math $x_1$';
      expect(remend(text), equals(text));
      const text2 = r'_italic text_ followed by $a_b$';
      expect(remend(text2), equals(text2));
    });

    test('should complete italic underscore outside math but not inside', () {
      const text = r'Start _italic with $x_1$';
      expect(remend(text), equals(r'Start _italic with $x_1$_'));
    });

    test(
      'should handle complex math expressions with multiple underscores',
      () {
        const text = r'$x_1 + x_2 + x_3 = y_1$';
        expect(remend(text), equals(text));
        const text2 =
            r'$$\sum_{i=1}^{n} x_i = \prod_{j=1}^{m} y_j$$';
        expect(remend(text2), equals(text2));
      },
    );

    test('should handle escaped dollar signs correctly', () {
      const text = r'Price is \$50 and _this is italic_';
      expect(remend(text), equals(text));
      const text2 = r'Cost \$100 with _incomplete';
      expect(remend(text2), equals(r'Cost \$100 with _incomplete_'));
    });

    test('should handle mixed inline and block math', () {
      const text = r'Inline $x_1$ and block $$y_2$$ math';
      expect(remend(text), equals(text));
    });

    test(
      'should not interfere with complete math blocks when adding underscores outside',
      () {
        const text = r'_italic start $x_1$ italic end_';
        expect(remend(text), equals(text));
      },
    );

    test('should not complete dollar signs in inline code blocks (#296)', () {
      const str =
          r'Streamdown uses double dollar signs (`$$`) to delimit mathematical expressions.';
      expect(remend(str), equals(str));
    });

    test(
      r'should handle multiple inline code blocks with $$ correctly (#296)',
      () {
        const str = r'Use `$$` for math blocks and `$$formula$$` for inline.';
        expect(remend(str), equals(str));
      },
    );

    test(r'should complete $$ outside inline code but not inside (#296)', () {
      const str = r'Math: $$x+y and code: `$$`';
      expect(remend(str), equals(r'Math: $$x+y and code: `$$`$$'));
    });

    test(r'should handle mixed $$ inside and outside code blocks (#296)', () {
      const str = r'$$formula$$ and code `$$` and $$incomplete';
      expect(
        remend(str),
        equals(r'$$formula$$ and code `$$` and $$incomplete$$'),
      );
    });
  });

  group('math blocks with asterisks', () {
    test('should not complete asterisks within block math', () {
      const text = r'$$\mathbf{w}^{*}$$';
      expect(remend(text), equals(text));
    });

    test('should not complete asterisks in complex math expressions', () {
      const text =
          '\$\$\n\\mathbf{w}^{*} = \\underset{\\|\\mathbf{w}\\|=1}{\\arg\\max} \\;\\; \\mathbf{w}^T S \\mathbf{w}\n\$\$';
      expect(remend(text), equals(text));
    });

    test('should handle asterisks outside math blocks normally', () {
      const text = r'Text with *italic* and math $$x^{*}$$';
      expect(remend(text), equals(text));
    });

    test('should complete italic asterisk outside math but not inside', () {
      const text = r'Start *italic with $$x^{*}$$';
      expect(remend(text), equals(r'Start *italic with $$x^{*}$$*'));
    });
  });
}
