import 'code_block_utils.dart';
import 'patterns.dart';
import 'utils.dart';

// Helper function to check if an asterisk should be skipped
bool _shouldSkipAsterisk(
  String text,
  int index,
  String prevChar,
  String nextChar,
) {
  // Skip if escaped with backslash
  if (prevChar == '\\') return true;
  // Skip if within math block (only check if text has dollar signs)
  final hasMathBlocks = text.contains('\$');
  if (hasMathBlocks && isWithinMathBlock(text, index)) return true;
  // Special handling for *** sequences
  // If this is the first * in ***, don't skip it - it can close a single * italic
  // Example: **bold and *italic*** should count the first * of *** as closing the italic
  if (prevChar != '*' && nextChar == '*') {
    final nextNextChar = index < text.length - 2 ? text[index + 2] : '';
    if (nextNextChar == '*') {
      // This is the first * in a *** sequence
      // Count it as a single asterisk for matching purposes
      return false;
    }
    // This is the first * in ** (not ***)
    return true;
  }
  // Skip if this is the second or third * in a sequence
  if (prevChar == '*') return true;
  // Skip if asterisk is word-internal (between word characters)
  if (prevChar.isNotEmpty &&
      nextChar.isNotEmpty &&
      isWordChar(prevChar) &&
      isWordChar(nextChar)) {
    return true;
  }
  // Skip if flanked by whitespace on both sides (not a valid emphasis delimiter per CommonMark)
  // This also catches list markers (e.g., "* item") since they have whitespace on both sides
  final prevIsWhitespace =
      prevChar.isEmpty ||
      prevChar == ' ' ||
      prevChar == '\t' ||
      prevChar == '\n';
  final nextIsWhitespace =
      nextChar.isEmpty ||
      nextChar == ' ' ||
      nextChar == '\t' ||
      nextChar == '\n';
  if (prevIsWhitespace && nextIsWhitespace) return true;
  return false;
}

// OPTIMIZATION: Counts single asterisks without split("").reduce()
// Counts single asterisks that are not part of double asterisks, not escaped, not list markers, not word-internal,
// and not inside fenced code blocks
int countSingleAsterisks(String text) {
  var count = 0;
  var inCodeBlock = false;
  final len = text.length;
  for (var index = 0; index < len; index += 1) {
    // Track fenced code blocks (```)
    if (text[index] == '`' &&
        index + 2 < len &&
        text[index + 1] == '`' &&
        text[index + 2] == '`') {
      inCodeBlock = !inCodeBlock;
      index += 2;
      continue;
    }
    // Skip content inside fenced code blocks
    if (inCodeBlock) continue;
    if (text[index] != '*') continue;
    final prevChar = index > 0 ? text[index - 1] : '';
    final nextChar = index < len - 1 ? text[index + 1] : '';
    if (!_shouldSkipAsterisk(text, index, prevChar, nextChar)) {
      count += 1;
    }
  }
  return count;
}

// Helper function to check if an underscore should be skipped
bool _shouldSkipUnderscore(
  String text,
  int index,
  String prevChar,
  String nextChar,
) {
  // Skip if escaped with backslash
  if (prevChar == '\\') return true;
  // Skip if within math block (only check if text has dollar signs)
  final hasMathBlocks = text.contains('\$');
  if (hasMathBlocks && isWithinMathBlock(text, index)) return true;
  // Skip if within a link or image URL
  if (isWithinLinkOrImageUrl(text, index)) return true;
  // Skip if within an HTML tag (e.g. <a target="_blank">)
  if (isWithinHtmlTag(text, index)) return true;
  // Skip if part of __
  if (prevChar == '_' || nextChar == '_') return true;
  // Skip if underscore is word-internal (between word characters)
  if (prevChar.isNotEmpty &&
      nextChar.isNotEmpty &&
      isWordChar(prevChar) &&
      isWordChar(nextChar)) {
    return true;
  }
  return false;
}

