import 'link_mode.dart';
import 'remend_handler.dart';

/// Configuration options for [remend].
///
/// All boolean options default to `true` except [inlineKatex], which
/// defaults to `false` to avoid ambiguity with currency symbols.
///
/// ```dart
/// final options = RemendOptions(
///   katex: false,
///   inlineKatex: true,
///   linkMode: LinkMode.textOnly,
/// );
/// ```
class RemendOptions {
  /// Complete `**` bold markers. Defaults to `true`.
  final bool bold;

  /// Complete `***` bold-italic markers. Defaults to `true`.
  final bool boldItalic;

  /// Complete `*` and `_` italic markers. Defaults to `true`.
  final bool italic;

  /// Complete `` ` `` inline code markers. Defaults to `true`.
  final bool inlineCode;

  /// Complete `~~` strikethrough markers. Defaults to `true`.
  final bool strikethrough;

  /// Complete `$$` block math markers. Defaults to `true`.
  final bool katex;

  /// Complete `$` inline math markers. Defaults to `false`.
  final bool inlineKatex;

  /// Remove incomplete image markup. Defaults to `true`.
  final bool images;

  /// Complete incomplete link markup. Defaults to `true`.
  final bool links;

  /// Handle incomplete setext heading underlines. Defaults to `true`.
  final bool setextHeadings;

  /// Escape single `~` between word characters. Defaults to `true`.
  final bool singleTilde;

  /// Escape `>` in list item comparison operators. Defaults to `true`.
  final bool comparisonOperators;

  /// Strip incomplete HTML tags. Defaults to `true`.
  final bool htmlTags;

  /// How to handle incomplete links. Defaults to [LinkMode.protocol].
  final LinkMode linkMode;

  /// Custom handlers to extend remend.
  final List<RemendHandler> handlers;

  /// Creates [RemendOptions] with the given configuration.
  const RemendOptions({
    this.bold = true,
    this.boldItalic = true,
    this.italic = true,
    this.inlineCode = true,
    this.strikethrough = true,
    this.katex = true,
    this.inlineKatex = false,
    this.images = true,
    this.links = true,
    this.setextHeadings = true,
    this.singleTilde = true,
    this.comparisonOperators = true,
    this.htmlTags = true,
    this.linkMode = LinkMode.protocol,
    this.handlers = const [],
  });
}
