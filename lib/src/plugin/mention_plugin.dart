import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../mention/models/mention_user.dart';
import '../core/rich_editor_controller.dart';
import 'summernote_plugin.dart';

/// Mention plugin for the rich editor.
///
/// This plugin uses a Summernote mention plugin to detect @ trigger
/// and notify Dart via callback. Use the static [insertMention] method
/// to insert a mention when the user selects one.
///
/// Example usage:
/// ```dart
/// RichEditor(
///   plugins: [
///     MentionPlugin(
///       onMentionTrigger: (query) => _showMentionPicker(query),
///       onMentionHide: () => Navigator.pop(context),
///     ),
///   ],
/// )
///
/// // When user selects a mention:
/// MentionPlugin.insertMention(_controller, selectedUser);
/// ```
class MentionPlugin extends SummernotePlugin {
  /// The embedded JavaScript code for the mention plugin
  static const String _javascriptCode = r'''
/**
 * Summernote Mention Plugin - Minimal Version for Dart
 *
 * This plugin:
 * - Detects @ trigger
 * - Notifies Dart with query via callback
 * - Inserts mention when Dart calls insertMentionFromDart
 */

// Store plugin instance globally for access from RE.insertMentionFromDart
window.__summernoteAtMentionInstance = null;

class SelectionPreserver {
  constructor(rootNode) {
    if (rootNode === undefined || rootNode === null) {
      throw new Error("Please provide a valid rootNode.");
    }
    this.rootNode = rootNode;
    this.rangeStartContainerAddress = null;
    this.rangeStartOffset = null;
  }

  preserve() {
    const selection = window.getSelection();
    this.rangeStartOffset = selection.getRangeAt(0).startOffset;
    this.rangeStartContainerAddress = this.findRangeStartContainerAddress(selection);
  }

  restore(restoreIndex) {
    if (this.rangeStartOffset === null || this.rangeStartContainerAddress === null) {
      throw new Error("Please call preserve() first.");
    }
    let rangeStartContainer = this.findRangeStartContainer();
    const range = document.createRange();
    const offSet = restoreIndex || this.rangeStartOffset;
    range.setStart(rangeStartContainer, offSet);
    range.collapse();
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
  }

  findRangeStartContainer() {
    let rangeStartContainer = this.rootNode;
    this.rangeStartContainerAddress.forEach(address => {
      rangeStartContainer = rangeStartContainer.childNodes[address];
    });
    return rangeStartContainer;
  }

  findRangeStartContainerAddress(selection) {
    let rangeStartContainerAddress = [];
    for (
      let currentContainer = selection.getRangeAt(0).startContainer;
      currentContainer !== this.rootNode;
      currentContainer = currentContainer.parentNode
    ) {
      const parent = currentContainer.parentElement;
      const children = parent.childNodes;
      for (let i = 0; i < children.length; i++) {
        if (children[i] === currentContainer) {
          rangeStartContainerAddress = [i, ...rangeStartContainerAddress];
          break;
        }
      }
    }
    return rangeStartContainerAddress;
  }
}

const WORD_REGEX = /^[^\s]+$/;

// Directly register the plugin with Summernote
(function($) {
  $.summernote.plugins.summernoteAtMention = function(context) {
    const self = this;
    this.editableEl = context.layoutInfo.editable[0];
    this.editorEl = context.layoutInfo.editor[0];

    // Store instance globally
    window.__summernoteAtMentionInstance = this;

    /**********
     * Events *
     **********/
    this.events = {
      "summernote.blur": () => {
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('plugin_summernoteAtMention_onMentionHide', null);
        }
      },
      "summernote.keyup": (_, event) => {
        const selection = document.getSelection();
        const currentText = selection.anchorNode.nodeValue;
        const { word } = this.findWordAndIndices(
          currentText || "",
          selection.anchorOffset
        );
        const trimmedWord = word.slice(1);

        if (word[0] === "@") {
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('plugin_summernoteAtMention_onMentionTrigger', {
              query: trimmedWord,
              trigger: '@'
            });
          }
        } else {
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('plugin_summernoteAtMention_onMentionHide', null);
          }
        }
      }
    };

    /***********
     * Helpers *
     ***********/

    this.findWordAndIndices = (text, offset) => {
      if (offset > text.length) {
        return { word: "", relativeIndex: 0 };
      } else {
        let leftWord = "";
        let relativeIndex = 0;
        let absoluteIndex = offset;

        for (let currentOffset = offset; currentOffset > 0; currentOffset--) {
          if (text[currentOffset - 1].match(WORD_REGEX)) {
            leftWord = text[currentOffset - 1] + leftWord;
            relativeIndex++;
            absoluteIndex--;
          } else {
            break;
          }
        }

        return {
          word: leftWord,
          relativeIndex,
          absoluteIndex
        };
      }
    };

    /**
     * Insert a mention from Dart (called when user selects from picker)
     * Called from Dart as: RE.insertMentionFromDart({user: {...}, trigger: '@'})
     */
    this.insertMentionFromDart = (mentionData) => {
      const trigger = mentionData.trigger || '@';
      const user = mentionData.user;
      const mentionText = user.username;

      const selection = document.getSelection();
      const currentText = selection.anchorNode.nodeValue;
      const { word, absoluteIndex } = this.findWordAndIndices(
        currentText || "",
        selection.anchorOffset
      );

      const selectionPreserver = new SelectionPreserver(this.editableEl);
      selectionPreserver.preserve();

      // Replace @query with @username
      selection.anchorNode.textContent =
        currentText.slice(0, absoluteIndex + 1) +
        mentionText +
        " " +
        currentText.slice(absoluteIndex + word.length);

      selectionPreserver.restore(absoluteIndex + mentionText.length + 1);

      if (context.options.callbacks.onChange !== undefined) {
        context.options.callbacks.onChange(this.editableEl.innerHTML);
      }

      // Notify Dart to hide picker
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('plugin_summernoteAtMention_onMentionHide', null);
      }
    };
  };
})(window.jQuery);

/**
 * Global function to insert mention from Dart
 * Called from Dart as: RE.insertMentionFromDart({user: {...}, trigger: '@'})
 */
RE.insertMentionFromDart = function(mentionData) {
  console.log('RE.insertMentionFromDart called with:', mentionData);

  // Use the globally stored instance
  const instance = window.__summernoteAtMentionInstance;
  if (instance && typeof instance.insertMentionFromDart === 'function') {
    instance.insertMentionFromDart(mentionData);
  } else {
    console.error('summernoteAtMention plugin instance not found', {
      hasInstance: !!instance,
      hasMethod: instance && typeof instance.insertMentionFromDart === 'function'
    });
  }
};
''';