// OPTIMIZATION: Counts single underscores without split("").reduce()
// Counts single underscores that are not part of double underscores, not escaped, not in math blocks,
// and not inside fenced code blocks
int countSingleUnderscores(String text) {
  var count = 0;
  var inCodeBlock = false;
  final len = text.length;
  for (var index = 0; index < len; index += 1) {
    // Track fenced code blocks (```)
    if (text[index] == '`' &&
        index + 2 < len &&
        text[index + 1] == '`' &&
        text[index + 2] == '`') {
      inCodeBlock = !inCodeBlock;
      index += 2;
      continue;
    }
    // Skip content inside fenced code blocks
    if (inCodeBlock) continue;
    if (text[index] != '_') continue;
    final prevChar = index > 0 ? text[index - 1] : '';
    final nextChar = index < len - 1 ? text[index + 1] : '';
    if (!_shouldSkipUnderscore(text, index, prevChar, nextChar)) {
      count += 1;
    }
  }
  return count;
}

// Counts triple asterisks that are not part of quadruple or more asterisks
// and not inside fenced code blocks
// OPTIMIZATION: Count *** without regex to avoid allocation
int countTripleAsterisks(String text) {
  var count = 0;
  var consecutiveAsterisks = 0;
  var inCodeBlock = false;
  for (var i = 0; i < text.length; i += 1) {
    // Track fenced code blocks (```)
    if (text[i] == '`' &&
        i + 2 < text.length &&
        text[i + 1] == '`' &&
        text[i + 2] == '`') {
      // Flush any pending asterisks before toggling
      if (consecutiveAsterisks >= 3) {
        count += consecutiveAsterisks ~/ 3;
      }
      consecutiveAsterisks = 0;
      inCodeBlock = !inCodeBlock;
      i += 2;
      continue;
    }
    // Skip content inside fenced code blocks
    if (inCodeBlock) continue;
    if (text[i] == '*') {
      consecutiveAsterisks += 1;
    } else {
      // End of asterisk sequence
      if (consecutiveAsterisks >= 3) {
        count += consecutiveAsterisks ~/ 3;
      }
      consecutiveAsterisks = 0;
    }
  }
  // Handle trailing asterisks
  if (consecutiveAsterisks >= 3) {
    count += consecutiveAsterisks ~/ 3;
  }
  return count;
}

// Counts ** pairs outside fenced code blocks
int _countDoubleAsterisksOutsideCodeBlocks(String text) {
  var count = 0;
  var inCodeBlock = false;
  for (var i = 0; i < text.length; i += 1) {
    if (text[i] == '`' &&
        i + 2 < text.length &&
        text[i + 1] == '`' &&
        text[i + 2] == '`') {
      inCodeBlock = !inCodeBlock;
      i += 2;
      continue;
    }
    if (inCodeBlock) continue;
    if (text[i] == '*' && i + 1 < text.length && text[i + 1] == '*') {
      count += 1;
      i += 1;
    }
  }
  return count;
}

// Counts __ pairs outside fenced code blocks
int _countDoubleUnderscoresOutsideCodeBlocks(String text) {
  var count = 0;
  var inCodeBlock = false;
  for (var i = 0; i < text.length; i += 1) {
    if (text[i] == '`' &&
        i + 2 < text.length &&
        text[i + 1] == '`' &&
        text[i + 2] == '`') {
      inCodeBlock = !inCodeBlock;
      i += 2;
      continue;
    }
    if (inCodeBlock) continue;
    if (text[i] == '_' && i + 1 < text.length && text[i + 1] == '_') {
      count += 1;
      i += 1;
    }
  }
  return count;
}

// Helper to check if bold marker should not be completed
bool _shouldSkipBoldCompletion(
  String text,
  String contentAfterMarker,
  int markerIndex,
) {
  if (contentAfterMarker.isEmpty ||
      whitespaceOrMarkersPattern.hasMatch(contentAfterMarker)) {
    return true;
  }
  // Check if this is in a list item with multiline content
  final beforeMarker = text.substring(0, markerIndex);
  final lastNewlineBeforeMarker = beforeMarker.lastIndexOf('\n');
  final lineStart = lastNewlineBeforeMarker == -1
      ? 0
      : lastNewlineBeforeMarker + 1;
  final lineBeforeMarker = text.substring(lineStart, markerIndex);
  if (listItemPattern.hasMatch(lineBeforeMarker)) {
    final hasNewlineInContent = contentAfterMarker.contains('\n');
    if (hasNewlineInContent) return true;
  }
  return isHorizontalRule(text, markerIndex, '*');
}

