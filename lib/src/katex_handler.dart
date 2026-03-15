// Helper function to check if a backtick is part of a triple backtick
bool _isTripleBacktick(String text, int index) =>
    (index >= 2 && text.substring(index - 2, index + 1) == '```') ||
    (index >= 1 &&
        index + 1 < text.length &&
        text.substring(index - 1, index + 2) == '```') ||
    (index <= text.length - 3 && text.substring(index, index + 3) == '```');

// Helper function to count $$ pairs outside of inline code blocks
int _countDollarPairs(String text) {
  var dollarPairs = 0;
  var inInlineCode = false;
  for (var i = 0; i < text.length - 1; i += 1) {
    if (text[i] == '`' && !_isTripleBacktick(text, i)) {
      inInlineCode = !inInlineCode;
    }
    if (!inInlineCode && text[i] == '\$' && text[i + 1] == '\$') {
      dollarPairs += 1;
      i += 1;
    }
  }
  return dollarPairs;
}

// Helper function to count single $ signs (excluding $$) outside of code blocks
int _countSingleDollars(String text) {
  var count = 0;
  var inInlineCode = false;
  for (var i = 0; i < text.length; i += 1) {
    if (text[i] == '\\') {
      i += 1;
      continue;
    }
    if (text[i] == '`' && !_isTripleBacktick(text, i)) {
      inInlineCode = !inInlineCode;
      continue;
    }
    if (!inInlineCode && text[i] == '\$') {
      if (i + 1 < text.length && text[i + 1] == '\$') {
        i += 1;
      } else {
        count += 1;
      }
    }
  }
  return count;
}

// Helper function to add closing $$ with appropriate formatting
String _addClosingKatex(String text) {
  // If the text already ends with a partial closing $ (but not $$),
  // just append one more $ to complete the $$ marker.
  if (text.endsWith('\$') && !text.endsWith('\$\$')) return '$text\$';
  final firstDollarIndex = text.indexOf('\$\$');
  final hasNewlineAfterStart =
      firstDollarIndex != -1 && text.indexOf('\n', firstDollarIndex) != -1;
  if (hasNewlineAfterStart && !text.endsWith('\n')) return '$text\n\$\$';
  return '$text\$\$';
}

// Completes incomplete block KaTeX formatting ($$)
String handleIncompleteBlockKatex(String text) {
  final dollarPairs = _countDollarPairs(text);
  if (dollarPairs % 2 == 0) return text;
  return _addClosingKatex(text);
}

// Completes incomplete inline KaTeX formatting ($...$)
String handleIncompleteInlineKatex(String text) {
  final count = _countSingleDollars(text);
  if (count % 2 == 1) return '$text\$';
  return text;
}
