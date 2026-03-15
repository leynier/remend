import 'code_block_utils.dart';
import 'patterns.dart';

final _tripleBacktickPattern = RegExp(r'```');

// Helper function to check for incomplete inline triple backticks
String? _handleInlineTripleBackticks(String text) {
  final inlineTripleBacktickMatch = inlineTripleBacktickPattern.firstMatch(
    text,
  );
  if (inlineTripleBacktickMatch == null || text.contains('\n')) return null;
  // Check if it ends with exactly 2 backticks (incomplete)
  if (text.endsWith('``') && !text.endsWith('```')) return '$text`';
  // Already complete inline triple backticks
  return text;
}

// Helper function to check if we're inside an incomplete code block
bool _isInsideIncompleteCodeBlock(String text) {
  final allTripleBackticks = _tripleBacktickPattern.allMatches(text).length;
  return allTripleBackticks % 2 == 1;
}

// Completes incomplete inline code formatting (`)
// Avoids completing if inside an incomplete code block
String handleIncompleteInlineCode(String text) {
  // Check if we have inline triple backticks (starts with ``` and should end with ```)
  // This pattern should ONLY match truly inline code (no newlines)
  // Examples: ```code``` or ```python code```
  final inlineResult = _handleInlineTripleBackticks(text);
  if (inlineResult != null) return inlineResult;
  final inlineCodeMatch = inlineCodePattern.firstMatch(text);
  if (inlineCodeMatch != null && !_isInsideIncompleteCodeBlock(text)) {
    // Don't close if there's no meaningful content after the opening marker
    // inlineCodeMatch[2] contains the content after `
    // Check if content is only whitespace or other emphasis markers
    final contentAfterMarker = inlineCodeMatch[2]!;
    if (contentAfterMarker.isEmpty ||
        whitespaceOrMarkersPattern.hasMatch(contentAfterMarker)) {
      return text;
    }
    final singleBacktickCount = countSingleBackticks(text);
    if (singleBacktickCount % 2 == 1) return '$text`';
  }
  return text;
}
