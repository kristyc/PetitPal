class MarkdownUtils {
  /// Convert Markdown-ish text to readable plain text.
  static String strip(String input) {
    var s = input;

    // Remove fenced code blocks entirely.
    s = s.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '');
    // Inline code -> content only.
    s = s.replaceAll(RegExp(r'`([^`]*)`'), r'\1');
    // Headings and blockquotes -> text only.
    s = s.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');
    // Bullet lists: turn leading -,*,+ into "• "
    s = s.replaceAllMapped(RegExp(r'^\s{0,3}[-*+]\s+', multiLine: true),
        (m) => '• ');
    // Keep numeric lists (do NOT strip "1. " etc.)

    // Bold/italic/strike -> keep text
    s = s.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1');
    s = s.replaceAll(RegExp(r'__([^_]+)__'), r'\1');
    s = s.replaceAll(RegExp(r'\*([^*]+)\*'), r'\1');
    s = s.replaceAll(RegExp(r'_([^_]+)_'), r'\1');
    s = s.replaceAll(RegExp(r'~~([^~]+)~~'), r'\1');

    // Images/links: [text](url) -> text
    s = s.replaceAll(RegExp(r'!\[([^\]]*)\]\([^\)]*\)'), r'\1');
    s = s.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]*\)'), r'\1');

    // Horizontal rules
    s = s.replaceAll(RegExp(r'^\s*([-*_]\s?){3,}\s*$', multiLine: true), '');

    // Normalize excessive newlines
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  /// Strip + unescape backslashes and normalize whitespace.
  static String clean(String input) {
    var s = strip(input);

    // Unescape backslash-escaped punctuation/symbols (single or double slashes).
    s = s.replaceAllMapped(RegExp(r'\\([`*_{}\[\]()#+.!>~-])'), (m) => m.group(1)!);
    s = s.replaceAllMapped(RegExp(r'\\\\([`*_{}\[\]()#+.!>~-])'), (m) => m.group(1)!);

    // Fix patterns like \1: or \1. and \\1: / \\1.
    s = s.replaceAllMapped(RegExp(r'\\(\d+)([.:])'), (m) => '${m.group(1)}${m.group(2)}');
    s = s.replaceAllMapped(RegExp(r'\\\\(\d+)([.:])'), (m) => '${m.group(1)}${m.group(2)}');

    // Trim extra spaces around newlines
    s = s.replaceAll(RegExp(r'\s*\n\s*'), '\n');
    // Collapse runs of spaces
    s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');

    return s.trim();
  }
}
