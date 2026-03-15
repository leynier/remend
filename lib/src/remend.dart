import 'remend_options.dart';

/// Processes [text] and auto-completes incomplete Markdown formatting.
///
/// Analyzes the input for unclosed formatting markers and intelligently
/// adds closing markers so that partial Markdown (e.g. from a streaming
/// LLM response) renders correctly.
///
/// ```dart
/// remend('This is **bold text');
/// // => 'This is **bold text**'
///
/// remend('Check `code');
/// // => 'Check `code`'
///
/// remend('Formula: \$\$x^2');
/// // => 'Formula: \$\$x^2\$\$'
/// ```
String remend(String text, [RemendOptions options = const RemendOptions()]) {
  throw UnimplementedError();
}
