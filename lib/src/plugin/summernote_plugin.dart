/// Plugin that wraps native Summernote plugins for use in mb_rich_editor.
///
/// Supports loading plugins from:
/// - CDN URLs (via `SummernotePlugin.fromUrl`)
/// - Flutter asset bundles (via `SummernotePlugin.fromAsset`)
/// - Raw JavaScript strings (via `SummernotePlugin.fromCode`)
///
/// Example usage:
/// ```dart
/// // Load from CDN
/// SummernotePlugin.fromUrl(
///   'helloPlugin',
///   'https://cdn.jsdelivr.net/npm/hello-plugin/plugin.min.js',
///   options: {'tooltip': 'Hello'},
/// )
///
/// // Load from asset
/// SummernotePlugin.fromAsset(
///   'customPlugin',
///   'assets/summernote_plugins/custom/plugin.js',
/// )
///
/// // Load from raw JavaScript
/// SummernotePlugin.fromCode(
///   'inlinePlugin',
///   '''
///     (function(factory) { factory(jQuery); }(function($) {
///       $.extend($.summernote.plugins, {
///         'inlinePlugin': function(context) { ... }
///       });
///     }));
///   ''',
/// )
/// ```
class SummernotePlugin {
  /// Name of the Summernote plugin (must match `$.summernote.plugins` key)
  final String pluginName;

  /// CDN URL to load the plugin script from
  final String? scriptUrl;

  /// Flutter asset path to load the plugin script from
  final String? assetPath;

  /// Raw JavaScript code to inject directly
  final String? rawJavaScript;

  /// Plugin options to pass to Summernote (via `$.summernote.options`)
  final Map<String, dynamic> options;

  /// Language strings for the plugin (via `$.summernote.lang`)
  ///
  /// Example:
  /// ```dart
  /// language: {
  ///   'en-US': {
  ///     'myPlugin': {
  ///       'tooltip': 'My Plugin',
  ///       'okButton': 'OK',
  ///     },
  ///   },
  /// }
  /// ```
  final Map<String, Map<String, String>>? language;

  /// Callback handlers for plugin-specific events (bridged to Dart)
  ///
  /// The plugin JavaScript can call these callbacks using:
  /// ```javascript
  /// window.flutter_inappwebview.callHandler('plugin_<pluginName>_<callbackName>', data);
  /// ```
  ///
  /// Example:
  /// ```dart
  /// callbacks: {
  ///   'onAction': (data) => print('Action: $data'),
  ///   'onData': (data) => processData(data),
  /// }
  /// ```
  final Map<String, Function(dynamic)>? callbacks;

  /// Creates a new Summernote plugin.
  ///
  /// Exactly one of [scriptUrl], [assetPath], or [rawJavaScript] must be provided.
  const SummernotePlugin({
    required this.pluginName,
    this.scriptUrl,
    this.assetPath,
    this.rawJavaScript,
    this.options = const {},
    this.language,
    this.callbacks,
  }) : assert(
         (scriptUrl != null && assetPath == null && rawJavaScript == null) ||
             (scriptUrl == null &&
                 assetPath != null &&
                 rawJavaScript == null) ||
             (scriptUrl == null && assetPath == null && rawJavaScript != null),
         'Exactly one of scriptUrl, assetPath, or rawJavaScript must be provided',
       );

  /// Creates a Summernote plugin that loads from a CDN URL.
  ///
  /// Example:
  /// ```dart
  /// SummernotePlugin.fromUrl(
  ///   'emoji',
  ///   'https://cdn.jsdelivr.net/npm/summernote-emoji/dist/summernote-emoji.min.js',
  ///   options: {'emojiPath': '/assets/emoji/'},
  ///   callbacks: {'onEmojiSelect': (emoji) => print('Emoji: $emoji')},
  /// )
  /// ```
  const factory SummernotePlugin.fromUrl(
    String pluginName,
    String scriptUrl, {
    Map<String, dynamic> options,
    Map<String, Map<String, String>>? language,
    Map<String, Function(dynamic)>? callbacks,
  }) = _SummernotePluginFromUrl;

  /// Creates a Summernote plugin that loads from a Flutter asset.
  ///
  /// Example:
  /// ```dart
  /// SummernotePlugin.fromAsset(
  ///   'mention',
  ///   'assets/summernote_plugins/mention/summernote-mention.js',
  ///   options: {'trigger': '@'},
  ///   callbacks: {'onSearch': (query) => searchUsers(query)},
  /// )
  /// ```
  const factory SummernotePlugin.fromAsset(
    String pluginName,
    String assetPath, {
    Map<String, dynamic> options,
    Map<String, Map<String, String>>? language,
    Map<String, Function(dynamic)>? callbacks,
  }) = _SummernotePluginFromAsset;

  /// Creates a Summernote plugin from raw JavaScript code.
  ///
  /// This is useful for inline plugins or for loading plugins from strings
  /// (e.g., loaded from a database or API).
  ///
  /// Example:
  /// ```dart
  /// SummernotePlugin.fromCode(
  ///   'helloPlugin',
  ///   '''
  ///     (function(factory) { factory(jQuery); }((function(\$) {
  ///       \$.extend(true, \$.summernote.lang, {
  ///         'en-US': { helloPlugin: { tooltip: 'Say Hello' } }
  ///       });
  ///       \$.extend(\$.summernote.options, {
  ///         helloPlugin: { icon: '<i class="note-icon-star"/>' }
  ///       });
  ///       \$.extend(\$.summernote.plugins, {
  ///         'helloPlugin': function(context) {
  ///           var ui = \$.summernote.ui;
  ///           context.memo('button.helloPlugin', function() {
  ///             return ui.button({
  ///               contents: \$.summernote.options.helloPlugin.icon,
  ///               tooltip: \$.summernote.lang.en_US.helloPlugin.tooltip,
  ///               click: function() {
  ///                 context.invoke('editor.insertText', 'Hello World!');
  ///               }
  ///             }).render();
  ///           });
  ///         }
  ///       });
  ///     }));
  ///   ''',
  /// )
  /// ```
  const factory SummernotePlugin.fromCode(
    String pluginName,
    String rawJavaScript, {
    Map<String, dynamic> options,
    Map<String, Map<String, String>>? language,
    Map<String, Function(dynamic)>? callbacks,
  }) = _SummernotePluginFromCode;
}

/// Internal implementation for URL-based plugins
class _SummernotePluginFromUrl extends SummernotePlugin {
  const _SummernotePluginFromUrl(
    String pluginName,
    String scriptUrl, {
    super.options = const {},
    super.language,
    super.callbacks,
  }) : super(pluginName: pluginName, scriptUrl: scriptUrl);
}

/// Internal implementation for asset-based plugins
class _SummernotePluginFromAsset extends SummernotePlugin {
  const _SummernotePluginFromAsset(
    String pluginName,
    String assetPath, {
    super.options = const {},
    super.language,
    super.callbacks,
  }) : super(pluginName: pluginName, assetPath: assetPath);
}

/// Internal implementation for code-based plugins
class _SummernotePluginFromCode extends SummernotePlugin {
  const _SummernotePluginFromCode(
    String pluginName,
    String rawJavaScript, {
    super.options = const {},
    super.language,
    super.callbacks,
  }) : super(pluginName: pluginName, rawJavaScript: rawJavaScript);
}
