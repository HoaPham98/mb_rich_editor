import 'package:flutter/material.dart';

///
/// A single toolbar button for the rich editor.
///
class ToolbarButton extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Label (for tooltip or text-only buttons)
  final String? label;

  /// Whether the button is currently active (pressed state)
  final bool isActive;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Button style
  final ButtonStyle? style;

  /// Icon size
  final double iconSize;

  /// Whether to show label next to icon
  final bool showLabel;

  const ToolbarButton({
    super.key,
    required this.icon,
    this.label,
    this.isActive = false,
    required this.onPressed,
    this.style,
    this.iconSize = 24.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Default button style
    final ButtonStyle defaultStyle = IconButton.styleFrom(
      foregroundColor: isActive
          ? theme.colorScheme.primary
          : theme.iconTheme.color,
      backgroundColor: isActive
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      hoverColor: theme.colorScheme.primary.withValues(alpha: 0.05),
      iconSize: iconSize,
    );

    // Merge with custom style if provided
    final effectiveStyle = style != null
        ? defaultStyle.merge(style)
        : defaultStyle;

    if (showLabel && label != null) {
      // Show icon with label
      return TextButton.icon(
        icon: Icon(icon, size: iconSize),
        label: Text(label!),
        onPressed: onPressed,
        style: effectiveStyle,
      );
    }

    // Icon-only button
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      style: effectiveStyle,
      tooltip: label,
    );
  }
}

///
/// Definition of a toolbar button.
///
class ToolbarButtonDefinition {
  /// Unique identifier for the button
  final String id;

  /// Display icon
  final IconData icon;

  /// Display label
  final String label;

  /// Decoration state to check for active status
  final String? decorationState;

  const ToolbarButtonDefinition({
    required this.id,
    required this.icon,
    required this.label,
    this.decorationState,
  });

  // Text Formatting
  static const bold = ToolbarButtonDefinition(
    id: 'bold',
    icon: Icons.format_bold,
    label: 'Bold',
    decorationState: 'bold',
  );

  static const italic = ToolbarButtonDefinition(
    id: 'italic',
    icon: Icons.format_italic,
    label: 'Italic',
    decorationState: 'italic',
  );

  static const underline = ToolbarButtonDefinition(
    id: 'underline',
    icon: Icons.format_underlined,
    label: 'Underline',
    decorationState: 'underline',
  );

  static const strikeThrough = ToolbarButtonDefinition(
    id: 'strikeThrough',
    icon: Icons.format_strikethrough,
    label: 'Strikethrough',
    decorationState: 'strikeThrough',
  );

  static const subscript = ToolbarButtonDefinition(
    id: 'subscript',
    icon: Icons.subscript,
    label: 'Subscript',
    decorationState: 'subscript',
  );

  static const superscript = ToolbarButtonDefinition(
    id: 'superscript',
    icon: Icons.superscript,
    label: 'Superscript',
    decorationState: 'superscript',
  );

  // Headings
  static const heading1 = ToolbarButtonDefinition(
    id: 'heading1',
    icon: Icons.title,
    label: 'Heading 1',
  );

  static const heading2 = ToolbarButtonDefinition(
    id: 'heading2',
    icon: Icons.title,
    label: 'Heading 2',
  );

  static const heading3 = ToolbarButtonDefinition(
    id: 'heading3',
    icon: Icons.title,
    label: 'Heading 3',
  );

  static const heading4 = ToolbarButtonDefinition(
    id: 'heading4',
    icon: Icons.title,
    label: 'Heading 4',
  );

  static const heading5 = ToolbarButtonDefinition(
    id: 'heading5',
    icon: Icons.title,
    label: 'Heading 5',
  );

  static const heading6 = ToolbarButtonDefinition(
    id: 'heading6',
    icon: Icons.title,
    label: 'Heading 6',
  );

  // Blocks
  static const blockquote = ToolbarButtonDefinition(
    id: 'blockquote',
    icon: Icons.format_quote,
    label: 'Blockquote',
    decorationState: 'blockquote',
  );

  static const bullets = ToolbarButtonDefinition(
    id: 'bullets',
    icon: Icons.format_list_bulleted,
    label: 'Bullets',
    decorationState: 'unorderedList',
  );

  static const numbers = ToolbarButtonDefinition(
    id: 'numbers',
    icon: Icons.format_list_numbered,
    label: 'Numbers',
    decorationState: 'orderedList',
  );

  // Alignment
  static const alignLeft = ToolbarButtonDefinition(
    id: 'alignLeft',
    icon: Icons.format_align_left,
    label: 'Align Left',
    decorationState: 'justifyLeft',
  );

  static const alignCenter = ToolbarButtonDefinition(
    id: 'alignCenter',
    icon: Icons.format_align_center,
    label: 'Align Center',
    decorationState: 'justifyCenter',
  );

  static const alignRight = ToolbarButtonDefinition(
    id: 'alignRight',
    icon: Icons.format_align_right,
    label: 'Align Right',
    decorationState: 'justifyRight',
  );

  // Indentation
  static const indent = ToolbarButtonDefinition(
    id: 'indent',
    icon: Icons.format_indent_increase,
    label: 'Increase Indent',
  );

  static const outdent = ToolbarButtonDefinition(
    id: 'outdent',
    icon: Icons.format_indent_decrease,
    label: 'Decrease Indent',
  );

  // Editor Control
  static const undo = ToolbarButtonDefinition(
    id: 'undo',
    icon: Icons.undo,
    label: 'Undo',
  );

  static const redo = ToolbarButtonDefinition(
    id: 'redo',
    icon: Icons.redo,
    label: 'Redo',
  );

  static const clearFormat = ToolbarButtonDefinition(
    id: 'clearFormat',
    icon: Icons.format_clear,
    label: 'Clear Format',
  );

  // Emoji & Mention
  static const emojiPicker = ToolbarButtonDefinition(
    id: 'emojiPicker',
    icon: Icons.emoji_emotions,
    label: 'Emoji',
  );

  static const mention = ToolbarButtonDefinition(
    id: 'mention',
    icon: Icons.alternate_email,
    label: 'Mention',
  );

  // Preset button groups
  static const List<ToolbarButtonDefinition> basicTextFormatting = [
    bold,
    italic,
    underline,
    strikeThrough,
  ];

  static const List<ToolbarButtonDefinition> advancedTextFormatting = [
    bold,
    italic,
    underline,
    strikeThrough,
    subscript,
    superscript,
  ];

  static const List<ToolbarButtonDefinition> blocks = [
    blockquote,
    bullets,
    numbers,
  ];

  static const List<ToolbarButtonDefinition> alignment = [
    alignLeft,
    alignCenter,
    alignRight,
  ];

  static const List<ToolbarButtonDefinition> indentation = [outdent, indent];

  static const List<ToolbarButtonDefinition> editorControls = [
    undo,
    redo,
    clearFormat,
  ];

  static const List<ToolbarButtonDefinition> allFormatting = [
    ...advancedTextFormatting,
    ...blocks,
    ...alignment,
    ...indentation,
  ];

  static const List<ToolbarButtonDefinition> emojiAndMention = [
    emojiPicker,
    mention,
  ];

  static const List<ToolbarButtonDefinition> all = [
    ...editorControls,
    ...advancedTextFormatting,
    ...blocks,
    ...alignment,
    ...indentation,
    ...emojiAndMention,
  ];
}
