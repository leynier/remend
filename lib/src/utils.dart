/// Returns `true` if [char] is a word character (letter, digit, or
/// underscore).
///
/// Uses an ASCII fast-path before falling back to Unicode matching.
bool isWordChar(String char) {
  throw UnimplementedError();
}

/// Returns `true` if [position] is inside a fenced code block
/// (triple backticks).
bool isWithinCodeBlock(String text, int position) {
  throw UnimplementedError();
}

/// Returns `true` if [position] is inside a math block (`$` or `$$`
/// markers).
bool isWithinMathBlock(String text, int position) {
  throw UnimplementedError();
}

/// Returns `true` if [position] is inside a link or image URL (between
/// `](` and `)`).
bool isWithinLinkOrImageUrl(String text, int position) {
  throw UnimplementedError();
}
