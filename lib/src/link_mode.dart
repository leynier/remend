/// Determines how incomplete links are handled.
enum LinkMode {
  /// Replace incomplete URL with `streamdown:incomplete-link` placeholder.
  protocol,

  /// Remove link markup and show only the link text.
  textOnly,
}
