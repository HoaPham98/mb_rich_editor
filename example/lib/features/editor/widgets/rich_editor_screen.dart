import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_detection/keyboard_detection.dart';
import 'package:mb_rich_editor/mb_rich_editor.dart' as mb;
import '../../../emoji/sources/json_emoji_source.dart';
import '../controllers/editor_ui_state.dart';
import 'editor_bottom_panel.dart';
import 'editor_toolbar.dart';
import 'mention_sheet.dart';

class RichEditorScreen extends StatefulWidget {
  const RichEditorScreen({super.key});

  @override
  State<RichEditorScreen> createState() => _RichEditorScreenState();
}

class _RichEditorScreenState extends State<RichEditorScreen> {
  late final mb.RichEditorController _controller;
  late final JsonEmojiSource _emojiSource;
  late final mb.StaticMentionProvider _mentionProvider;
  late final KeyboardDetectionController _keyboardDetectionController;
  late final EditorUIState _uiState;

  // Visual state
  bool _isBottomSheetOpen = false;
  String _currentHtml = '';
  // ignore: unused_field
  List<String> _activeStates = [];
  bool _useBuiltInToolbar = false;

  @override
  void initState() {
    super.initState();
    _uiState = EditorUIState();

    _keyboardDetectionController = KeyboardDetectionController(
      onChanged: (state) {
        // Update UI state with keyboard info
        final isVisible = state == KeyboardState.visible;
        final height = _keyboardDetectionController.size;

        if (isVisible) {
          _uiState.updateKeyboardHeight(height);
          _uiState.showKeyboard();
        } else {
          // Check if this was a manual dismiss before closing
          if (_uiState.isKeyboardVisible && !_uiState.isManualDismiss) {
            // Only close if user dismissed keyboard (not code)
            _uiState.closeBottomAttachment();
          }
          // If manual dismiss, do nothing - emoji stays visible
        }
      },
    );
    _keyboardDetectionController.ensureSizeLoaded;

    _controller = mb.RichEditorController();
    _emojiSource = JsonEmojiSource(jsonPath: 'assets/emoji_voz.json');
    _mentionProvider = mb.StaticMentionProvider(
      users: [
        mb.MentionUser(
          id: '1',
          username: 'john_doe',
          displayName: 'John Doe',
          avatarUrl: 'https://i.pravatar.cc/150?u=1',
        ),
        mb.MentionUser(
          id: '2',
          username: 'jane_smith',
          displayName: 'Jane Smith',
          avatarUrl: 'https://i.pravatar.cc/150?u=2',
        ),
        // ... add more if needed
      ],
    );

    _setupControllerCallbacks();
    // _loadInitialHtml();
  }

  void _setupControllerCallbacks() {
    _controller.onEmojiSelected = (emoji) {
      if (emoji != null) _controller.insertEmoji(emoji);
    };

    _controller.onMentionTrigger = (text) {
      if (text != null && text.isNotEmpty && !_isBottomSheetOpen) {
        _showMentionSuggestions();
      }
    };

    _controller.onMentionHide = () {
      if (_isBottomSheetOpen) {
        _isBottomSheetOpen = false;
        Navigator.of(context).pop();
      }
    };

    _controller.onMentionSelected = (username) {
      if (username != null) {
        Navigator.of(context).pop();
      }
    };

    _controller.onDecorationChange = (states) {
      setState(() {
        _activeStates.clear();
        _activeStates.addAll(states);
      });
    };
  }

  Future<void> _loadInitialHtml() async {
    try {
      final htmlContent = await rootBundle.loadString('assets/sample.html');
      _controller.setHtml(htmlContent);
    } catch (e) {
      print('Failed to load initial HTML: $e');
    }
  }

  void _showMentionSuggestions() {
    _isBottomSheetOpen = true;
    MentionSheet.show(context, _mentionProvider.users).then((user) {
      if (user != null) {
        _controller.insertMention(mb.Mention.text(user: user));
      }
      _isBottomSheetOpen = false;
    });
  }

