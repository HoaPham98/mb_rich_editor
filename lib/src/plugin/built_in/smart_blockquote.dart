/// Built-in Summernote plugins for mb_rich_editor.
///
/// This library contains ready-to-use Summernote plugins that can be
/// directly used with the `RichEditor` widget.
library;

import '../summernote_plugin.dart';

/// Smart Blockquote Exit Plugin
///
/// This plugin improves the blockquote editing experience by intelligently
/// handling the Enter key to exit blockquotes.
///
/// **Features:**
/// - Press Enter on an empty line inside a blockquote to exit and create a new paragraph
/// - Press Enter on a non-empty line to create a new line inside the blockquote
/// - Maintains proper cursor position when exiting
///
/// **Usage:**
/// ```dart
/// RichEditor(
///   controller: controller,
///   plugins: [
///     smartBlockquote,
///   ],
/// )
/// ```
///
/// **Technical Details:**
/// - The plugin registers a `keydown` event handler
/// - When Enter (keyCode 13) is pressed without Shift:
///   - If inside a blockquote and the current line is empty, it exits the blockquote
///   - Otherwise, it allows normal behavior (creates new line inside)
/// - Empty line detection checks for no text and no inline/block elements
///
/// **Note:** This plugin uses the plugin name `'smartBlockquoteExit'` internally.
final SummernotePlugin smartBlockquote = SummernotePlugin.fromCode(
  'smartBlockquoteExit',
  r'''
    (function (factory) {
    if (typeof define === 'function' && define.amd) {
        define(['jquery'], factory);
    } else if (typeof module === 'object' && module.exports) {
        module.exports = factory(require('jquery'));
    } else {
        factory(window.jQuery);
    }
}(function ($) {
    $.extend($.summernote.plugins, {
        'smartBlockquoteExit': function (context) {
            var self = this;
            var ui = $.summernote.ui;
            // Get core objects
            var $note = context.layoutInfo.note;
            var $editor = context.layoutInfo.editor;
            var $editable = context.layoutInfo.editable;

            this.events = {
                'summernote.keydown': function (we, e) {
                    // Handle Enter key (without Shift)
                    if (e.keyCode === 13 && !e.shiftKey) {

                        // Get current cursor position
                        var range = context.invoke('editor.createRange');
                        var $blockquote = $(range.sc).closest('blockquote');

                        // If inside a blockquote
                        if ($blockquote.length > 0) {

                            // Determine current block (usually p or div tag)
                            var $currentBlock = $(range.sc).closest('p, div, h1, h2, h3, h4, h5, h6, li');

                            // Check for empty line: No text and no child tags (like img)
                            // Note: Summernote typically uses <br> in empty lines, so checking text is sufficient
                            var isEmpty = $currentBlock.text().trim() === '' &&
                                          ($currentBlock.find('img, span, div, input').length === 0);

                            // --- EXIT BLOCKQUOTE LOGIC ---
                            if (isEmpty) {
                                e.preventDefault(); // Prevent creating second empty line

                                // 1. Remove current empty line (created by first Enter press)
                                $currentBlock.remove();

                                // 2. Create new paragraph outside, right after blockquote
                                var $newPara = $('<p><br/></p>');
                                $blockquote.after($newPara);

                                // 3. Move cursor outside into new tag
                                var newRange = document.createRange();
                                var selection = window.getSelection();
                                newRange.setStart($newPara[0], 0);
                                newRange.collapse(true);
                                selection.removeAllRanges();
                                selection.addRange(newRange);

                                // Save state for Undo/Redo support
                                context.invoke('editor.saveRange');
                            }

                            // If line is NOT empty:
                            // We do nothing (no preventDefault).
                            // Since you set blockquoteBreakingLevel: 0,
                            // Summernote will automatically create new line inside quote for you.
                        }
                    }
                }
            };
        }
    });
}));
  ''',
  options: const {},
);
