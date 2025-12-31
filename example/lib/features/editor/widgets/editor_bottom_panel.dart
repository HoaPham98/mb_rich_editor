import 'package:flutter/material.dart';

// Actually, emoji/widgets/emoji_picker.dart is in example/lib.
// So import should be relative or package:example/ ... but example doesn't name itself 'example' in pubspec usually?
// Checked pubspec: name: example. So package:example/ works.
// Or relative: ../../../emoji/widgets/emoji_picker.dart
import 'package:mb_rich_editor/mb_rich_editor.dart';
import '../../../emoji/sources/json_emoji_source.dart';
import '../controllers/editor_ui_state.dart';

class EditorBottomPanel extends StatelessWidget {
  final EditorUIState uiState;
  final JsonEmojiSource emojiSource;
  final Function(Emoji) onEmojiSelected;

  const EditorBottomPanel({
    super.key,
    required this.uiState,
    required this.emojiSource,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    // If nothing to show, return minimal
    if (!uiState.isEmojiVisible && !uiState.isKeyboardVisible) {
      return SizedBox(height: MediaQuery.of(context).viewPadding.bottom);
    }

    return SizedBox(
      height: uiState.bottomAreaHeight,
      child: uiState.isEmojiVisible || uiState.isKeyboardVisible
          ? SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: uiState.savedKeyboardHeight,
                child: _buildContent(),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (uiState.isEmojiVisible) {
      return EmojiPicker(
        emojiSource: emojiSource,
        config: EmojiPickerConfig.compact,
        style: EmojiPickerStyle(),
        onEmojiSelected: onEmojiSelected,
      );
    }
    // If keyboard is visible, we just show a spacer (or nothing, as the keyboard covers it likely?
    // In the original code:
    // if _isKeyboardVisible || _isEmojiVisible -> show SizedBox with height.
    // Inside it: if _isEmojiVisible -> EmojiPicker.
    // If _isKeyboardVisible -> The area is "empty" but takes up space?
    // Wait, if keyboard is visible, the keyboard itself takes up screen space. We don't need to render a widget 'behind' it usually,
    // unless the bottom sheet is mimicking the keyboard height.

    // In original code:
    // child: _isEmojiVisible || _isKeyboardVisible ? ...
    //   child: _buildEmojiPicker()
    // This logic seems to imply ALWAYS building emoji picker if either is true?
    // "The picker should already be "behind" the keyboard, so this transition reveals it."
    // Yes, the user wants the picker to be "behind" the keyboard.

    return EmojiPicker(
      emojiSource: emojiSource,
      config: EmojiPickerConfig.compact,
      style: EmojiPickerStyle(),
      onEmojiSelected: onEmojiSelected,
    );
  }
}
