// Check if a position is inside a code block (between ``` or `)
bool isInsideCodeBlock(String text, int position) {
  // Check for inline code (backticks)
  var inInlineCode = false;
  var inMultilineCode = false;
  for (var i = 0; i < position; i += 1) {
    // Skip escaped backticks
    if (text[i] == '\\' && i + 1 < text.length && text[i + 1] == '`') {
      i += 1;
      continue;
    }
    // Check for triple backticks (multiline code blocks)
    if (i + 2 < text.length && text.substring(i, i + 3) == '```') {
      inMultilineCode = !inMultilineCode;
      i += 2; // Skip the next 2 backticks
      continue;
    }
    // Only check for inline code if not in multiline code
    if (!inMultilineCode && text[i] == '`') {
      inInlineCode = !inInlineCode;
    }
  }
  return inInlineCode || inMultilineCode;
}

// Checks if a backtick at position i is part of a triple backtick sequence
bool isPartOfTripleBacktick(String text, int i) {
  final isTripleStart =
      i + 2 < text.length && text.substring(i, i + 3) == '```';
  final isTripleMiddle =
      i > 0 && i + 1 < text.length && text.substring(i - 1, i + 2) == '```';
  final isTripleEnd = i > 1 && text.substring(i - 2, i + 1) == '```';
  return isTripleStart || isTripleMiddle || isTripleEnd;
}

// Counts single backticks that are not part of triple backticks or escaped
int countSingleBackticks(String text) {
  var count = 0;
  for (var i = 0; i < text.length; i += 1) {
    // Skip escaped backticks
    if (text[i] == '\\' && i + 1 < text.length && text[i + 1] == '`') {
      i += 1;
      continue;
    }
    if (text[i] == '`' && !isPartOfTripleBacktick(text, i)) {
      count += 1;
    }
  }
  return count;
}

// Check if a position is inside a COMPLETE inline code span (both opening and closing backtick present).
// Returns false for incomplete inline code spans (streaming) so emphasis markers can still be completed.
bool isWithinCompleteInlineCode(String text, int position) {
  var inInlineCode = false;
  var inMultilineCode = false;
  var inlineCodeStart = -1;
  for (var i = 0; i < text.length; i += 1) {
    // Skip escaped backticks
    if (text[i] == '\\' && i + 1 < text.length && text[i + 1] == '`') {
      i += 1;
      continue;
    }
    // Check for triple backticks (multiline code blocks)
    if (i + 2 < text.length && text.substring(i, i + 3) == '```') {
      inMultilineCode = !inMultilineCode;
      i += 2;
      continue;
    }
    // Only check for inline code if not in multiline code
    if (!inMultilineCode && text[i] == '`') {
      if (inInlineCode) {
        // Found closing backtick — check if position is inside this complete span
        if (inlineCodeStart < position && position < i) return true;
        inInlineCode = false;
        inlineCodeStart = -1;
      } else {
        inInlineCode = true;
        inlineCodeStart = i;
      }
    }
  }
  return false;
}
