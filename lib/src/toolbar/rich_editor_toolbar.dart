import 'package:flutter/material.dart';
import 'package:mb_rich_editor/mb_rich_editor.dart';

///
/// A customizable toolbar for the RichEditor widget.
///
/// Example usage:
/// ```dart
/// RichEditorToolbar(
///   controller: controller,
///   options: ToolbarOptions.defaultOptions,
/// )
/// ```
///
class MBRichEditorToolbar extends StatefulWidget {
  /// Controller for the rich editor
  final MBRichEditorController controller;

  /// Toolbar customization options
  final MBToolbarOptions options;

  final Function()? onEmojiPicker;

  const MBRichEditorToolbar({
    super.key,
    required this.controller,
    this.options = const MBToolbarOptions(),
    this.onEmojiPicker,
  });

  @override
  State<MBRichEditorToolbar> createState() => _MBRichEditorToolbarState();
}

class _MBRichEditorToolbarState extends State<MBRichEditorToolbar> {
  final List<String> _activeStates = [];

  @override
  void initState() {
    super.initState();
    widget.controller.onDecorationChange = (states) {
      setState(() {
        _activeStates.clear();
        _activeStates.addAll(states);
      });
    };
  }

  @override
  void didUpdateWidget(MBRichEditorToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.onDecorationChange = null;
      widget.controller.onDecorationChange = (states) {
        setState(() {
          _activeStates.clear();
          _activeStates.addAll(states);
        });
      };
    }
  }

  VoidCallback _createCommand(Future<void> Function() command) {
    return () => command();
  }

  Widget _buildButton(ToolbarButtonDefinition buttonDef) {
    // Determine if button should be active
    final bool isActive =
        buttonDef.decorationState != null &&
        _activeStates.contains(buttonDef.decorationState);

    // Create the command handler
    VoidCallback onPressed;
    switch (buttonDef.id) {
      // Text Formatting
      case 'bold':
        onPressed = _createCommand(() => widget.controller.setBold());
        break;
      case 'italic':
        onPressed = _createCommand(() => widget.controller.setItalic());
        break;
      case 'underline':
        onPressed = _createCommand(() => widget.controller.setUnderline());
        break;
      case 'strikeThrough':
        onPressed = _createCommand(() => widget.controller.setStrikeThrough());
        break;
      case 'subscript':
        onPressed = _createCommand(() => widget.controller.setSubscript());
        break;
      case 'superscript':
        onPressed = _createCommand(() => widget.controller.setSuperscript());
        break;

      // Headings
      case 'heading1':
        onPressed = _createCommand(() => widget.controller.setHeading(1));
        break;
      case 'heading2':
        onPressed = _createCommand(() => widget.controller.setHeading(2));
        break;
      case 'heading3':
        onPressed = _createCommand(() => widget.controller.setHeading(3));
        break;
      case 'heading4':
        onPressed = _createCommand(() => widget.controller.setHeading(4));
        break;
      case 'heading5':
        onPressed = _createCommand(() => widget.controller.setHeading(5));
        break;
      case 'heading6':
        onPressed = _createCommand(() => widget.controller.setHeading(6));
        break;

      // Blocks
      case 'blockquote':
        onPressed = _createCommand(() => widget.controller.setBlockquote());
        break;
      case 'bullets':
        onPressed = _createCommand(() => widget.controller.setBullets());
        break;
      case 'numbers':
        onPressed = _createCommand(() => widget.controller.setNumbers());
        break;

      // Alignment
      case 'alignLeft':
        onPressed = _createCommand(() => widget.controller.setAlignLeft());
        break;
      case 'alignCenter':
        onPressed = _createCommand(() => widget.controller.setAlignCenter());
        break;
      case 'alignRight':
        onPressed = _createCommand(() => widget.controller.setAlignRight());
        break;

      // Indentation
      case 'indent':
        onPressed = _createCommand(() => widget.controller.setIndent());
        break;
      case 'outdent':
        onPressed = _createCommand(() => widget.controller.setOutdent());
        break;

      // Editor Control
      case 'undo':
        onPressed = _createCommand(() => widget.controller.undo());
        break;
      case 'redo':
        onPressed = _createCommand(() => widget.controller.redo());
        break;
      case 'clearFormat':
        onPressed = _createCommand(() => widget.controller.removeFormat());
        break;

      case 'emojiPicker':
        onPressed = widget.onEmojiPicker ?? () {};
        break;

      default:
        onPressed = () {};
    }

    return ToolbarButton(
      icon: buttonDef.icon,
      label: buttonDef.label,
      isActive: isActive,
      onPressed: onPressed,
      iconSize: widget.options.iconSize,
      showLabel: widget.options.showLabels,
      style: widget.options.buttonStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter buttons based on button list
    final buttons = widget.options.buttons
        .where((buttonDef) => widget.options.buttonFilter(buttonDef))
        .map((buttonDef) => _buildButton(buttonDef))
        .toList();

    // Build toolbar based on layout
    final toolbarContent = widget.options.horizontal
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: buttons),
          )
        : SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
          );

    // Apply decoration and padding
    return Container(
      decoration: widget.options.decoration,
      padding: widget.options.padding,
      child: toolbarContent,
    );
  }
}

///
/// Customization options for the RichEditorToolbar.
///
class MBToolbarOptions {
  /// Buttons to display in the toolbar
  final List<ToolbarButtonDefinition> buttons;

  /// Filter function to show/hide specific buttons
  final bool Function(ToolbarButtonDefinition) buttonFilter;

  /// Whether the toolbar is horizontal (default) or vertical
  final bool horizontal;

  /// Decoration for the toolbar container
  final BoxDecoration decoration;

  /// Padding around toolbar buttons
  final EdgeInsets padding;

  /// Spacing between buttons
  final double spacing;

  /// Icon size for buttons
  final double iconSize;

  /// Whether to show labels next to icons
  final bool showLabels;

  /// Custom button style
  final ButtonStyle? buttonStyle;

  const MBToolbarOptions({
    this.buttons = ToolbarButtonDefinition.all,
    this.buttonFilter = _defaultButtonFilter,
    this.horizontal = true,
    this.decoration = const BoxDecoration(
      color: Color(0xFFF5F5F5),
      border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    this.spacing = 0.0,
    this.iconSize = 24.0,
    this.showLabels = false,
    this.buttonStyle,
  });

  /// Default button filter - shows all buttons
  static bool _defaultButtonFilter(ToolbarButtonDefinition button) {
    return true;
  }

  /// Basic preset: only basic text formatting
  static const basic = MBToolbarOptions(
    buttons: ToolbarButtonDefinition.basicTextFormatting,
  );

  /// Default preset: text formatting + blocks + alignment + editor controls
  static const defaultOptions = MBToolbarOptions(
    buttons: [
      ...ToolbarButtonDefinition.editorControls,
      ...ToolbarButtonDefinition.basicTextFormatting,
      ...ToolbarButtonDefinition.blocks,
      ...ToolbarButtonDefinition.alignment,
    ],
  );

  /// Full preset: all available buttons
  static const full = MBToolbarOptions(buttons: ToolbarButtonDefinition.all);

  /// Text only preset: formatting buttons without editor controls
  static const textFormatting = MBToolbarOptions(
    buttons: ToolbarButtonDefinition.advancedTextFormatting,
  );

  /// Minimal preset: only bold, italic, underline
  static const minimal = MBToolbarOptions(
    buttons: [
      ToolbarButtonDefinition.bold,
      ToolbarButtonDefinition.italic,
      ToolbarButtonDefinition.underline,
    ],
  );
}
