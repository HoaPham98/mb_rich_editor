import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../mention/models/mention.dart';
import '../mention/models/mention_user.dart';
import 'rich_editor_plugin.dart';

/// Plugin for mention functionality in the RichEditor.
///
/// This plugin handles:
/// - Detecting when the user types a mention trigger (e.g., '@')
/// - Inserting formatted mentions
/// - Parsing and extracting mentions from content
///
/// @deprecated Use `SummernotePlugin` with a Summernote-compatible mention plugin.
/// This class will be removed in v2.0.0.
///
/// **Migration Guide:**
/// ```dart
/// // OLD (deprecated)
/// MentionPlugin(
///   trigger: '@',
///   onMentionTrigger: (query) { ... },
/// )
///
/// // NEW (recommended)
/// SummernotePlugin.fromAsset(
///   'mention',
///   'assets/summernote_plugins/mention/summernote-mention.js',
///   options: {'trigger': '@'},
///   callbacks: {'onSearch': (query) { ... }},
/// )
/// ```
@Deprecated('Use SummernotePlugin with a Summernote-compatible mention plugin instead. Will be removed in v2.0.0.')
class MentionPlugin extends RichEditorPlugin {
  /// The trigger character for mentions (default: '@')
  final String trigger;

  /// Called when a mention trigger is detected with the current query text.
  final ValueChanged<String?>? onMentionTrigger;

  /// Called when the mention suggestions should be hidden.
  final VoidCallback? onMentionHide;

  /// Called when a mention is selected/clicked.
  final ValueChanged<Mention?>? onMentionSelected;

  /// Internal state
  Mention? _currentMention;
  List<Mention> _allMentions = [];

  MentionPlugin({
    this.trigger = '@',
    this.onMentionTrigger,
    this.onMentionHide,
    this.onMentionSelected,
  });

  @override
  String get id => 'mention';

  @override
  List<String> get handlerNames => [
    'getMentionTextAtCursor',
    'hideMentionBottomSheet',
    'getMentionAtCursor',
    'getAllMentions',
  ];

  @override
  String get javascriptToInject =>
      '''
// ==================== Mention Plugin ====================

(function() {
  // Track when we've just inserted a mention to prevent re-triggering
  var _justInsertedMention = false;
  var _mentionInsertTimeout = null;
  var endSpace = /\\s\$/;

  /**
   * Insert a mention at the current cursor position.
   */
  RE.insertMention = function(mentionData) {
    RE.restorerange();

    _justInsertedMention = true;
    if (_mentionInsertTimeout) {
      clearTimeout(_mentionInsertTimeout);
    }
    _mentionInsertTimeout = setTimeout(function() {
      _justInsertedMention = false;
    }, 500);

    var trigger = mentionData.trigger || '$trigger';
    var user = mentionData.user;
    var format = mentionData.format || 'link';

    var html = '';
    switch (format) {
      case 'text':
        html = trigger + user.username;
        break;
      case 'link':
      default:
        var href = (mentionData.attributes && mentionData.attributes.href) || '#';
        var className = (mentionData.attributes && mentionData.attributes.className) || 'mention';
        html = '<a href="' + href + '" class="' + className + '" data-user-id="' + user.id + '" data-username="' + user.username + '">' + trigger + user.username + '</a>';
        break;
    }

    // Get text around cursor to find and replace @ + query
    var textAroundCursor = RE.getTextAroundCursor(50);
    var triggerEvent = RE.detectMentionTrigger(textAroundCursor, textAroundCursor.length, trigger);

    if (triggerEvent) {
      // We need to delete the @query and insert the mention
      var selection = window.getSelection();
      if (selection.rangeCount > 0) {
        var range = selection.getRangeAt(0);
        
        // Move back to delete the trigger + query
        for (var i = 0; i <= triggerEvent.query.length; i++) {
          document.execCommand('delete', false, null);
        }
        
        // Insert the mention HTML
        \$('#editor').summernote('pasteHTML', html + ' ');
      }
    } else {
      \$('#editor').summernote('pasteHTML', html + ' ');
    }

    RE.callback();
  };

  /**
   * Detect mention trigger in text at the current cursor position.
   */
  RE.detectMentionTrigger = function(text, position, trigger) {
    var lastTriggerIndex = -1;
    for (var i = position - 1; i >= 0; i--) {
      if (text[i] === trigger) {
        lastTriggerIndex = i;
        break;
      }
      if (text[i] === ' ' || text[i] === '\\n' || text[i] === '\\t') {
        break;
      }
    }

    if (lastTriggerIndex === -1) {
      return null;
    }

    var query = text.substring(lastTriggerIndex + 1, position).trim();
    var hasSpaceBefore = lastTriggerIndex === 0 || /\\s/.test(text[lastTriggerIndex - 1]);

    return {
      trigger: trigger,
      query: query,
      position: lastTriggerIndex,
      hasSpaceBefore: hasSpaceBefore,
      range: {
        start: lastTriggerIndex,
        end: position
      }
    };
  };

  /**
   * Get the mention at the current cursor position.
   */
  RE.getMentionAtCursor = function() {
    var selection = window.getSelection();
    if (!selection.rangeCount) return null;

    var range = selection.getRangeAt(0);
    var node = range.startContainer;

    if (node.nodeType === 3) {
      node = node.parentElement;
    }

    var mentionElement = node.closest('.mention, a[data-user-id]');
    if (!mentionElement) {
      return null;
    }

    return JSON.stringify({
      user: {
        id: mentionElement.getAttribute('data-user-id'),
        username: mentionElement.getAttribute('data-username')
      }
    });
  };

  /**
   * Get all mentions in the editor content.
   */
  RE.getAllMentions = function() {
    var mentions = [];
    var mentionElements = \$(RE.editor).find('.mention, a[data-user-id]');

    mentionElements.each(function() {
      var el = \$(this);
      mentions.push({
        user: {
          id: el.attr('data-user-id'),
          username: el.attr('data-username')
        }
      });
    });

    return JSON.stringify(mentions);
  };

  /**
   * Check if cursor is inside a mention.
   */
  RE.isCursorInsideMention = function() {
    if (_justInsertedMention) {
      return true;
    }

    var selection = window.getSelection();
    if (!selection.rangeCount) return false;

    var range = selection.getRangeAt(0);
    var node = range.startContainer;

    if (node.nodeType === 3) {
      node = node.parentElement;
    }

    return node.closest('.mention, a[data-user-id]') !== null;
  };

  // Hook into the Summernote onKeyup event for mention detection
  var originalHandleKeyup = RE.handleKeyup;
  RE.handleKeyup = function(e) {
    if (originalHandleKeyup) originalHandleKeyup(e);

    // Check if we should trigger mention detection
    if (!RE.isCursorInsideMention()) {
      var textAroundCursor = RE.getTextAroundCursor(50);
      
      if (endSpace.test(textAroundCursor)) {
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('hideMentionBottomSheet');
        }
        return;
      }

      var triggerEvent = RE.detectMentionTrigger(textAroundCursor, textAroundCursor.length, '$trigger');

      if (triggerEvent && triggerEvent.query.length >= 1) {
        var mentionText = textAroundCursor.substring(triggerEvent.position);
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('getMentionTextAtCursor', mentionText);
        }
      }
    }
  };

})();
''';

