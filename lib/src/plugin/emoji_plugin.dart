import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../emoji/models/emoji.dart';
import 'rich_editor_plugin.dart';

/// Plugin for emoji functionality in the RichEditor.
///
/// This plugin handles:
/// - Inserting emoji images at cursor position
/// - Getting emoji at cursor
///
/// @deprecated Use `SummernotePlugin` with a Summernote-compatible emoji plugin.
/// This class will be removed in v2.0.0.
///
/// **Migration Guide:**
/// ```dart
/// // OLD (deprecated)
/// EmojiPlugin(
///   onEmojiSelected: (emoji) { ... },
/// )
///
/// // NEW (recommended)
/// SummernotePlugin.fromUrl(
///   'emoji',
///   'https://cdn.jsdelivr.net/npm/summernote-emoji/dist/summernote-emoji.min.js',
///   options: {'emojiPath': '/assets/emoji/'},
///   callbacks: {'onEmojiSelect': (emoji) { ... }},
/// )
/// ```
@Deprecated('Use SummernotePlugin with a Summernote-compatible emoji plugin instead. Will be removed in v2.0.0.')
class EmojiPlugin extends RichEditorPlugin {
  /// Called when an emoji is selected/clicked.
  final ValueChanged<Emoji?>? onEmojiSelected;

  /// Internal state
  Emoji? _currentEmoji;

  EmojiPlugin({this.onEmojiSelected});

  @override
  String get id => 'emoji';

  @override
  List<String> get handlerNames => ['getEmojiAtCursor'];

  @override
  String get javascriptToInject => '''
// ==================== Emoji Plugin ====================

(function() {

  /**
   * Insert an emoji at the current cursor position.
   */
  RE.insertEmoji = function(emojiData) {
    var url = emojiData.imageUrl || '';
    var alt = (emojiData.metadata && emojiData.metadata.alt) || emojiData.name || emojiData.shortcodes || 'emoji';
    var className = 'emoji';

    var html = '<img src="' + url + '" class="' + className + '" alt="' + alt + '" data-emoji-id="' + emojiData.id + '" />';
    \$('#editor').summernote('pasteHTML', html);
    RE.callback();
  };

  /**
   * Get the emoji at the current cursor position.
   */
  RE.getEmojiAtCursor = function() {
    var selection = window.getSelection();
    if (!selection.rangeCount) return null;

    var range = selection.getRangeAt(0);
    var node = range.startContainer;

    if (node.nodeType === 3) {
      node = node.parentElement;
    }

    var emojiElement = node.closest('img.emoji, img[data-emoji-id]');
    if (!emojiElement) {
      return null;
    }

    return JSON.stringify({
      id: emojiElement.getAttribute('data-emoji-id'),
      imageUrl: emojiElement.src,
      name: emojiElement.alt
    });
  };

})();
''';

  @override
  void onHandlerCalled(String handlerName, dynamic args) {
    switch (handlerName) {
      case 'getEmojiAtCursor':
        debugPrint('DEBUG: getEmojiAtCursor received: $args');
        if (args != null) {
          try {
            final emojiData = jsonDecode(args.toString());
            _currentEmoji = Emoji(
              id: emojiData['id'] ?? '',
              name: emojiData['name'] ?? '',
              imageUrl: emojiData['imageUrl'] ?? '',
              category: 'custom',
            );
            onEmojiSelected?.call(_currentEmoji);
          } catch (e) {
            debugPrint('DEBUG: Error parsing emoji: $e');
          }
        }
        break;
    }
  }

  /// Get the current emoji at cursor
  Emoji? get currentEmoji => _currentEmoji;

  /// Insert an emoji programmatically
  Future<void> insertEmoji(Emoji emoji) async {
    if (controller != null) {
      // This will be handled by the injected JS via controller.evaluateJavascript
    }
  }
}
