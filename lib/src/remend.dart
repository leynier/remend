import 'comparison_operator_handler.dart';
import 'emphasis_handlers.dart';
import 'html_tag_handler.dart';
import 'inline_code_handler.dart';
import 'katex_handler.dart';
import 'link_image_handler.dart';
import 'setext_heading_handler.dart';
import 'single_tilde_handler.dart';
import 'strikethrough_handler.dart';

/// Handler function that transforms text during streaming.
class RemendHandler {
  /// Handler function: takes text, returns modified text
  final String Function(String text) handle;

  /// Unique identifier for this handler
  final String name;

  /// Priority (lower runs first). Built-in priorities: 0-100. Default: 100
  final int priority;

  /// Creates a [RemendHandler].
  const RemendHandler({
    required this.name,
    required this.handle,
    this.priority = 100,
  });
}

/// Configuration options for the remend function.
/// Options default to `true` unless noted otherwise.
/// Set an option to `false` to disable that specific completion.
class RemendOptions {
  /// Complete bold formatting (e.g., `**text` → `**text**`)
  final bool bold;

  /// Complete bold-italic formatting (e.g., `***text` → `***text***`)
  final bool boldItalic;

  /// Escape > as comparison operators in list items (e.g., `- > 25` → `- \> 25`)
  final bool comparisonOperators;

  /// Custom handlers to extend remend
  final List<RemendHandler> handlers;

  /// Strip incomplete HTML tags at end of streaming text (e.g., `text <custom` → `text`)
  final bool htmlTags;

  /// Complete images (e.g., `![alt](url` → removed)
  final bool images;

  /// Complete inline code formatting (e.g., `` `code `` → `` `code` ``)
  final bool inlineCode;

  /// Complete inline KaTeX math (e.g., `$equation` → `$equation$`).
  /// Defaults to `false` — single `$` is ambiguous with currency symbols.
  final bool inlineKatex;

  /// Complete italic formatting (e.g., `*text` → `*text*` or `_text` → `_text_`)
  final bool italic;

  /// Complete block KaTeX math (e.g., `$$equation` → `$$equation$$`)
  final bool katex;

  /// How to handle incomplete links:
  /// - [LinkMode.protocol]: Use `streamdown:incomplete-link` placeholder URL (default)
  /// - [LinkMode.textOnly]: Display only the link text without any link markup
  final LinkMode linkMode;

  /// Complete links and images (e.g., `[text](url` → `[text](streamdown:incomplete-link)`)
  final bool links;

  /// Handle incomplete setext headings to prevent misinterpretation
  final bool setextHeadings;

  /// Escape single ~ between word characters to prevent false strikethrough (e.g., `20~25` → `20\~25`)
  final bool singleTilde;

  /// Complete strikethrough formatting (e.g., `~~text` → `~~text~~`)
  final bool strikethrough;

  /// Creates [RemendOptions] with the given configuration.
  const RemendOptions({
    this.bold = true,
    this.boldItalic = true,
    this.comparisonOperators = true,
    this.handlers = const [],
    this.htmlTags = true,
    this.images = true,
    this.inlineCode = true,
    this.inlineKatex = false,
    this.italic = true,
    this.katex = true,
    this.linkMode = LinkMode.protocol,
    this.links = true,
    this.setextHeadings = true,
    this.singleTilde = true,
    this.strikethrough = true,
  });
}

// Helper to check if an option is enabled (defaults to true)
bool _isEnabled(bool option) => option;

// Helper to check if an opt-in option is enabled (defaults to false)
bool _isOptedIn(bool option) => option;

// Built-in handler priorities (0-100)
const _priority = (
  singleTilde: 0,
  comparisonOperators: 5,
  htmlTags: 10,
  setextHeadings: 15,
  links: 20,
  boldItalic: 30,
  bold: 35,
  italicDoubleUnderscore: 40,
  italicSingleAsterisk: 41,
  italicSingleUnderscore: 42,
  inlineCode: 50,
  strikethrough: 60,
  katex: 70,
  inlineKatex: 75,
  defaultPriority: 100,
);

// Internal entry pairing a handler with an optional early-return predicate
class _HandlerEntry {
  final RemendHandler handler;
  final bool Function(String result)? earlyReturn;
  const _HandlerEntry({required this.handler, this.earlyReturn});
}

