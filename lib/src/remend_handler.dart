/// A custom handler to extend remend with domain-specific syntax completion.
///
/// Handlers are executed in [priority] order (lower values run first).
/// Built-in handlers use priorities 0–75; custom handlers default to 100.
///
/// ```dart
/// final handler = RemendHandler(
///   name: 'joke',
///   priority: 80,
///   handle: (text) {
///     final match = RegExp(r'<<<JOKE>>>([^<]*)$').firstMatch(text);
///     if (match != null && !text.endsWith('<<</JOKE>>>')) {
///       return '$text<<</JOKE>>>';
///     }
///     return text;
///   },
/// );
/// ```
class RemendHandler {
  /// Unique identifier for this handler.
  final String name;

  /// Transform function that receives the current text and returns
  /// the modified text.
  final String Function(String text) handle;

  /// Execution priority. Lower values run first. Defaults to 100.
  final int priority;

  /// Creates a [RemendHandler].
  const RemendHandler({
    required this.name,
    required this.handle,
    this.priority = 100,
  });
}