// Completes incomplete bold formatting (**)
String handleIncompleteBold(String text) {
  final boldMatch = boldPattern.firstMatch(text);
  if (boldMatch == null) return text;
  final contentAfterMarker = boldMatch[2]!;
  final markerIndex = text.lastIndexOf(boldMatch[1]!);
  // Check if the bold marker is within a code block (fenced or inline)
  if (isInsideCodeBlock(text, markerIndex) ||
      isWithinCompleteInlineCode(text, markerIndex)) {
    return text;
  }
  if (_shouldSkipBoldCompletion(text, contentAfterMarker, markerIndex)) {
    return text;
  }
  final asteriskPairs = _countDoubleAsterisksOutsideCodeBlocks(text);
  if (asteriskPairs % 2 == 1) {
    // Check for half-complete closing marker: **content* should become **content**
    // The trailing * is the first char of the closing ** being streamed
    if (contentAfterMarker.endsWith('*')) return '$text*';
    return '$text**';
  }
  return text;
}

// Helper to check if italic marker should not be completed
bool _shouldSkipItalicCompletion(
  String text,
  String contentAfterMarker,
  int markerIndex,
) {
  if (contentAfterMarker.isEmpty ||
      whitespaceOrMarkersPattern.hasMatch(contentAfterMarker)) {
    return true;
  }
  // Check if this is in a list item with multiline content
  final beforeMarker = text.substring(0, markerIndex);
  final lastNewlineBeforeMarker = beforeMarker.lastIndexOf('\n');
  final lineStart = lastNewlineBeforeMarker == -1
      ? 0
      : lastNewlineBeforeMarker + 1;
  final lineBeforeMarker = text.substring(lineStart, markerIndex);
  if (listItemPattern.hasMatch(lineBeforeMarker)) {
    final hasNewlineInContent = contentAfterMarker.contains('\n');
    if (hasNewlineInContent) return true;
  }
  return isHorizontalRule(text, markerIndex, '_');
}

// Completes incomplete italic formatting with double underscores (__)
String handleIncompleteDoubleUnderscoreItalic(String text) {
  final italicMatch = italicPattern.firstMatch(text);
  if (italicMatch == null) {
    // Check for half-complete closing marker: __content_ should become __content__
    // The pattern /(__)([^_]*?)$/ won't match __content_ because it ends with _
    // So we need a separate check for this case
    final halfCompleteMatch = halfCompleteUnderscorePattern.firstMatch(text);
    if (halfCompleteMatch != null) {
      final markerIndex = text.lastIndexOf(halfCompleteMatch[1]!);
      if (!(isInsideCodeBlock(text, markerIndex) ||
          isWithinCompleteInlineCode(text, markerIndex))) {
        final underscorePairs = _countDoubleUnderscoresOutsideCodeBlocks(text);
        if (underscorePairs % 2 == 1) return '${text}_';
      }
    }
    return text;
  }
  final contentAfterMarker = italicMatch[2]!;
  final markerIndex = text.lastIndexOf(italicMatch[1]!);
  // Check if the italic marker is within a code block (fenced or inline)
  if (isInsideCodeBlock(text, markerIndex) ||
      isWithinCompleteInlineCode(text, markerIndex)) {
    return text;
  }
  if (_shouldSkipItalicCompletion(text, contentAfterMarker, markerIndex)) {
    return text;
  }
  final underscorePairs = _countDoubleUnderscoresOutsideCodeBlocks(text);
  if (underscorePairs % 2 == 1) return '${text}__';
  return text;
}

