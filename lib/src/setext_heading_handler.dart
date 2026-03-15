// Handles incomplete setext heading underlines during streaming
// Setext headings use --- or === on the line below text to create headings
// During streaming, partial list items (like "-") can be misinterpreted as setext heading underlines

// Regex patterns defined at top level for performance
final _dashOnlyPattern = RegExp(r'^-{1,2}$');
final _dashWithSpacePattern = RegExp(r'^[\s]*-{1,2}[\s]+$');
final _equalsOnlyPattern = RegExp(r'^={1,2}$');
final _equalsWithSpacePattern = RegExp(r'^[\s]*={1,2}[\s]+$');

/// Detects if the text ends with a potential incomplete setext heading underline
/// and adds a space to break the setext heading pattern
String handleIncompleteSetextHeading(String text) {
  // Find the last line of the text
  final lastNewlineIndex = text.lastIndexOf('\n');
  // If there's no newline, we can't have a setext heading
  if (lastNewlineIndex == -1) {
    return text;
  }
  final lastLine = text.substring(lastNewlineIndex + 1);
  final previousContent = text.substring(0, lastNewlineIndex);
  // Check if last line is only dashes or equals (potential setext heading underline)
  // We need to check for patterns like: "-", "--", "=", "=="
  // But NOT "---" or "===" (which are valid horizontal rules / setext headings)
  // Trim to check the actual content
  final trimmedLastLine = lastLine.trim();
  // Check if it's ONLY dashes (1 or 2) - but if there's trailing space, don't modify
  // If the last line ends with space after the dashes, it's already broken the setext heading pattern
  if (_dashOnlyPattern.hasMatch(trimmedLastLine) &&
      !_dashWithSpacePattern.hasMatch(lastLine)) {
    // Check if there's content on the previous line (required for setext heading)
    final lines = previousContent.split('\n');
    final previousLine = lines.last;
    // If the previous line has content, this could be interpreted as a setext heading
    if (previousLine.trim().isNotEmpty) {
      // Add text to break the setext heading pattern
      // We add a zero-width space (\u200B) which breaks the pattern without being visible
      // This is better than adding a regular space which markdown parsers may still interpret
      // as a setext heading underline
      return '$text\u200B';
    }
  }
  // Check if it's ONLY equals (1 or 2)
  if (_equalsOnlyPattern.hasMatch(trimmedLastLine) &&
      !_equalsWithSpacePattern.hasMatch(lastLine)) {
    // Check if there's content on the previous line
    final lines = previousContent.split('\n');
    final previousLine = lines.last;
    if (previousLine.trim().isNotEmpty) {
      // Add text to break the setext heading pattern
      // We add a zero-width space (\u200B) which breaks the pattern without being visible
      return '$text\u200B';
    }
  }
  return text;
}
