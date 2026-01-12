/// Migration examples from the deprecated RichEditorPlugin system
/// to the new SummernotePlugin system.
///
/// This file provides examples for migrating existing plugins to the new
/// native Summernote plugin system.
///
/// **IMPORTANT:** The old `RichEditorPlugin`, `MentionPlugin`, and `EmojiPlugin`
/// classes are deprecated and will be removed in v2.0.0.
///
/// Migration Steps:
/// 1. Replace `RichEditorPlugin` with `SummernotePlugin`
/// 2. Rewrite plugins as Summernote-compatible jQuery plugins
/// 3. Use `$.summernote.plugins` API instead of extending `RE` object
/// 4. Register buttons via `context.memo('button.pluginName')`
/// 5. Bridge callbacks using `window.flutter_inappwebview.callHandler()`
library;

/// Example 1: Migrating MentionPlugin
///
/// **OLD (deprecated):**
/// ```dart
/// RichEditor(
///   controller: controller,
///   plugins: [
///     MentionPlugin(
///       trigger: '@',
///       onMentionTrigger: (query) {
///         // Show mention suggestions for query
///         print('Mention query: $query');
///       },
///       onMentionHide: () {
///         // Hide mention suggestions
///       },
///       onMentionSelected: (mention) {
///         // Handle mention selection
///         print('Mention selected: ${mention.user.username}');
///       },
///     ),
///   ],
/// )
/// ```
///
/// **NEW (recommended):**
/// First, obtain or create a Summernote-compatible mention plugin.
/// You can use an existing plugin like summernote-mention or create your own.
///
/// ```dart
/// RichEditor(
///   controller: controller,
///   plugins: [
///     // Option 1: Load from CDN
///     SummernotePlugin.fromUrl(
///       'mention',
///       'https://cdn.jsdelivr.net/npm/summernote-mention/dist/summernote-mention.min.js',
///       options: {
///         'trigger': '@',
///         'searchUrl': '/api/users/search',
///         'mentionUrl': '/api/users/{id}',
///       },
///       callbacks: {
///         'onSearch': (query) => print('Search: $query'),
///         'onSelect': (user) => print('Selected: $user'),
///       },
///     ),
///
///     // Option 2: Load from Flutter asset
///     // First, place the plugin file in assets/summernote_plugins/mention/
///     SummernotePlugin.fromAsset(
///       'mention',
///       'assets/summernote_plugins/mention/summernote-mention.js',
///       options: {
///         'trigger': '@',
///       },
///       callbacks: {
///         'onSearch': (query) => searchUsers(query),
///         'onSelect': (user) => insertMention(user),
///       },
///     ),
///
///     // Option 3: Inline custom mention plugin
///     SummernotePlugin.fromCode(
///       'mention',
///       '''
///         (function(factory) { factory(jQuery); }((function(\$) {
///           \$.extend(true, \$.summernote.lang, {
///             'en-US': { mention: { tooltip: 'Mention' } }
///           });
///           \$.extend(\$.summernote.options, {
///             mention: { trigger: '@' }
///           });
///           \$.extend(\$.summernote.plugins, {
///             'mention': function(context) {
///               var ui = \$.summernote.ui;
///               context.memo('button.mention', function() {
///                 return ui.button({
///                   contents: '<i class="note-icon-at"/>',
///                   tooltip: 'Mention',
///                   click: function() {
///                     // Trigger mention action
///                     window.flutter_inappwebview.callHandler('plugin_mention_onTrigger');
///                   }
///                 }).render();
///               });
///             }
///           });
///         })));
///       ''',
///       options: {'trigger': '@'},
///       callbacks: {
///         'onTrigger': () => showMentionPanel(),
///       },
///     ),
///   ],
///   customSummernoteOptions: {
///     'toolbar': [
///       ['insert', ['mention']],
///     ],
///   },
/// )
/// ```
///
/// **Creating a Custom Summernote Mention Plugin:**
///
/// If you need to create a custom mention plugin, here's a template:
///
/// ```javascript
/// // assets/summernote_plugins/custom_mention/custom_mention.js
/// (function(factory) {
///   factory(jQuery);
/// }(function($) {
///   // Extend language
///   $.extend(true, $.summernote.lang, {
///     'en-US': {
///       customMention: {
///         tooltip: 'Mention',
///         searchPlaceholder: 'Search users...',
///       }
///     }
///   });
///
///   // Extend options
///   $.extend($.summernote.options, {
///     customMention: {
///       trigger: '@',
///       searchUrl: null,
///       mentionUrl: null,
///     }
///   });
///
///   // Define the plugin
///   $.extend($.summernote.plugins, {
///     'customMention': function(context) {
///       var self = this;
///       var ui = $.summernote.ui;
///       var $editable = context.layoutInfo.editable;
///
///       // Register button
///       context.memo('button.customMention', function() {
///         return ui.button({
///           contents: '<i class="note-icon-at"/>',
///           tooltip: $.summernote.lang.enUS.customMention.tooltip,
///           click: function() {
///             // Insert trigger character
///             context.invoke('editor.insertText', '@');
///           }
///         }).render();
///       });
///
///       // Handle keyup to detect trigger
///       this.events.keyup = function(e) {
///         var text = $editable.text();
///         var lastAt = text.lastIndexOf('@');
///         if (lastAt !== -1 && text.length > lastAt + 1) {
///           var query = text.substring(lastAt + 1);
///           // Call Dart handler with query
///           window.flutter_inappwebview.callHandler(
///             'plugin_customMention_onSearch',
///             query
///           );
///         }
///       };
///     }
///   });
/// }));
/// ```
class MentionPluginMigrationExample {}