// Helper function to find the first single asterisk index (skips fenced code blocks)
int _findFirstSingleAsteriskIndex(String text) {
  var inCodeBlock = false;
  for (var i = 0; i < text.length; i += 1) {
    // Track fenced code blocks (```)
    if (text[i] == '`' &&
        i + 2 < text.length &&
        text[i + 1] == '`' &&
        text[i + 2] == '`') {
      inCodeBlock = !inCodeBlock;
      i += 2;
      continue;
    }
    // Skip content inside fenced code blocks
    if (inCodeBlock) continue;
    final prevChar = i > 0 ? text[i - 1] : '';
    final nextChar = i < text.length - 1 ? text[i + 1] : '';
    if (text[i] == '*' &&
        prevChar != '*' &&
        nextChar != '*' &&
        prevChar != '\\' &&
        !isWithinMathBlock(text, i)) {
      // Skip if flanked by whitespace on both sides (not a valid emphasis delimiter)
      final prevIsWs =
          prevChar.isEmpty ||
          prevChar == ' ' ||
          prevChar == '\t' ||
          prevChar == '\n';
      final nextIsWs =
          nextChar.isEmpty ||
          nextChar == ' ' ||
          nextChar == '\t' ||
          nextChar == '\n';
      if (prevIsWs && nextIsWs) continue;
      // Check if asterisk is word-internal (between word characters)
      if (prevChar.isNotEmpty &&
          nextChar.isNotEmpty &&
          isWordChar(prevChar) &&
          isWordChar(nextChar)) {
        continue;
      }
      return i;
    }
  }
  return -1;
}

// Completes incomplete italic formatting with single asterisks (*)
String handleIncompleteSingleAsteriskItalic(String text) {
  final singleAsteriskMatch = singleAsteriskPattern.firstMatch(text);
  if (singleAsteriskMatch == null) return text;
  final firstSingleAsteriskIndex = _findFirstSingleAsteriskIndex(text);
  if (firstSingleAsteriskIndex == -1) return text;
  // Don't close if the marker is inside a complete inline code span or fenced code block
  if (isInsideCodeBlock(text, firstSingleAsteriskIndex) ||
      isWithinCompleteInlineCode(text, firstSingleAsteriskIndex)) {
    return text;
  }
  // Get content after the first single asterisk
  final contentAfterFirstAsterisk = text.substring(
    firstSingleAsteriskIndex + 1,
  );
  // Check if there's meaningful content after the asterisk
  // Don't close if content is only whitespace or emphasis markers
  if (contentAfterFirstAsterisk.isEmpty ||
      whitespaceOrMarkersPattern.hasMatch(contentAfterFirstAsterisk)) {
    return text;
  }
  final singleAsterisks = countSingleAsterisks(text);
  if (singleAsterisks % 2 == 1) return '$text*';
  return text;
}

// Helper function to find the first single underscore index (skips fenced code blocks)
int _findFirstSingleUnderscoreIndex(String text) {
  var inCodeBlock = false;
  for (var i = 0; i < text.length; i += 1) {
    // Track fenced code blocks (```)
    if (text[i] == '`' &&
        i + 2 < text.length &&
        text[i + 1] == '`' &&
        text[i + 2] == '`') {
      inCodeBlock = !inCodeBlock;
      i += 2;
      continue;
    }
    // Skip content inside fenced code blocks
    if (inCodeBlock) continue;
    final prevChar = i > 0 ? text[i - 1] : '';
    final nextChar = i < text.length - 1 ? text[i + 1] : '';
    if (text[i] == '_' &&
        prevChar != '_' &&
        nextChar != '_' &&
        prevChar != '\\' &&
        !isWithinMathBlock(text, i) &&
        !isWithinLinkOrImageUrl(text, i)) {
      // Check if underscore is word-internal (between word characters)
      if (prevChar.isNotEmpty &&
          nextChar.isNotEmpty &&
          isWordChar(prevChar) &&
          isWordChar(nextChar)) {
        continue;
      }
      return i;
    }
  }
  return -1;
}

// Helper function to insert closing underscore, handling trailing newlines
String _insertClosingUnderscore(String text) {
  // If text ends with newline(s), insert underscore before them
  // Use string methods instead of regex to avoid ReDoS vulnerability
  var endIndex = text.length;
  while (endIndex > 0 && text[endIndex - 1] == '\n') {
    endIndex -= 1;
  }
  if (endIndex < text.length) {
    final textBeforeNewlines = text.substring(0, endIndex);
    final trailingNewlines = text.substring(endIndex);
    return '${textBeforeNewlines}_$trailingNewlines';
  }
  return '${text}_';
}

