import 'code_block_utils.dart';

// Handles > characters that are comparison operators inside list items
// AI models frequently generate list items like "- > 25: expensive" where
// the > is a "greater than" operator, not a blockquote marker.

// Match list items where > appears as a comparison operator followed by a digit
// Pattern: list marker (-, *, +, or 1.) followed by > then optional = and a digit
// The \d check ensures we only escape > when it's clearly a comparison (not a real blockquote)
final _listComparisonPattern =
    RegExp(r'^(\s*(?:[-*+]|\d+[.)]) +)>(=?\s*[$]?\d)', multiLine: true);

String handleComparisonOperators(String text) {
  // Quick check: if there's no > in the text, skip processing
  if (!text.contains('>')) {
    return text;
  }
  return text.replaceAllMapped(_listComparisonPattern, (match) {
    // Don't escape inside code blocks
    if (isInsideCodeBlock(text, match.start)) {
      return match[0]!;
    }
    return '${match[1]}\\>${match[2]}';
  });
}
