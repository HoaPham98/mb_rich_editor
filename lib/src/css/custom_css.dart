library;

/// Custom CSS injection model for the Summernote editor.
///
/// CSS can be loaded from:
/// - Raw CSS strings (via `CustomCSS.fromString`)
/// - Flutter asset bundles (via `CustomCSS.fromAsset`)
/// - External URLs (via `CustomCSS.fromUrl`)
///
/// Example usage:
/// ```dart
/// // Load from string
/// CustomCSS.fromString(
///   'customTheme',
///   '.note-editable { font-family: "Georgia", serif; }',
/// )
///
/// // Load from asset
/// CustomCSS.fromAsset(
///   'darkMode',
///   'assets/css/dark_mode.css',
///   scope: CSSScope.global,
/// )
///
/// // Load from URL
/// CustomCSS.fromUrl(
///   'fontAwesome',
///   'https://cdnjs.cloudflare.com/ajax/font-awesome/6.0.0/css/all.min.css',
///   scope: CSSScope.global,
/// )
/// ```

/// Scope for CSS application
enum CSSScope {
  /// Apply CSS to the entire document (injected into `<head>`)
  global,

  /// Apply CSS only to the editor area (scoped to `.note-editor`)
  editor,
}

/// Model for custom CSS to be injected into the Summernote editor.
class CustomCSS {
  /// Unique identifier for this CSS
  final String cssName;

  /// Raw CSS content to inject
  final String? cssContent;

  /// Flutter asset path to load CSS from
  final String? assetPath;

  /// External URL to load CSS from
  final String? cssUrl;

  /// Scope where the CSS should be applied
  final CSSScope scope;

  /// Priority for ordering (higher = applied later, default: 100)
  final int priority;

  const CustomCSS({
    required this.cssName,
    this.cssContent,
    this.assetPath,
    this.cssUrl,
    this.scope = CSSScope.editor,
    this.priority = 100,
  }) : assert(
         (cssContent != null && assetPath == null && cssUrl == null) ||
             (cssContent == null && assetPath != null && cssUrl == null) ||
             (cssContent == null && assetPath == null && cssUrl != null),
         'Exactly one of cssContent, assetPath, or cssUrl must be provided',
       );

  /// Creates a CustomCSS from a raw CSS string.
  ///
  /// Example:
  /// ```dart
  /// CustomCSS.fromString(
  ///   'customTheme',
  ///   '''
  ///     .note-editable {
  ///       font-family: 'Georgia', serif;
  ///       line-height: 1.8;
  ///     }
  ///     blockquote {
  ///       border-left-color: #007bff;
  ///     }
  ///   ''',
  /// )
  /// ```
  const factory CustomCSS.fromString(
    String cssName,
    String cssContent, {
    CSSScope scope,
    int priority,
  }) = _CustomCSSFromString;

  /// Creates a CustomCSS from a Flutter asset.
  ///
  /// Example:
  /// ```dart
  /// CustomCSS.fromAsset(
  ///   'darkMode',
  ///   'assets/css/editor_dark_mode.css',
  ///   scope: CSSScope.global,
  /// )
  /// ```
  const factory CustomCSS.fromAsset(
    String cssName,
    String assetPath, {
    CSSScope scope,
    int priority,
  }) = _CustomCSSFromAsset;

  /// Creates a CustomCSS from an external URL.
  ///
  /// Example:
  /// ```dart
  /// CustomCSS.fromUrl(
  ///   'fontAwesome',
  ///   'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css',
  ///   scope: CSSScope.global,
  /// )
  /// ```
  const factory CustomCSS.fromUrl(
    String cssName,
    String cssUrl, {
    CSSScope scope,
    int priority,
  }) = _CustomCSSFromUrl;
}

// Internal implementations

class _CustomCSSFromString extends CustomCSS {
  const _CustomCSSFromString(
    String cssName,
    String cssContent, {
    CSSScope scope = CSSScope.editor,
    int priority = 100,
  }) : super(
          cssName: cssName,
          cssContent: cssContent,
          scope: scope,
          priority: priority,
        );
}

class _CustomCSSFromAsset extends CustomCSS {
  const _CustomCSSFromAsset(
    String cssName,
    String assetPath, {
    CSSScope scope = CSSScope.editor,
    int priority = 100,
  }) : super(
          cssName: cssName,
          assetPath: assetPath,
          scope: scope,
          priority: priority,
        );
}

class _CustomCSSFromUrl extends CustomCSS {
  const _CustomCSSFromUrl(
    String cssName,
    String cssUrl, {
    CSSScope scope = CSSScope.editor,
    int priority = 100,
  }) : super(
          cssName: cssName,
          cssUrl: cssUrl,
          scope: scope,
          priority: priority,
        );
}