// Helper to handle trailing ** for proper nesting of _ and ** markers
String? _handleTrailingAsterisksForUnderscore(String text) {
  if (!text.endsWith('**')) return null;
  final textWithoutTrailingAsterisks = text.substring(0, text.length - 2);
  final asteriskPairsAfterRemoval = _countDoubleAsterisksOutsideCodeBlocks(
    textWithoutTrailingAsterisks,
  );
  // If removing trailing ** makes the count odd, it was added to close an unclosed **
  if (asteriskPairsAfterRemoval % 2 != 1) return null;
  final firstDoubleAsteriskIndex = textWithoutTrailingAsterisks.indexOf('**');
  final underscoreIndex = _findFirstSingleUnderscoreIndex(
    textWithoutTrailingAsterisks,
  );
  // If ** opened before _, then _ should close before **
  if (firstDoubleAsteriskIndex != -1 &&
      underscoreIndex != -1 &&
      firstDoubleAsteriskIndex < underscoreIndex) {
    return '${textWithoutTrailingAsterisks}_**';
  }
  return null;
}

// Completes incomplete italic formatting with single underscores (_)
String handleIncompleteSingleUnderscoreItalic(String text) {
  final singleUnderscoreMatch = singleUnderscorePattern.firstMatch(text);
  if (singleUnderscoreMatch == null) return text;
  final firstSingleUnderscoreIndex = _findFirstSingleUnderscoreIndex(text);
  if (firstSingleUnderscoreIndex == -1) return text;
  // Get content after the first single underscore
  final contentAfterFirstUnderscore = text.substring(
    firstSingleUnderscoreIndex + 1,
  );
  // Check if there's meaningful content after the underscore
  // Don't close if content is only whitespace or emphasis markers
  if (contentAfterFirstUnderscore.isEmpty ||
      whitespaceOrMarkersPattern.hasMatch(contentAfterFirstUnderscore)) {
    return text;
  }
  if (isInsideCodeBlock(text, firstSingleUnderscoreIndex) ||
      isWithinCompleteInlineCode(text, firstSingleUnderscoreIndex)) {
    return text;
  }
  final singleUnderscores = countSingleUnderscores(text);
  if (singleUnderscores % 2 == 1) {
    // Check if we need to insert _ before trailing ** for proper nesting
    final trailingResult = _handleTrailingAsterisksForUnderscore(text);
    if (trailingResult != null) return trailingResult;
    return _insertClosingUnderscore(text);
  }
  return text;
}

// Helper to check if bold-italic markers are already balanced
bool _areBoldItalicMarkersBalanced(String text) {
  final asteriskPairs = _countDoubleAsterisksOutsideCodeBlocks(text);
  final singleAsterisks = countSingleAsterisks(text);
  return asteriskPairs % 2 == 0 && singleAsterisks % 2 == 0;
}

// Helper to check if bold-italic should be skipped
bool _shouldSkipBoldItalicCompletion(
  String text,
  String contentAfterMarker,
  int markerIndex,
) {
  if (contentAfterMarker.isEmpty ||
      whitespaceOrMarkersPattern.hasMatch(contentAfterMarker)) {
    return true;
  }
  if (isInsideCodeBlock(text, markerIndex) ||
      isWithinCompleteInlineCode(text, markerIndex)) {
    return true;
  }
  return isHorizontalRule(text, markerIndex, '*');
}

// Completes incomplete bold-italic formatting (***)
String handleIncompleteBoldItalic(String text) {
  // Don't process if text is only asterisks and has 4 or more consecutive asterisks
  if (fourOrMoreAsterisksPattern.hasMatch(text)) return text;
  final boldItalicMatch = boldItalicPattern.firstMatch(text);
  if (boldItalicMatch == null) return text;
  final contentAfterMarker = boldItalicMatch[2]!;
  final markerIndex = text.lastIndexOf(boldItalicMatch[1]!);
  if (_shouldSkipBoldItalicCompletion(text, contentAfterMarker, markerIndex)) {
    return text;
  }
  final tripleAsteriskCount = countTripleAsterisks(text);
  if (tripleAsteriskCount % 2 == 1) {
    // If both ** and * are balanced, don't add closing ***
    // The *** is likely overlapping markers (e.g., **bold and *italic***)
    if (_areBoldItalicMarkersBalanced(text)) return text;
    return '$text***';
  }
  return text;
}
