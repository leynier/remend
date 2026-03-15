import 'comparison_operator_handler.dart';
import 'emphasis_handlers.dart';
import 'html_tag_handler.dart';
import 'inline_code_handler.dart';
import 'katex_handler.dart';
import 'link_image_handler.dart';
import 'link_mode.dart';
import 'remend_handler.dart';
import 'remend_options.dart';
import 'setext_heading_handler.dart';
import 'single_tilde_handler.dart';
import 'strikethrough_handler.dart';

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
final _builtInHandlers = <({
  RemendHandler handler,
  String optionKey,
  bool Function(String result)? earlyReturn,
})>[
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
    earlyReturn: (result) => result.endsWith('](streamdown:incomplete-link)'),
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
    'bold' => options.bold,
    'boldItalic' => options.boldItalic,
    'italic' => options.italic,
    'inlineCode' => options.inlineCode,
    'strikethrough' => options.strikethrough,
    'katex' => options.katex,
    'inlineKatex' => options.inlineKatex,
    'images' => options.images,
    'links' => options.links,
    'setextHeadings' => options.setextHeadings,
    'singleTilde' => options.singleTilde,
    'comparisonOperators' => options.comparisonOperators,
    'htmlTags' => options.htmlTags,
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
          return options.links || options.images;
        }
        // Special case: inlineKatex is opt-in (defaults to false, unlike other options)
        if (entry.handler.name == 'inlineKatex') {
          return options.inlineKatex;
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
            earlyReturn:
                linkMode == LinkMode.protocol ? entry.earlyReturn : null,
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
  var result =
      text.endsWith(' ') && !text.endsWith('  ')
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
  // Priority is always set: built-ins have explicit priority, customs get default
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
