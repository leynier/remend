import 'patterns.dart';

// OPTIMIZATION: Precompute which characters are word characters
// Using ASCII fast path before falling back to Unicode regex
bool isWordChar(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  // ASCII optimization: a-z, A-Z, 0-9, _
  if ((code >= 48 && code <= 57) || // 0-9
      (code >= 65 && code <= 90) || // A-Z
      (code >= 97 && code <= 122) || // a-z
      code == 95) {
    // _
    return true;
  }
  // Fallback to regex for Unicode characters (less common)
  return letterNumberUnderscorePattern.hasMatch(char);
}

// Check if a position is within a code block (between ``` markers)
bool isWithinCodeBlock(String text, int position) {
  var inCodeBlock = false;
  for (var i = 0; i < position; i += 1) {
    // Check for triple backticks
    if (i + 2 < text.length &&
        text[i] == '`' &&
        text[i + 1] == '`' &&
        text[i + 2] == '`') {
      inCodeBlock = !inCodeBlock;
      i += 2; // Skip the next two backticks
    }
  }
  return inCodeBlock;
}

// Helper function to find the matching opening bracket for a closing bracket
// Handles nested brackets correctly by searching backwards
int findMatchingOpeningBracket(String text, int closeIndex) {
  var depth = 1;
  for (var i = closeIndex - 1; i >= 0; i -= 1) {
    if (text[i] == ']') {
      depth += 1;
    } else if (text[i] == '[') {
      depth -= 1;
      if (depth == 0) return i;
    }
  }
  return -1; // No matching bracket found
}

// Helper function to find the matching closing bracket for an opening bracket
// Handles nested brackets correctly
int findMatchingClosingBracket(String text, int openIndex) {
  var depth = 1;
  for (var i = openIndex + 1; i < text.length; i += 1) {
    if (text[i] == '[') {
      depth += 1;
    } else if (text[i] == ']') {
      depth -= 1;
      if (depth == 0) return i;
    }
  }
  return -1; // No matching bracket found
}

// Check if a position is within a math block (between $ or $$)
bool isWithinMathBlock(String text, int position) {
  // Count dollar signs before this position
  var inInlineMath = false;
  var inBlockMath = false;
  for (var i = 0; i < text.length && i < position; i += 1) {
    // Skip escaped dollar signs
    if (text[i] == '\\' && i + 1 < text.length && text[i + 1] == '\$') {
      i += 1; // Skip the next character
      continue;
    }
    if (text[i] == '\$') {
      // Check for block math ($$)
      if (i + 1 < text.length && text[i + 1] == '\$') {
        inBlockMath = !inBlockMath;
        i += 1; // Skip the second $
        inInlineMath = false; // Block math takes precedence
      } else if (!inBlockMath) {
        // Only toggle inline math if not in block math
        inInlineMath = !inInlineMath;
      }
    }
  }
  return inInlineMath || inBlockMath;
}

// Helper to check if position is before closing paren on same line
bool _isBeforeClosingParen(String text, int position) {
  for (var j = position; j < text.length; j += 1) {
    if (text[j] == ')') return true;
    if (text[j] == '\n') return false;
  }
  return false;
}

// Check if a position is within a link or image URL
// Links and images have the format [text](url) or ![alt](url)
bool isWithinLinkOrImageUrl(String text, int position) {
  // Search backwards from position to find if we're inside a (url) part
  for (var i = position - 1; i >= 0; i -= 1) {
    if (text[i] == ')') return false;
    if (text[i] == '(') {
      // Check if there's a ] immediately before the (
      if (i > 0 && text[i - 1] == ']') {
        // We're potentially inside a link/image URL
        // Check if we're before the closing )
        return _isBeforeClosingParen(text, position);
      }
      return false;
    }
    if (text[i] == '\n') return false;
  }
  return false;
}

// Check if a position is within an HTML tag (between < and >)
// e.g. <a target="_blank"> — the underscore in _blank is inside the tag
bool isWithinHtmlTag(String text, int position) {
  // Search backwards from position to find < or >
  for (var i = position - 1; i >= 0; i -= 1) {
    if (text[i] == '>') {
      return false; // Found closing > first — we're outside a tag
    }
    if (text[i] == '<') {
      // Found opening < — check it starts a valid tag (followed by letter or /)
      final nextChar = i + 1 < text.length ? text[i + 1] : '';
      if (nextChar.isNotEmpty &&
          ((nextChar.codeUnitAt(0) >= 97 &&
                  nextChar.codeUnitAt(0) <= 122) || // a-z
              (nextChar.codeUnitAt(0) >= 65 &&
                  nextChar.codeUnitAt(0) <= 90) || // A-Z
              nextChar == '/')) {
        return true;
      }
      return false;
    }
    if (text[i] == '\n') return false; // Tags don't span lines in this context
  }
  return false;
}

// Check if a marker sequence appears to be a horizontal rule
// Horizontal rules must be on their own line with optional leading/trailing whitespace
// Valid patterns: ---, ***, ___, or longer sequences with optional spaces between markers
bool isHorizontalRule(String text, int markerIndex, String marker) {
  // Find the start of the line containing this marker
  var lineStart = 0;
  for (var i = markerIndex - 1; i >= 0; i -= 1) {
    if (text[i] == '\n') {
      lineStart = i + 1;
      break;
    }
  }
  // Find the end of the line containing this marker
  var lineEnd = text.length;
  for (var i = markerIndex; i < text.length; i += 1) {
    if (text[i] == '\n') {
      lineEnd = i;
      break;
    }
  }
  final line = text.substring(lineStart, lineEnd);
  // Check if the line matches horizontal rule pattern
  // Must be: optional spaces + at least 3 markers + optional spaces
  // Can have spaces between markers (e.g., "* * *")
  var markerCount = 0;
  var hasNonWhitespaceNonMarker = false;
  for (var i = 0; i < line.length; i += 1) {
    final char = line[i];
    if (char == marker) {
      markerCount += 1;
    } else if (char != ' ' && char != '\t') {
      // Found a character that's not a space, tab, or the marker
      hasNonWhitespaceNonMarker = true;
      break;
    }
  }
  // A horizontal rule needs:
  // 1. At least 3 markers
  // 2. No other non-whitespace characters on the line
  return markerCount >= 3 && !hasNonWhitespaceNonMarker;
}
