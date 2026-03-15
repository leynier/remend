import 'code_block_utils.dart';

// Escapes single ~ characters that appear between word characters
// to prevent remarkGfm (with singleTilde: true) from misinterpreting
// them as strikethrough markers.
// e.g. "20~25°C" → "20\~25°C" (not strikethrough)
// Does NOT escape ~~ (double tilde, valid strikethrough syntax).

// Match a single ~ that is:
// - preceded by a word character (letter, number, or underscore)
// - NOT preceded by another ~ (to avoid matching ~~)
// - NOT followed by another ~ (to avoid matching ~~)
// - followed by a word character
// Uses Unicode-aware \p{L} and \p{N} for CJK and other scripts
final _singleTildePattern =
    RegExp(r'(?<=[\p{L}\p{N}_])~(?!~)(?=[\p{L}\p{N}_])', unicode: true);

String handleSingleTildeEscape(String text) {
  // Quick check: if there's no ~ in the text, skip processing
  if (!text.contains('~')) {
    return text;
  }
  return text.replaceAllMapped(_singleTildePattern, (match) {
    // Don't escape inside code blocks
    if (isInsideCodeBlock(text, match.start)) {
      return match[0]!;
    }
    return r'\~';
  });
}