  /// Callback when @ trigger is detected with the search query
  final ValueChanged<String> onMentionTrigger;

  /// Callback when mention should be hidden
  final VoidCallback? onMentionHide;

  /// Creates a mention plugin with embedded JavaScript (for hot reload support).
  MentionPlugin({required this.onMentionTrigger, this.onMentionHide})
    : super(
        pluginName: 'summernoteAtMention',
        rawJavaScript: _javascriptCode,
        callbacks: {
          'onMentionTrigger': (data) {
            final query = data is Map
                ? data['query'] as String? ?? ''
                : data.toString();
            onMentionTrigger(query);
          },
          if (onMentionHide != null) 'onMentionHide': (_) => onMentionHide(),
        },
      );

  /// Insert a mention into the editor at the current cursor position.
  ///
  /// This method calls the JavaScript function `RE.insertMentionFromDart`
  /// which is provided by the mention plugin. The mention will replace
  /// the @query text that triggered the mention picker.
  ///
  /// Example:
  /// ```dart
  /// // When user selects a user from the picker:
  /// MentionPlugin.insertMention(_controller, selectedUser);
  /// ```
  static Future<void> insertMention(
    RichEditorController controller,
    MentionUser user, {
    String trigger = '@',
  }) async {
    final mentionData = jsonEncode({
      'user': user.toJson(),
      'trigger': trigger,
    });
    await controller.evalJs('RE.insertMentionFromDart($mentionData);');
  }
}