  void _onEmojiButtonTapped() {
    if (_uiState.isKeyboardVisible) {
      // Mark as manual dismiss BEFORE calling blur()
      _uiState.markManualDismiss();
      _controller.blur();
      _uiState.showEmojiPicker();
    } else {
      if (_uiState.isEmojiVisible) {
        // Don't call showKeyboard() here - let keyboard listener handle it
        // to avoid double rebuild and flicker
        _controller.focus();
        // Keyboard showing will trigger listener to update state to keyboard
      } else {
        _uiState.showEmojiPicker();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emojiSource.dispose();
    _mentionProvider.dispose();
    _uiState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDetection(
      controller: _keyboardDetectionController,
      child: AnimatedBuilder(
        animation: _uiState,
        builder: (context, _) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: const Text('Rich Editor (Refactored)'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () =>
                      setState(() => _useBuiltInToolbar = !_useBuiltInToolbar),
                ),
                IconButton(
                  icon: const Icon(Icons.code),
                  onPressed: () => _showHtmlOutput(),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        bottom: _uiState.bottomAreaHeight + 56.0,
                        child: mb.RichEditor(
                          controller: _controller,
                          placeholder: 'Start typing...',
                          customSummernoteOptions: {
                            'blockquoteBreakingLevel': 1,
                          },
                          padding: const EdgeInsets.all(16.0),
                          onTextChange: (html) {
                            _currentHtml = html;
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EditorToolbar(
                              controller: _controller,
                              onEmojiPicker: _onEmojiButtonTapped,
                            ),
                            EditorBottomPanel(
                              uiState: _uiState,
                              emojiSource: _emojiSource,
                              onEmojiSelected: (emoji) =>
                                  _controller.insertEmoji(emoji),
                            ),
                            if (_uiState.activeAttachment ==
                                BottomAttachment.none)
                              SizedBox(
                                height: MediaQuery.of(
                                  context,
                                ).viewPadding.bottom,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHtmlOutput() {
    // ... same as before ...
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HTML Output'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              _currentHtml.isEmpty ? '<Empty>' : _currentHtml,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _currentHtml.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ==================== EXAMPLE USAGE ====================
//
// Below are examples of how to use the new custom Summernote options and callbacks:
//
// Example 1: Basic styling options
// ```dart
// mb.RichEditor(
//   controller: _controller,
//   customSummernoteOptions: {
//     'height': 400,
//     'minHeight': 200,
//     'placeholder': 'Write your story...',
//     'fontSizes': ['8', '9', '10', '11', '12', '14', '18', '24', '36'],
//   },
// )
// ```
//
// Example 2: Custom toolbar
// ```dart
// mb.RichEditor(
//   controller: _controller,
//   customSummernoteOptions: {
//     'toolbar': [
//       ['style', ['style']],
//       ['font', ['bold', 'italic', 'underline', 'clear']],
//       ['fontsize', ['fontsize']],
//       ['color', ['color']],
//       ['para', ['ul', 'ol', 'paragraph']],
//       ['insert', ['link', 'picture', 'video']],
//       ['view', ['fullscreen', 'codeview']],
//     ],
//   },
// )
// ```
//
// Example 3: Dart callbacks (full Dart customization)
// ```dart
// mb.RichEditor(
//   controller: _controller,
//   summernoteCallbacks: mb.SummernoteCallbacks(
//     onInit: () {
//       print('Editor is ready!');
//       // Can trigger UI updates, show notifications, etc.
//     },
//     onChange: (contents) {
//       print('Content changed, length: ${contents.length}');
//       // Can trigger auto-save, word count update, etc.
//     },
//     onFocus: () {
//       print('Editor focused');
//       // Can show keyboard, custom toolbar, etc.
//     },
//     onBlur: () {
//       print('Editor blurred');
//       // Can hide keyboard, save state, etc.
//     },
//     onPaste: (event) {
//       print('Pasted: key=${event['key']}');
//       // Can sanitize paste, show custom dialog, etc.
//     },
//     onKeydown: (event) {
//       if (event['key'] == 'Enter') {
//         print('Enter pressed');
//         // Can handle custom Enter behavior
//       }
//     },
//     onStateChange: (state) {
//       // Receive toolbar state changes as typed object
//       print('Bold enabled: ${state.bold}');
//       print('Italic enabled: ${state.italic}');
//       print('Underline enabled: ${state.underline}');
//       print('OrderedList enabled: ${state.orderedList}');
//       print('UnorderedList enabled: ${state.unorderedList}');
//       print('Format block: ${state.formatBlock}');
//       print('Is heading: ${state.isHeading}');
//       print('Heading level: ${state.headingLevel}');
//       print('Any formatting: ${state.hasAnyFormatting}');
//       // Can update custom toolbar UI, enable/disable buttons, etc.
//     },
//   ),
// )
// ```
//
// Example 4: Combined - options + callbacks
// ```dart
// mb.RichEditor(
//   controller: _controller,
//   customSummernoteOptions: {
//     'height': 300,
//     'dialogsInBody': true,
//   },
//   summernoteCallbacks: mb.SummernoteCallbacks(
//     onInit: () => print('Ready'),
//     onChange: (contents) => print('Changed: ${contents.length} chars'),
//     onStateChange: (state) {
//       // Update custom toolbar button states using typed object
//       setState(() {
//         isBold = state.bold;
//         isItalic = state.italic;
//         isUnderline = state.underline;
//         hasList = state.hasList;
//         hasAlignment = state.hasAlignment;
//       });
//     },
//   ),
// )
// ```
//
// Example 5: Using SummernoteToolbarState helper methods
// ```dart
// onStateChange: (state) {
//   // Type-safe access with IDE autocomplete
//   if (state.bold) {
//     // Bold button should be highlighted
//   }
//   if (state.hasList) {
//     // Disable indent buttons
//   }
//   if (state.isHeading) {
//     // Show heading level in toolbar
//     print('Current heading: H${state.headingLevel}');
//   }
//   if (state.isBlockquote) {
//     // Highlight quote button
//   }
//   if (state.formatBlock == 'pre') {
//     // Show code block indicator
//   }
// }
// ```