  @override
  void onHandlerCalled(String handlerName, dynamic args) {
    switch (handlerName) {
      case 'getMentionTextAtCursor':
        debugPrint('DEBUG: getMentionTextAtCursor received: $args');
        onMentionTrigger?.call(args?.toString());
        break;
      case 'hideMentionBottomSheet':
        debugPrint('DEBUG: hideMentionBottomSheet called');
        onMentionHide?.call();
        break;
      case 'getMentionAtCursor':
        debugPrint('DEBUG: getMentionAtCursor received: $args');
        if (args != null) {
          try {
            final mentionData = jsonDecode(args.toString());
            _currentMention = Mention(
              user: MentionUser(
                id: mentionData['user']['id'] ?? '',
                username: mentionData['user']['username'] ?? '',
              ),
              trigger: trigger,
              format: MentionFormat.link,
            );
            onMentionSelected?.call(_currentMention);
          } catch (e) {
            debugPrint('DEBUG: Error parsing mention: $e');
          }
        }
        break;
      case 'getAllMentions':
        debugPrint('DEBUG: getAllMentions received: $args');
        if (args != null) {
          try {
            final List<dynamic> mentionsData = jsonDecode(args.toString());
            _allMentions = mentionsData
                .map(
                  (data) => Mention(
                    user: MentionUser(
                      id: data['user']['id'] ?? '',
                      username: data['user']['username'] ?? '',
                    ),
                    trigger: trigger,
                    format: MentionFormat.link,
                  ),
                )
                .toList();
          } catch (e) {
            debugPrint('DEBUG: Error parsing mentions: $e');
          }
        }
        break;
    }
  }

  /// Get the current mention at cursor
  Mention? get currentMention => _currentMention;

  /// Get all mentions in the editor
  List<Mention> get allMentions => List.unmodifiable(_allMentions);

  /// Insert a mention programmatically
  Future<void> insertMention(Mention mention) async {
    if (controller != null) {
      await controller!.insertHtml(''); // Ensure focus
      // The actual insertion is done via JS
    }
  }
}