// Built-in handlers with their option keys and priorities
final _builtInHandlers =
    <
      ({
        RemendHandler handler,
        String optionKey,
        bool Function(String result)? earlyReturn,
      })
    >[
      (
        handler: RemendHandler(
          name: 'singleTilde',
          handle: handleSingleTildeEscape,
          priority: _priority.singleTilde,
        ),
        optionKey: 'singleTilde',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'comparisonOperators',
          handle: handleComparisonOperators,
          priority: _priority.comparisonOperators,
        ),
        optionKey: 'comparisonOperators',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'htmlTags',
          handle: handleIncompleteHtmlTag,
          priority: _priority.htmlTags,
        ),
        optionKey: 'htmlTags',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'setextHeadings',
          handle: handleIncompleteSetextHeading,
          priority: _priority.setextHeadings,
        ),
        optionKey: 'setextHeadings',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'links',
          handle: handleIncompleteLinksAndImages,
          priority: _priority.links,
        ),
        optionKey: 'links',
        earlyReturn: (result) =>
            result.endsWith('](streamdown:incomplete-link)'),
      ),
      (
        handler: RemendHandler(
          name: 'boldItalic',
          handle: handleIncompleteBoldItalic,
          priority: _priority.boldItalic,
        ),
        optionKey: 'boldItalic',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'bold',
          handle: handleIncompleteBold,
          priority: _priority.bold,
        ),
        optionKey: 'bold',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'italicDoubleUnderscore',
          handle: handleIncompleteDoubleUnderscoreItalic,
          priority: _priority.italicDoubleUnderscore,
        ),
        optionKey: 'italic',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'italicSingleAsterisk',
          handle: handleIncompleteSingleAsteriskItalic,
          priority: _priority.italicSingleAsterisk,
        ),
        optionKey: 'italic',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'italicSingleUnderscore',
          handle: handleIncompleteSingleUnderscoreItalic,
          priority: _priority.italicSingleUnderscore,
        ),
        optionKey: 'italic',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'inlineCode',
          handle: handleIncompleteInlineCode,
          priority: _priority.inlineCode,
        ),
        optionKey: 'inlineCode',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'strikethrough',
          handle: handleIncompleteStrikethrough,
          priority: _priority.strikethrough,
        ),
        optionKey: 'strikethrough',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'katex',
          handle: handleIncompleteBlockKatex,
          priority: _priority.katex,
        ),
        optionKey: 'katex',
        earlyReturn: null,
      ),
      (
        handler: RemendHandler(
          name: 'inlineKatex',
          handle: handleIncompleteInlineKatex,
          priority: _priority.inlineKatex,
        ),
        optionKey: 'inlineKatex',
        earlyReturn: null,
      ),
    ];

// Helper to check if an option is enabled by its key name
bool _isOptionEnabled(RemendOptions options, String optionKey) {
  return switch (optionKey) {
    'bold' => _isEnabled(options.bold),
    'boldItalic' => _isEnabled(options.boldItalic),
    'italic' => _isEnabled(options.italic),
    'inlineCode' => _isEnabled(options.inlineCode),
    'strikethrough' => _isEnabled(options.strikethrough),
    'katex' => _isEnabled(options.katex),
    'inlineKatex' => _isOptedIn(options.inlineKatex),
    'images' => _isEnabled(options.images),
    'links' => _isEnabled(options.links),
    'setextHeadings' => _isEnabled(options.setextHeadings),
    'singleTilde' => _isEnabled(options.singleTilde),
    'comparisonOperators' => _isEnabled(options.comparisonOperators),
    'htmlTags' => _isEnabled(options.htmlTags),
    _ => true,
  };
}

// Also enable links handler when images option is enabled
List<_HandlerEntry> _getEnabledBuiltInHandlers(RemendOptions options) {
  final linkMode = options.linkMode;
  return _builtInHandlers
      .where((entry) {
        // Special case: links handler is enabled by either links or images option
        if (entry.handler.name == 'links') {
          return _isEnabled(options.links) || _isEnabled(options.images);
        }
        // Special case: inlineKatex is opt-in (defaults to false, unlike other options)
        if (entry.handler.name == 'inlineKatex') {
          return _isOptedIn(options.inlineKatex);
        }
        return _isOptionEnabled(options, entry.optionKey);
      })
      .map((entry) {
        // Special case: wrap links handler to pass linkMode option
        if (entry.handler.name == 'links') {
          return _HandlerEntry(
            handler: RemendHandler(
              name: entry.handler.name,
              handle: (text) => handleIncompleteLinksAndImages(text, linkMode),
              priority: entry.handler.priority,
            ),
            // Only use early return for protocol mode (text-only won't end with the marker)
            earlyReturn: linkMode == LinkMode.protocol
                ? entry.earlyReturn
                : null,
          );
        }
        return _HandlerEntry(
          handler: entry.handler,
          earlyReturn: entry.earlyReturn,
        );
      })
      .toList();
}

// Parses markdown text and removes incomplete tokens to prevent partial rendering
String remend(String text, [RemendOptions options = const RemendOptions()]) {
  // Remove trailing whitespace if it's not a double space
  var result = text.endsWith(' ') && !text.endsWith('  ')
      ? text.substring(0, text.length - 1)
      : text;
  // Get enabled built-in handlers
  final enabledBuiltIns = _getEnabledBuiltInHandlers(options);
  // Combine with custom handlers (default priority: 100)
  final customHandlers = options.handlers.map(
    (h) => _HandlerEntry(
      handler: RemendHandler(
        name: h.name,
        handle: h.handle,
        priority: h.priority,
      ),
      earlyReturn: null,
    ),
  );
  // Merge and sort by priority
  // Priority is always set: built-ins have explicit priority, customs get default at line 252
  final allHandlers = [...enabledBuiltIns, ...customHandlers]
    ..sort((a, b) => a.handler.priority.compareTo(b.handler.priority));
  // Execute handlers in priority order
  for (final entry in allHandlers) {
    result = entry.handler.handle(result);
    // Check for early return condition (e.g., incomplete link marker)
    if (entry.earlyReturn != null && entry.earlyReturn!(result)) {
      return result;
    }
  }
  return result;
}
