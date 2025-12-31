import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mb_rich_editor/mb_rich_editor.dart' as mb;

import 'package:keyboard_detection/keyboard_detection.dart';
import 'package:mb_rich_editor/mb_rich_editor.dart';

import 'emoji/sources/json_emoji_source.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MB Rich Editor Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RichEditorExample(),
    );
  }
}

class RichEditorExample extends StatefulWidget {
  const RichEditorExample({super.key});

  @override
  State<RichEditorExample> createState() => _RichEditorExampleState();
}

class _RichEditorExampleState extends State<RichEditorExample> {
  late final mb.RichEditorController _controller;
  late final JsonEmojiSource _emojiSource;
  late final mb.StaticMentionProvider _mentionProvider;
  late final KeyboardDetectionController _keyboardDetectionController;

  // Visual state
  bool _isBottomSheetOpen = false;
  String _currentHtml = '';
  List<String> _activeStates = [];
  bool _useBuiltInToolbar = false;

  // Keyboard & Emoji state
  double _keyboardHeight = 0;
  bool _isEmojiVisible = false;
  bool _isKeyboardVisible = false;

  // Default height if keyboard hasn't been shown yet
  static const double _kDefaultKeyboardHeight = 250.0;
  double _savedKeyboardHeight = _kDefaultKeyboardHeight;

