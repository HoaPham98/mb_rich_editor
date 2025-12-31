import 'package:flutter/material.dart';
import 'package:mb_rich_editor/mb_rich_editor.dart';

class EditorToolbar extends StatelessWidget {
  final RichEditorController controller;
  final VoidCallback onEmojiPicker;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.onEmojiPicker,
  });

  @override
  Widget build(BuildContext context) {
    return MBRichEditorToolbar(
      controller: controller,
      options: const MBToolbarOptions(
        buttons: [
          ToolbarButtonDefinition.emojiPicker,
          ...ToolbarButtonDefinition.basicTextFormatting,
          ...ToolbarButtonDefinition.blocks,
          ...ToolbarButtonDefinition.alignment,
        ],
      ),
      onEmojiPicker: onEmojiPicker,
    );
  }
}
