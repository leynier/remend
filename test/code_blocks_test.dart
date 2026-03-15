import 'package:remend/remend.dart';
import 'package:test/test.dart';

void main() {
  group('code block handling', () {
    test('should handle incomplete multiline code blocks', () {
      expect(
        remend('```javascript\nconst x = 5;'),
        equals('```javascript\nconst x = 5;'),
      );
      expect(remend('```\ncode here'), equals('```\ncode here'));
    });

    test('should handle complete multiline code blocks', () {
      const text = '```javascript\nconst x = 5;\n```';
      expect(remend(text), equals(text));
    });

    test('should handle code blocks with language and incomplete content', () {
      expect(
        remend('```python\ndef hello():'),
        equals('```python\ndef hello():'),
      );
    });

    test('should handle nested backticks inside code blocks', () {
      const text = '```\nconst str = `template`;\n```';
      expect(remend(text), equals(text));
    });

    test(
      'should handle incomplete code blocks at end of chunked response',
      () {
        expect(
          remend('Some text\n```js\nconsole.log'),
          equals('Some text\n```js\nconsole.log'),
        );
      },
    );

    test('should handle code blocks with trailing content', () {
      const text = '```\ncode\n```\nMore text';
      expect(remend(text), equals(text));
    });

    test(
      'should handle complete code blocks ending with triple backticks on newline',
      () {
        const text =
            '```python\ndef greet(name):\n    return f"Hello, {name}!"\n```';
        expect(remend(text), equals(text));
      },
    );

    test(
      'should handle complete code blocks with trailing newline after closing backticks',
      () {
        const text =
            '```python\ndef greet(name):\n    return f"Hello, {name}!"\n```\n';
        expect(remend(text), equals(text));
      },
    );

    test('should not add extra characters to complete simple code block', () {
      const text =
          '```\nSimple code block\nwith multiple lines\nand some special characters: !@#\$%^&*()\n```';
      expect(remend(text), equals(text));
    });

    test(
      'should not add extra characters to complete Python code block with underscores and asterisks',
      () {
        const text =
            '```python\ndef hello_world():\n    """A simple function"""\n    name = "World"\n    print(f"Hello, {name}!")\n    \n    # List comprehension\n    numbers = [x**2 for x in range(10) if x % 2 == 0]\n    return numbers\n\nclass TestClass:\n    def __init__(self, value):\n        self.value = value\n```';
        expect(remend(text), equals(text));
      },
    );

    test('should not add backticks when code block ends properly', () {
      const grokOutput =
          '```python def greet(name): return f"Hello, {name}!"\n```';
      expect(remend(grokOutput), equals(grokOutput));
    });

    test('should handle multiple complete code blocks with newlines', () {
      const text = '```js\ncode1\n```\n\n```python\ncode2\n```';
      expect(remend(text), equals(text));
    });

    test(
      'should correctly handle code on same line as opening backticks with closing on newline',
      () {
        const text =
            '```python def greet(name): return f"Hello, {name}!"\n```';
        expect(remend(text), equals(text));
        final result = remend(text);
        expect(result, isNot(contains('````')));
      },
    );

    test('should only treat truly inline triple backticks as inline', () {
      const inline = '```python code```';
      expect(remend(inline), equals(inline));
      const multiline = '```python code\n```';
      expect(remend(multiline), equals(multiline));
    });

    test(
      'should not treat brackets inside complete code blocks as incomplete links',
      () {
        const text =
            "Here's some code:\n```javascript\nconst arr = [1, 2, 3];\nconsole.log(arr[0]);\n```\nDone with code block.";
        final result = remend(text);
        expect(result, isNot(contains('streamdown:incomplete-link')));
        expect(result, equals(text));
      },
    );

    test(
      'should still detect actual incomplete links outside of code blocks',
      () {
        const text =
            "Here's a code block:\n```bash\necho \"test\"\n```\nAnd here's an [incomplete link";
        final result = remend(text);
        expect(result, contains('streamdown:incomplete-link'));
        expect(
          result,
          equals(
            "Here's a code block:\n```bash\necho \"test\"\n```\nAnd here's an [incomplete link](streamdown:incomplete-link)",
          ),
        );
      },
    );

    test(
      'should not add incomplete-link marker after complete code blocks - #227',
      () {
        const textContent =
            'Precisely.\n\nWhen full-screen TUI applications like **Vim**, **less**, or **htop** start, they switch the terminal into what\'s called the **alternate screen buffer**—a second, temporary display area separate from the main scrollback buffer.\n\n### How it works\nThey send ANSI escape sequences such as:\n```bash\n# Enter alternate screen buffer\necho -e "\\\\e[?1049h"\n\n# Exit (back to normal buffer)\necho -e "\\\\e[?1049l"\n```\n\n- `\\\\e[?1049h` — activates the alternate screen.\n- `\\\\e[?1049l` — deactivates it and restores the previous view.\n\nWhile in this mode:\n- The "scrollback" (your regular terminal history) is hidden.\n- The program gets a fresh, empty screen to draw on.\n- When the program exits, the screen restores exactly as it was before.\n\n### tmux behavior\n`tmux` respects these escape sequences by default. When apps use the alternate buffer, tmux holds that screen separately from the main one. That\'s why, when you scroll in tmux during Vim, you don\'t see your shell history—you have to leave Vim first.\n\nIf someone wants to **disable** this behavior (so the app draws on the main screen and you can scroll back freely), they can set:\n```bash\nset -g terminal-overrides \'xterm*:smcup@:rmcup@\'\n```\nin their `~/.tmux.conf`, which disables use of the alternate buffer entirely.\n\nWould you like me to show how to conditionally toggle that behavior per app or session?';
        final result = remend(textContent);
        expect(result, isNot(contains('streamdown:incomplete-link')));
        expect(result, equals(textContent));
      },
    );

    test(
      'should not add extra __ after code block with underscores followed by bullet list (#300)',
      () {
        const input =
            '```css\n/* Commentary */\n\n[class*="WidgetTitle__Header"] {\n  font-size: 18px !important;\n}\n```\n\nNotes and tips:\n* Use !important only where necessary in CSS.';
        final result = remend(input);
        expect(result, equals(input));
        expect(result, isNot(endsWith('__')));
      },
    );

    test(
      'should handle complete code blocks with underscores followed by asterisk list (#300)',
      () {
        const input =
            '```python\ndef __init__(self):\n    pass\n```\n\n* List item';
        final result = remend(input);
        expect(result, equals(input));
        expect(result, isNot(endsWith('__')));
      },
    );

    test(
      'should handle code blocks with underscores and following text with asterisks (#300)',
      () {
        const input =
            "Here's some code:\n```javascript\nconst my__variable = \"test\";\nconst another_var = 5;\n```\n\nSome notes:\n* First note\n* Second note";
        final result = remend(input);
        expect(result, equals(input));
        expect(result, isNot(endsWith('__')));
      },
    );

    test('should not add stray * from [*] in mermaid code blocks', () {
      const input =
          "Here's a state diagram:\n\n```mermaid\nstateDiagram-v2\n    [*] --> Idle\n    Idle --> Loading: fetch()\n    Loading --> Success: 200 OK\n    Loading --> Error: 4xx/5xx\n    Error --> Loading: retry()\n    Success --> Idle: reset()\n```";
      final result = remend(input);
      expect(result, equals(input));
    });

    test(
      'should not add stray * from [*] in incomplete mermaid code blocks (streaming)',
      () {
        const input =
            "Here's a state diagram:\n\n```mermaid\nstateDiagram-v2\n    [*] --> Idle\n    Idle --> Loading: fetch()";
        final result = remend(input);
        expect(result, equals(input));
      },
    );

    test(
      'should not add stray * when emphasis exists outside code block with [*] inside',
      () {
        const input =
            "*Note:* Here's a state diagram:\n\n```mermaid\nstateDiagram-v2\n    [*] --> Idle\n```";
        final result = remend(input);
        expect(result, equals(input));
      },
    );

    test(
      'should still complete emphasis when * is only outside code blocks',
      () {
        const input =
            '```mermaid\nstateDiagram-v2\n    [*] --> Idle\n```\n\nHere is *incomplete italic';
        final result = remend(input);
        expect(
          result,
          equals(
            '```mermaid\nstateDiagram-v2\n    [*] --> Idle\n```\n\nHere is *incomplete italic*',
          ),
        );
      },
    );

    test('should handle incomplete markdown after code block (#302)', () {
      const text = '```css\ncode here\n```\n\n**incomplete bold';
      expect(
        remend(text),
        equals('```css\ncode here\n```\n\n**incomplete bold**'),
      );
    });
  });
}