  @override
  void initState() {
    super.initState();
    _keyboardDetectionController = KeyboardDetectionController(
      onChanged: (state) {
        setState(() {
          _isKeyboardVisible = state == KeyboardState.visible;
          if (_isKeyboardVisible) {
            _keyboardHeight = _keyboardDetectionController.size;
            _savedKeyboardHeight = _keyboardHeight;
          }
        });
      },
    );
    // Ensure size is loaded (accessing the property/future)
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
          role: 'Admin',
        ),
        mb.MentionUser(
          id: '2',
          username: 'jane_smith',
          displayName: 'Jane Smith',
          avatarUrl: 'https://i.pravatar.cc/150?u=2',
          role: 'Moderator',
        ),
        mb.MentionUser(
          id: '3',
          username: 'bob_wilson',
          displayName: 'Bob Wilson',
          avatarUrl: 'https://i.pravatar.cc/150?u=3',
          role: 'User',
        ),
        mb.MentionUser(
          id: '4',
          username: 'alice_johnson',
          displayName: 'Alice Johnson',
          avatarUrl: 'https://i.pravatar.cc/150?u=4',
          role: 'User',
        ),
        mb.MentionUser(
          id: '5',
          username: 'charlie_brown',
          displayName: 'Charlie Brown',
          avatarUrl: 'https://i.pravatar.cc/150?u=5',
          role: 'User',
        ),
      ],
    );

    // Set up emoji callback
    _controller.onEmojiSelected = (emoji) {
      if (emoji != null) {
        _controller.insertEmoji(emoji);
      }
    };

    // Set up mention callbacks
    _controller.onMentionTrigger = (text) {
      // Trigger mention suggestions when @ is detected
      if (text != null && text.isNotEmpty) {
        print('Mention trigger: $text');
        // Only show bottom sheet if it's not already open
        if (!_isBottomSheetOpen) {
          _showMentionSuggestionsBottomSheet();
        }
      }
    };

    _controller.onMentionHide = () {
      // Hide mention bottom sheet
      if (_isBottomSheetOpen) {
        print('Hiding mention bottom sheet');
        _isBottomSheetOpen = false;
        Navigator.of(context).pop();
      }
    };

    _controller.onMentionSelected = (username) {
      if (username != null) {
        print('Mention selected: $username');
        Navigator.of(context).pop();
      }
    };

    // Subscribe to decoration state changes for button active states
    _controller.onDecorationChange = (states) {
      setState(() {
        _activeStates.clear();
        _activeStates.addAll(states);
      });
    };

    // Load initial HTML content from assets
    _loadInitialHtml();
  }

  Future<void> _loadInitialHtml() async {
    try {
      final htmlContent = await rootBundle.loadString('assets/sample.html');
      _controller.setHtml(htmlContent);
    } catch (e) {
      print('Failed to load initial HTML: $e');
    }
  }

  @override
  void dispose() {
    _controller.onDecorationChange = null;
    _controller.dispose();
    _emojiSource.dispose();
    _mentionProvider.dispose();
    super.dispose();
  }

  void _onEmojiButtonTapped() {
    setState(() {
      if (_isKeyboardVisible) {
        // Case: Keyboard is showing.
        // Action: Hide keyboard, show emoji picker (logic variable).
        // The picker should already be "behind" the keyboard, so this transition reveals it.
        _controller.blur();
        _isEmojiVisible = true;
      } else {
        // Case: Keyboard is hidden.
        if (_isEmojiVisible) {
          // Emoji is showing -> hide it.
          _controller.focus();
          _isEmojiVisible = false;
        } else {
          // Everything closed -> show emoji.
          _isEmojiVisible = true;
          // Note: Logic says "When picker appears, default height 250" if no saved height?
          // We use _savedKeyboardHeight which initiates at 250.
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the height of the bottom spacer (Toolbar + Picker/Keyboard placeholder)
    // If keyboard is visible, we use its height.
    // If emoji is visible (and keyboard hidden), we use saved height.
    // If neither, 0 (plus safe area).

    final double bottomAreaHeight = (_isKeyboardVisible || _isEmojiVisible)
        ? _savedKeyboardHeight
        : 0.0;

    return KeyboardDetection(
      controller: _keyboardDetectionController,
      child: Scaffold(
        resizeToAvoidBottomInset:
            false, // Essential for custom keyboard/toolbar
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Rich Editor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () =>
                  setState(() => _useBuiltInToolbar = !_useBuiltInToolbar),
              tooltip: 'Switch Toolbar',
            ),
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: () => _showHtmlOutput(),
              tooltip: 'View HTML',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The Main Content
                  Positioned.fill(
                    bottom:
                        bottomAreaHeight +
                        56.0, // Reserve space for toolbar (56.0) + keyboard/picker
                    child: mb.RichEditor(
                      controller: _controller,
                      placeholder: 'Start typing...',
                      padding: EdgeInsets.all(16.0),
                      // height is now controlled by layout
                      onTextChange: (html) {
                        setState(() {
                          _currentHtml = html;
                        });
                      },
                    ),
                  ),

                  // Toolbar & Picker Area
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Toolbar always sits above the keyboard/picker area
                        _buildToolbar(),

                        // The Picker / Placeholder Area
                        SizedBox(
                          height: bottomAreaHeight,
                          child: _isEmojiVisible || _isKeyboardVisible
                              ? SingleChildScrollView(
                                  // Use SingleChildScrollView to prevent overflow if keyboard > picker
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: _savedKeyboardHeight,
                                    child: _buildEmojiPicker(),
                                  ),
                                )
                              : null,
                        ),
                        // Add safe area spacing if nothing is showing
                        if (!_isKeyboardVisible && !_isEmojiVisible)
                          SizedBox(
                            height: MediaQuery.of(context).viewPadding.bottom,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return mb.MBRichEditorToolbar(
      controller: _controller,
      options: const mb.MBToolbarOptions(
        buttons: [
          mb.ToolbarButtonDefinition.emojiPicker,
          ...mb.ToolbarButtonDefinition.basicTextFormatting,
          ...mb.ToolbarButtonDefinition.blocks,
          ...mb.ToolbarButtonDefinition.alignment,
        ],
      ),
      onEmojiPicker: _onEmojiButtonTapped,
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiPicker(
      emojiSource: _emojiSource,
      config: EmojiPickerConfig.compact,
      style: EmojiPickerStyle(),
      onEmojiSelected: (emoji) {
        _controller.insertEmoji(emoji);
      },
    );
  }

  void _showMentionSuggestionsBottomSheet() {
    print('DEBUG: _showMentionSuggestionsBottomSheet called');
    _isBottomSheetOpen = true;
    showModalBottomSheet<mb.MentionUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      builder: (context) {
        print('DEBUG: Bottom sheet builder called');
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.6,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mention Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _isBottomSheetOpen = false;
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildSimpleMentionSuggestions()),
                ],
              ),
            ),
          ),
        );
      },
    ).then((user) {
      if (user != null) {
        _controller.insertMention(mb.Mention.text(user: user));
      }
      _isBottomSheetOpen = false;
    });
  }

  Widget _buildSimpleMentionSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _mentionProvider.users.length,
      itemBuilder: (context, index) {
        final user = _mentionProvider.users[index];
        return InkWell(
          onTap: () {
            print('Selected user: ${user.username}');
            _isBottomSheetOpen = false;
            Navigator.of(context).pop(user);
          },
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                _buildAvatar(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.displayName ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(mb.MentionUser user) {
    if (user.avatarUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(user.avatarUrl!),
        backgroundColor: Colors.grey.shade300,
      );
    } else {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          _getInitials(user.displayName ?? '?'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _showHtmlOutput() {
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
          if (_currentHtml.isNotEmpty)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _currentHtml));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('HTML copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
        ],
      ),
    );
  }
}
