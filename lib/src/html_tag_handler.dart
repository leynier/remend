import 'code_block_utils.dart';

// Matches an incomplete HTML tag at the end of the string.
// Must start with < followed by a letter (opening tag) or / (closing tag),
// and must NOT contain a > (which would close the tag).
final _incompleteHtmlTagPattern = RegExp(r'<[a-zA-Z/][^>]*$');

String handleIncompleteHtmlTag(String text) {
  final match = _incompleteHtmlTagPattern.firstMatch(text);
  if (match == null) {
    return text;
  }
  // Don't strip if the < is inside a code block or inline code
  if (isInsideCodeBlock(text, match.start)) {
    return text;
  }
  // Strip the incomplete tag and any trailing whitespace before it
  return text.substring(0, match.start).trimRight();
}