/// Example 2: Migrating EmojiPlugin
///
/// **OLD (deprecated):**
/// ```dart
/// RichEditor(
///   controller: controller,
///   plugins: [
///     EmojiPlugin(
///       onEmojiSelected: (emoji) {
///         print('Emoji selected: ${emoji.name}');
///       },
///     ),
///   ],
/// )
/// ```
///
/// **NEW (recommended):**
/// ```dart
/// RichEditor(
///   controller: controller,
///   plugins: [
///     // Option 1: Load from CDN
///     SummernotePlugin.fromUrl(
///       'emoji',
///       'https://cdn.jsdelivr.net/npm/summernote-emoji/dist/summernote-emoji.min.js',
///       options: {
///         'emojiPath': '/assets/emoji/',
///         'buttonIcon': '<i class="note-icon-smile"/>',
///       },
///       callbacks: {
///         'onEmojiSelect': (emoji) => print('Emoji: $emoji'),
///       },
///     ),
///
///     // Option 2: Load from Flutter asset
///     SummernotePlugin.fromAsset(
///       'emoji',
///       'assets/summernote_plugins/emoji/summernote-emoji.js',
///       options: {
///         'emojiPath': '/assets/emoji/',
///       },
///       callbacks: {
///         'onSelect': (emoji) => insertEmoji(emoji),
///       },
///     ),
///
///     // Option 3: Inline custom emoji plugin
///     SummernotePlugin.fromCode(
///       'emoji',
///       '''
///         (function(factory) { factory(jQuery); }(function(\$) {
///           \$.extend(true, \$.summernote.lang, {
///             'en-US': { emoji: { tooltip: 'Emoji' } }
///           });
///           \$.extend(\$.summernote.options, {
///             emoji: {
///               emojiPath: '/assets/emoji/',
///               icon: '<i class="note-icon-smile"/>'
///             }
///           });
///           \$.extend(\$.summernote.plugins, {
///             'emoji': function(context) {
///               var ui = \$.summernote.ui;
///               context.memo('button.emoji', function() {
///                 return ui.button({
///                   contents: \$.summernote.options.emoji.icon,
///                   tooltip: \$.summernote.lang.en_US.emoji.tooltip,
///                   click: function() {
///                     // Show emoji picker
///                     window.flutter_inappwebview.callHandler('plugin_emoji_onShowPicker');
///                   }
///                 }).render();
///               });
///             }
///           });
///         }));
///       ''',
///       callbacks: {
///         'onShowPicker': () => showEmojiPicker(),
///       },
///     ),
///   ],
///   customSummernoteOptions: {
///     'toolbar': [
///       ['insert', ['emoji']],
///     ],
///   },
/// )
/// ```
class EmojiPluginMigrationExample {}

