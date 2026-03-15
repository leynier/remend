import 'code_block_utils.dart';
import 'utils.dart';

/// Determines how incomplete links are handled.
enum LinkMode {
  /// Replace incomplete URL with `streamdown:incomplete-link` placeholder.
  protocol,

  /// Remove link markup and show only the link text.
  textOnly,
}

// Helper function to handle incomplete URLs in links/images
String? _handleIncompleteUrl(
  String text,
  int lastParenIndex,
  LinkMode linkMode,
) {
  final afterParen = text.substring(lastParenIndex + 2);
  if (afterParen.contains(')')) {
    return null;
  }
  // We have an incomplete URL like [text](partial-url
  // Now find the matching opening bracket for the ] before (
  final openBracketIndex = findMatchingOpeningBracket(text, lastParenIndex);
  if (openBracketIndex == -1 || isInsideCodeBlock(text, openBracketIndex)) {
    return null;
  }
  // Check if there's a ! before the [
  final isImage = openBracketIndex > 0 && text[openBracketIndex - 1] == '!';
  final startIndex = isImage ? openBracketIndex - 1 : openBracketIndex;
  // Extract everything before this link/image
  final beforeLink = text.substring(0, startIndex);
  if (isImage) {
    // For images with incomplete URLs, remove them entirely
    return beforeLink;
  }
  // For links with incomplete URLs, handle based on linkMode
  final linkText = text.substring(openBracketIndex + 1, lastParenIndex);
  if (linkMode == LinkMode.textOnly) {
    return '$beforeLink$linkText';
  }
  return '$beforeLink[$linkText](streamdown:incomplete-link)';
}

// Helper to find the first incomplete [ (for text-only mode)
// Always returns a valid index since callers guarantee text[maxPos] is an incomplete [
int _findFirstIncompleteBracket(String text, int maxPos) {
  for (var j = 0; j < maxPos; j += 1) {
    if (text[j] == '[' && !isInsideCodeBlock(text, j)) {
      // Skip if it's an image
      if (j > 0 && text[j - 1] == '!') {
        continue;
      }
      // Check if this [ has a matching ]
      final closingIdx = findMatchingClosingBracket(text, j);
      if (closingIdx == -1) {
        // This is an incomplete [
        return j;
      }
      // This [ is complete, check if it's a full link [text](url)
      if (closingIdx + 1 < text.length && text[closingIdx + 1] == '(') {
        final urlEnd = text.indexOf(')', closingIdx + 2);
        if (urlEnd != -1) {
          // Skip past this complete link
          j = urlEnd;
        }
      }
    }
  }
  // Fallback: the bracket at maxPos is always incomplete by contract
  return maxPos;
}

// Helper function to handle incomplete link text (unclosed brackets)
String? _handleIncompleteText(String text, int i, LinkMode linkMode) {
  // Check if there's a ! before it
  final isImage = i > 0 && text[i - 1] == '!';
  final openIndex = isImage ? i - 1 : i;
  // Check if we have a closing bracket after this
  final afterOpen = text.substring(i + 1);
  if (!afterOpen.contains(']')) {
    // This is an incomplete link/image
    final beforeLink = text.substring(0, openIndex);
    if (isImage) {
      // For images, we remove them as they can't show skeleton
      return beforeLink;
    }
    // For links, handle based on linkMode
    if (linkMode == LinkMode.textOnly) {
      // Find the first incomplete [ and strip just that bracket
      final firstIncomplete = _findFirstIncompleteBracket(text, i);
      return text.substring(0, firstIncomplete) +
          text.substring(firstIncomplete + 1);
    }
    // Preserve the text and close the link with a placeholder URL
    return '$text](streamdown:incomplete-link)';
  }
  // If we found a closing bracket, we need to check if it's the matching one
  // (accounting for nested brackets)
  final closingIndex = findMatchingClosingBracket(text, i);
  if (closingIndex == -1) {
    // No matching closing bracket
    final beforeLink = text.substring(0, openIndex);
    if (isImage) {
      return beforeLink;
    }
    if (linkMode == LinkMode.textOnly) {
      // Find the first incomplete [ and strip just that bracket
      final firstIncomplete = _findFirstIncompleteBracket(text, i);
      return text.substring(0, firstIncomplete) +
          text.substring(firstIncomplete + 1);
    }
    return '$text](streamdown:incomplete-link)';
  }
  return null;
}

// Handles incomplete links and images by preserving them with a special marker
String handleIncompleteLinksAndImages(
  String text, [
  LinkMode linkMode = LinkMode.protocol,
]) {
  // Look for patterns like [text]( or ![text]( at the end of text
  // We need to handle nested brackets in the link text
  // Start from the end and look for ]( pattern
  final lastParenIndex = text.lastIndexOf('](');
  if (lastParenIndex != -1 && !isInsideCodeBlock(text, lastParenIndex)) {
    final result = _handleIncompleteUrl(text, lastParenIndex, linkMode);
    if (result != null) {
      return result;
    }
  }
  // Then check for incomplete link text: [partial-text without closing ]
  // Search backwards for an opening bracket that doesn't have a matching closing bracket
  for (var i = text.length - 1; i >= 0; i -= 1) {
    if (text[i] == '[' && !isInsideCodeBlock(text, i)) {
      final result = _handleIncompleteText(text, i, linkMode);
      if (result != null) {
        return result;
      }
    }
  }
  return text;
}
