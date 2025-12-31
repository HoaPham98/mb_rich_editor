# MB Rich Editor

A highly customizable WebView-based rich text editor for Flutter with integrated toolbar, emoji picker, and mention support. Ported from the popular [richeditor-android](https://github.com/wasabeef/richeditor-android) library.

## Features

### Text Formatting
- **Bold**, *Italic*, <u>Underline</u>, ~~Strikethrough~~
- Subscript and Superscript
- Headings (H1-H6)
- Font sizes (1-7 scale)

### Block Elements
- Ordered and unordered lists
- Blockquotes
- Indentation (increase/decrease)

### Text Alignment
- Left, Center, Right alignment

### Colors & Styling
- Text color
- Text background color (highlight)
- Editor background color
- Custom font size
- Custom padding

### Media Insertion
- Images (with width/height control)
- Videos (with width/height control)
- Audio files
- YouTube embeds
- Hyperlinks
- Checkboxes (todo items)

### Emoji Support
- Built-in emoji picker with customizable UI
- Support for custom emoji sources (JSON, API, Unicode)
- Emoji search and categories
- Recent and frequently used emojis

### Mention Support
- @-mention trigger with customizable suggestions
- Multiple mention providers (static, API, Firestore)
- Custom mention formats (text, link, custom HTML)
- Avatar and role display in suggestions

### Built-in Toolbar
- Pre-built customizable toolbar with 20+ buttons
- Multiple preset configurations (minimal, basic, default, full)
- Custom button styling and layouts
- Active state tracking for formatting buttons

### Editor Control
- Undo/Redo
- Focus/blur control
- Enable/disable editing
- Clear formatting

### Real-time Callbacks
- Text change listener (returns HTML)
- Decoration state listener (tracks active formatting)
- Ready state listener
- Emoji selection callback
- Mention trigger/hide/select callbacks

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  mb_rich_editor: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Example

```dart
import 'package:mb_rich_editor/mb_rich_editor.dart';

class MyEditor extends StatefulWidget {
  @override
  State<MyEditor> createState() => _MyEditorState();
}

class _MyEditorState extends State<MyEditor> {
  final controller = RichEditorController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichEditor(
          controller: controller,
          height: 300,
          placeholder: 'Start typing...',
          onTextChange: (html) {
            print('HTML changed: $html');
          },
          onDecorationChange: (states) {
            print('Active states: $states');
          },
        ),

        // Control buttons
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.format_bold),
              onPressed: () => controller.setBold(),
            ),
            IconButton(
              icon: Icon(Icons.format_italic),
              onPressed: () => controller.setItalic(),
            ),
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: () => controller.undo(),
            ),
          ],
        ),
      ],
    );
  }
}
```

### Using the Built-in Toolbar

The package includes a highly customizable toolbar widget:

```dart
// Basic toolbar with default options
MBRichEditorToolbar(
  controller: controller,
)

// Customized toolbar
MBRichEditorToolbar(
  controller: controller,
  options: MBToolbarOptions(
    buttons: [
      ToolbarButtonDefinition.bold,
      ToolbarButtonDefinition.italic,
      ToolbarButtonDefinition.underline,
      ToolbarButtonDefinition.bullets,
      ToolbarButtonDefinition.numbers,
      ToolbarButtonDefinition.emojiPicker,
    ],
    horizontal: true,
    decoration: BoxDecoration(
      color: Colors.grey[100],
      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
    ),
    iconSize: 24,
    showLabels: false,
  ),
  onEmojiPicker: () {
    // Show emoji picker
  },
)
```

#### Toolbar Presets

```dart
// Minimal - only bold, italic, underline
MBRichEditorToolbar(
  controller: controller,
  options: MBToolbarOptions.minimal,
)

// Basic - text formatting
MBRichEditorToolbar(
  controller: controller,
  options: MBToolbarOptions.basic,
)

// Default - text + blocks + alignment + controls
MBRichEditorToolbar(
  controller: controller,
  options: MBToolbarOptions.defaultOptions,
)

// Full - all available buttons
MBRichEditorToolbar(
  controller: controller,
  options: MBToolbarOptions.full,
)
```

#### Available Toolbar Buttons

```dart
// Text Formatting
ToolbarButtonDefinition.bold
ToolbarButtonDefinition.italic
ToolbarButtonDefinition.underline
ToolbarButtonDefinition.strikeThrough
ToolbarButtonDefinition.subscript
ToolbarButtonDefinition.superscript

// Headings
ToolbarButtonDefinition.heading1
ToolbarButtonDefinition.heading2
ToolbarButtonDefinition.heading3
ToolbarButtonDefinition.heading4
ToolbarButtonDefinition.heading5
ToolbarButtonDefinition.heading6

// Blocks
ToolbarButtonDefinition.blockquote
ToolbarButtonDefinition.bullets
ToolbarButtonDefinition.numbers

// Alignment
ToolbarButtonDefinition.alignLeft
ToolbarButtonDefinition.alignCenter
ToolbarButtonDefinition.alignRight

// Indentation
ToolbarButtonDefinition.indent
ToolbarButtonDefinition.outdent

// Editor Control
ToolbarButtonDefinition.undo
ToolbarButtonDefinition.redo
ToolbarButtonDefinition.clearFormat

// Special
ToolbarButtonDefinition.emojiPicker
ToolbarButtonDefinition.mention
```

### Emoji Picker

The built-in emoji picker with customizable configuration:

```dart
// Create emoji source
final emojiSource = JsonEmojiSource(jsonPath: 'assets/emoji.json');

// Use emoji picker
EmojiPicker(
  emojiSource: emojiSource,
  config: EmojiPickerConfig(
    columns: 8,
    rows: 6,
    showSearch: true,
    showCategories: true,
  ),
  style: EmojiPickerStyle(
    backgroundColor: Colors.white,
    emojiSize: 32,
  ),
  onEmojiSelected: (emoji) {
    controller.insertEmoji(emoji);
  },
)
```

#### Emoji Picker Presets

```dart
// Default
EmojiPickerConfig.defaultConfig

// Compact for mobile
EmojiPickerConfig.compact

// Full-featured
EmojiPickerConfig.full

// Minimal
EmojiPickerConfig.minimal
```

#### Creating Custom Emoji Source

```dart
class CustomEmojiSource extends EmojiSource {
  @override
  Future<List<EmojiCategory>> loadCategories() async {
    // Load your emoji data
    return categories;
  }

  @override
  EmojiSourceMetadata get metadata {
    return EmojiSourceMetadata(
      name: 'My Custom Emojis',
      version: '1.0.0',
      isUnicode: false,
      totalEmojis: 100,
      totalCategories: 5,
    );
  }
}
```

### Mention Support

Add @-mention functionality with custom providers:

```dart
// Create mention provider
final mentionProvider = StaticMentionProvider(
  users: [
    MentionUser(
      id: '1',
      username: 'john_doe',
      displayName: 'John Doe',
      avatarUrl: 'https://example.com/avatar1.jpg',
      role: 'Admin',
    ),
    MentionUser(
      id: '2',
      username: 'jane_smith',
      displayName: 'Jane Smith',
      avatarUrl: 'https://example.com/avatar2.jpg',
    ),
  ],
);

// Set up mention callbacks
controller.onMentionTrigger = (text) {
  // Show mention suggestions when @ is detected
  showModalBottomSheet(
    context: context,
    builder: (context) => MentionSuggestions(
      mentionProvider: mentionProvider,
      query: text,
      onUserSelected: (user) {
        controller.insertMention(Mention.text(user: user));
        Navigator.pop(context);
      },
    ),
  );
};

controller.onMentionHide = () {
  // Hide mention suggestions
  Navigator.pop(context);
};
```

#### Mention Configuration

```dart
MentionConfig(
  trigger: '@',
  minLength: 1,
  maxResults: 10,
  showAvatars: true,
  showRoles: true,
  highlightMatches: true,
  searchDebounce: Duration(milliseconds: 300),
)

// Presets
MentionConfig.defaultConfig
MentionConfig.minimal
MentionConfig.full
```

#### Mention Formats

```dart
// Plain text: @username
Mention.text(user: user)

// HTML link: <a href="/users/1">@john_doe</a>
Mention.link(user: user, baseUrl: '/users')

// Custom HTML
Mention.customHtml(
  user: user,
  htmlTemplate: '<span class="mention" data-id="{userId}">{displayName}</span>',
)
```

#### Creating Custom Mention Provider

```dart
class ApiMentionProvider extends MentionProvider {
  final String apiUrl;
  final String apiKey;

  ApiMentionProvider({required this.apiUrl, required this.apiKey});

  @override
  Future<List<MentionUser>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$apiUrl/users?q=$query'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    final data = jsonDecode(response.body);
    return (data['users'] as List)
        .map((json) => MentionUser.fromJson(json))
        .toList();
  }

  @override
  MentionProviderMetadata get metadata {
    return MentionProviderMetadata(
      name: 'API Users',
      trigger: '@',
      maxResults: 10,
    );
  }
}
```

### Getting HTML Content

```dart
// Get current HTML
String html = await controller.getHtml();

// Set HTML content
await controller.setHtml('<p>Hello <b>World</b></p>');
```

### Formatting Commands

```dart
// Text formatting
await controller.setBold();
await controller.setItalic();
await controller.setUnderline();
await controller.setStrikeThrough();

// Headings
await controller.setHeading(1); // H1-H6

// Lists
await controller.setBullets();    // Unordered list
await controller.setNumbers();    // Ordered list

// Alignment
await controller.setAlignLeft();
await controller.setAlignCenter();
await controller.setAlignRight();

// Colors
await controller.setTextColor('#FF0000');
await controller.setTextBackgroundColor('#FFFF00');
```

### Inserting Media

```dart
// Insert image
await controller.insertImage(
  'https://example.com/image.jpg',
  alt: 'Description',
  width: 200,
  height: 150,
);

// Insert video
await controller.insertVideo(
  'https://example.com/video.mp4',
  width: 320,
);

// Insert YouTube video
await controller.insertYoutubeVideo(
  'https://www.youtube.com/embed/VIDEO_ID',
  width: 560,
  height: 315,
);

// Insert link
await controller.insertLink(
  'https://example.com',
  'Link Text',
);

// Insert checkbox
await controller.insertTodo();
```

### Customizing Editor Appearance

```dart
RichEditor(
  controller: controller,
  height: 400,
  width: double.infinity,
  placeholder: 'Write something amazing...',
  backgroundColor: Colors.white,
  textColor: Colors.black,
  fontSize: 16,
  padding: EdgeInsets.all(16),
  enabled: true,
  autoFocus: false,
)
```

### Tracking Active Formatting

The `onDecorationChange` callback returns a list of currently active formatting states:

```dart
RichEditor(
  controller: controller,
  onDecorationChange: (states) {
    setState(() {
      _activeStates = states;
      // states contains: ['bold', 'italic', 'justifyLeft', etc.]
    });
  },
)
```

## Platform Support

- Android
- iOS
- Web

## Architecture

This package uses a **hybrid architecture**:

- **Core editing**: WebView with HTML contenteditable
- **JavaScript bridge**: Bidirectional communication between Dart and JavaScript
- **Flutter UI**: Native Flutter widgets for toolbar, emoji picker, and mentions

This approach provides:

- Feature parity with web-based rich editors
- Consistent behavior across platforms
- Familiar `document.execCommand` API for formatting
- Highly customizable Flutter UI layer

## Customization

The library is designed for extensive customization:

| Component | Customization Options |
|-----------|---------------------|
| **Toolbar** | Button selection, layout, styling, presets |
| **Emoji Picker** | Config, Style, custom sources, custom builders |
| **Mentions** | Config, Style, custom providers, formats |
| **Editor** | Colors, fonts, padding, placeholder |

## Notes

- This package uses `document.execCommand` for formatting, which is deprecated but still widely supported
- The editor is based on the successful richeditor-android library
- WebView performance may vary across devices
- Consider debouncing text change callbacks for better performance

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Acknowledgments

- Based on [richeditor-android](https://github.com/wasabeef/richeditor-android) by Wasabeef
- Uses [webview_flutter](https://pub.dev/packages/webview_flutter) for WebView integration
- CSS normalization from [normalize.css](https://github.com/necolas/normalize.css)