/// Example 3: Creating a Simple Custom Plugin
///
/// This example shows how to create a simple "Hello World" plugin:
///
/// ```dart
/// RichEditor(
///   controller: controller,
///   plugins: [
///     SummernotePlugin.fromCode(
///       'helloPlugin',
///       '''
///         (function(factory) { factory(jQuery); }(function(\$) {
///           // Extend language
///           \$.extend(true, \$.summernote.lang, {
///             'en-US': {
///               helloPlugin: {
///                 tooltip: 'Say Hello',
///                 dialogTitle: 'Hello World',
///                 okButton: 'OK',
///               }
///             }
///           });
///
///           // Extend options
///           \$.extend(\$.summernote.options, {
///             helloPlugin: {
///               icon: '<i class="note-icon-star"/>',
///               message: 'Hello from plugin!',
///             }
///           });
///
///           // Define the plugin
///           \$.extend(\$.summernote.plugins, {
///             'helloPlugin': function(context) {
///               var self = this;
///               var ui = \$.summernote.ui;
///               var \$editor = context.layoutInfo.editor;
///               var \$editable = context.layoutInfo.editable;
///               var options = context.options;
///
///               // Register button
///               context.memo('button.helloPlugin', function() {
///                 return ui.button({
///                   contents: options.helloPlugin.icon,
///                   tooltip: \$.summernote.lang.en_US.helloPlugin.tooltip,
///                   click: function() {
///                     self.showDialog();
///                   }
///                 }).render();
///               });
///
///               // Initialize dialog
///               this.initialize = function() {
///                 var \$container = options.dialogsInBody ? \$(document.body) : \$editor;
///                 var body = '<div class="form-group">' +
///                   '<label>' + options.helloPlugin.message + '</label>' +
///                   '</div>';
///                 var footer = '<button href="#" class="btn btn-primary note-hello-plugin-btn">' +
///                   \$.summernote.lang.en_US.helloPlugin.okButton +
///                   '</button>';
///
///                 this.\$dialog = ui.dialog({
///                   title: \$.summernote.lang.en_US.helloPlugin.dialogTitle,
///                   body: body,
///                   footer: footer
///                 }).render().appendTo(\$container);
///               };
///
///               // Destroy dialog
///               this.destroy = function() {
///                 ui.hideDialog(this.\$dialog);
///                 this.\$dialog.remove();
///               };
///
///               // Show dialog
///               this.showDialog = function() {
///                 var self = this;
///                 context.invoke('editor.saveRange');
///                 ui.showDialog(this.\$dialog);
///
///                 this.\$dialog.find('.note-hello-plugin-btn').click(function(e) {
///                   e.preventDefault();
///                   context.invoke('editor.restoreRange');
///
///                   // Call Dart handler
///                   window.flutter_inappwebview.callHandler(
///                     'plugin_helloPlugin_onAction',
///                     { message: options.helloPlugin.message }
///                   );
///
///                   ui.hideDialog(self.\$dialog);
///                 });
///               };
///             }
///           });
///         }));
///       ''',
///       options: {
///         'icon': '<i class="note-icon-star"/>',
///         'message': 'Hello from plugin!',
///       },
///       language: {
///         'en-US': {
///           'tooltip': 'Say Hello',
///           'dialogTitle': 'Hello World',
///           'okButton': 'OK',
///         },
///       },
///       callbacks: {
///         'onAction': (data) => print('Action: ${data['message']}'),
///       },
///     ),
///   ],
///   customSummernoteOptions: {
///     'toolbar': [
///       ['custom', ['helloPlugin']],
///     ],
///   },
/// )
/// ```
class SimpleCustomPluginExample {}

/// Summary of Migration Benefits
///
/// The new SummernotePlugin system provides several advantages:
///
/// 1. **Native Summernote Integration**: Plugins work directly with Summernote's
///    plugin API, ensuring better compatibility and stability.
///
/// 2. **Three Loading Methods**:
///    - `fromUrl()`: Load from CDN for quick testing and updates
///    - `fromAsset()`: Bundle with your app for offline support
///    - `fromCode()`: Inline plugins for simple use cases
///
/// 3. **Standard Plugin Architecture**: Use existing Summernote plugins from
///    the community (https://summernote.org/plugins).
///
/// 4. **Simpler Callback Bridge**: Direct mapping between JavaScript and Dart
///    using standardized handler names.
///
/// 5. **Better Toolbar Integration**: Plugin buttons are configured through
///    standard Summernote toolbar options.
///
/// For more information on creating Summernote plugins, see:
/// - https://summernote.org/plugins
/// - https://github.com/summernote/summernote/tree/develop/plugin
class MigrationSummary {}
