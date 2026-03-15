## 1.2.2

Initial Dart port of the [`remend`](https://www.npmjs.com/package/remend) npm package (v1.2.2).

This release establishes 1:1 parity with the TypeScript original: same handler pipeline,
same logic, same behavior — adapted to Dart conventions.

- Full implementation of all built-in handlers: bold, italic, bold-italic, inline code,
  strikethrough, links, images, block KaTeX, inline KaTeX, single tilde escape,
  comparison operators, HTML tags, and setext headings
- `RemendOptions` to selectively enable/disable handlers
- `RemendHandler` for custom handlers with priority-based execution
- `LinkMode` enum (`protocol` / `textOnly`) for incomplete link handling
- Exported context utilities: `isWithinCodeBlock`, `isWithinMathBlock`,
  `isWithinLinkOrImageUrl`, `isWordChar`
