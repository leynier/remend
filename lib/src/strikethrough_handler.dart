import 'code_block_utils.dart';
import 'patterns.dart';

// Completes incomplete strikethrough formatting (~~)
String handleIncompleteStrikethrough(String text) {
  final strikethroughMatch = strikethroughPattern.firstMatch(text);
  if (strikethroughMatch != null) {
    // Don't close if there's no meaningful content after the opening markers
    // strikethroughMatch[2] contains the content after ~~
    // Check if content is only whitespace or other emphasis markers
    final contentAfterMarker = strikethroughMatch[2]!;
    if (contentAfterMarker.isEmpty ||
        whitespaceOrMarkersPattern.hasMatch(contentAfterMarker)) {
      return text;
    }
    // Don't close if the marker is inside an inline code span or fenced code block
    final markerIndex = text.lastIndexOf(strikethroughMatch[1]!);
    if (isInsideCodeBlock(text, markerIndex) ||
        isWithinCompleteInlineCode(text, markerIndex)) {
      return text;
    }
    // doubleTildeGlobalPattern always matches when strikethroughPattern matched
    final tildePairs = doubleTildeGlobalPattern.allMatches(text).length;
    if (tildePairs % 2 == 1) return '$text~~';
  } else {
    // Check for half-complete closing marker: ~~content~ should become ~~content~~
    // The pattern /(~~)([^~]*?)$/ won't match ~~content~ because it ends with ~
    final halfCompleteMatch = halfCompleteTildePattern.firstMatch(text);
    if (halfCompleteMatch != null) {
      // Don't close if the marker is inside an inline code span or fenced code block
      final markerIndex =
          text.lastIndexOf(halfCompleteMatch[0]!.substring(0, 2));
      if (isInsideCodeBlock(text, markerIndex) ||
          isWithinCompleteInlineCode(text, markerIndex)) {
        return text;
      }
      // doubleTildeGlobalPattern always matches when halfCompleteTildePattern matched
      final tildePairs = doubleTildeGlobalPattern.allMatches(text).length;
      if (tildePairs % 2 == 1) return '$text~';
    }
  }
  return text;
}
