import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../emoji/models/emoji.dart';
import '../mention/models/mention.dart';

///
/// Controller for the RichEditor widget.
/// Manages state, executes commands, and handles JavaScript communication.
///
class RichEditorController extends ChangeNotifier {
  WebViewController? _webViewController;
  bool _isReady = false;
  String _html = '';
  final List<String> _activeStates = [];
  Emoji? _currentEmoji;
  Mention? _currentMention;
  String? _mentionTextAtCursor;
  List<Mention> _allMentions = [];

  /// Callback when text changes
  ValueChanged<String>? onTextChange;

  /// Callback when decoration state changes
  ValueChanged<List<String>>? onDecorationChange;

  /// Callback when editor is ready
  VoidCallback? onReady;

  /// Callback when emoji is selected from picker
  ValueChanged<Emoji?>? onEmojiSelected;

  /// Callback when mention trigger is detected
  ValueChanged<String?>? onMentionTrigger;

  /// Callback when mention bottom sheet should be hidden
  VoidCallback? onMentionHide;

  /// Callback when mention is selected
  ValueChanged<String?>? onMentionSelected;

  /// Register the WebView controller
  void registerViewController(WebViewController controller) {
    _webViewController = controller;
  }

  /// Check if the editor is ready
  bool get isReady => _isReady;

  /// Get current HTML content
  String get html => _html;

  /// Get current decoration state
  List<String> get activeStates => List.unmodifiable(_activeStates);

  /// Set HTML result from JavaScript (internal use)
  void setHtmlResult(String html) {
    _html = html;
  }

  /// Set editor ready state
  void setReady(bool ready) {
    _isReady = ready;
    if (ready) {
      onReady?.call();
    }
  }

  /// Update HTML content (called from JavaScript)
  void updateHtml(String html) {
    _html = html;
    onTextChange?.call(html);
  }

  /// Update decoration state (called from JavaScript)
  void updateDecorationState(String stateString) {
    _activeStates.clear();
    if (stateString.isNotEmpty) {
      _activeStates.addAll(stateString.split(','));
    }
    onDecorationChange?.call(_activeStates);
    notifyListeners();
  }

  // ==================== Content Methods ====================

  /// Set HTML content
  Future<void> setHtml(String html) async {
    await _evalJs('RE.setHtml(`${Uri.encodeComponent(html)}`);');
    _html = html;
    onTextChange?.call(html);
  }

  /// Get HTML content
  Future<String> getHtml() async {
    // Execute JavaScript to get HTML and send via channel
    await _evalJs('window.getHtmlResult.postMessage(RE.getHtml());');

    // Wait a bit for the callback to complete
    await Future.delayed(const Duration(milliseconds: 100));

    return _html;
  }

  Future<void> insertHtml(String html) async {
    await _evalJs('RE.insertHTML(`$html`);');
  }

  /// Set placeholder text
  Future<void> setPlaceholder(String placeholder) async {
    await _evalJs('RE.setPlaceholder(\'$placeholder\');');
  }

  // ==================== Text Formatting ====================

  /// Set text bold
  Future<void> setBold() async {
    await _evalJs('RE.setBold();');
  }

  /// Set text italic
  Future<void> setItalic() async {
    await _evalJs('RE.setItalic();');
  }

  /// Set text underline
  Future<void> setUnderline() async {
    await _evalJs('RE.setUnderline();');
  }

  /// Set text strikethrough
  Future<void> setStrikeThrough() async {
    await _evalJs('RE.setStrikeThrough();');
  }

  /// Set text subscript
  Future<void> setSubscript() async {
    await _evalJs('RE.setSubscript();');
  }

  /// Set text superscript
  Future<void> setSuperscript() async {
    await _evalJs('RE.setSuperscript();');
  }

  // ==================== Headings ====================

  /// Set heading level (1-6)
  Future<void> setHeading(int level) async {
    if (level < 1 || level > 6) {
      throw ArgumentError('Heading level must be between 1 and 6');
    }
    await _evalJs('RE.setHeading($level);');
  }

  // ==================== Blocks ====================

  /// Set blockquote
  Future<void> setBlockquote() async {
    await _evalJs('RE.setBlockquote();');
  }

  /// Set bullets (unordered list)
  Future<void> setBullets() async {
    await _evalJs('RE.setBullets();');
  }

  /// Set numbers (ordered list)
  Future<void> setNumbers() async {
    await _evalJs('RE.setNumbers();');
  }

  // ==================== Indentation ====================

  /// Increase indent
  Future<void> setIndent() async {
    await _evalJs('RE.setIndent();');
  }

  /// Decrease indent
  Future<void> setOutdent() async {
    await _evalJs('RE.setOutdent();');
  }

  // ==================== Alignment ====================

  /// Align left
  Future<void> setAlignLeft() async {
    await _evalJs('RE.setJustifyLeft();');
  }

  /// Align center
  Future<void> setAlignCenter() async {
    await _evalJs('RE.setJustifyCenter();');
  }

  /// Align right
  Future<void> setAlignRight() async {
    await _evalJs('RE.setJustifyRight();');
  }

  // ==================== Colors ====================

  /// Set text color (hex string, e.g., '#FF0000')
  Future<void> setTextColor(String color) async {
    await _evalJs('RE.prepareInsert();');
    await _evalJs('RE.setTextColor(\'$color\');');
  }

  /// Set text background color (hex string, e.g., '#FFFF00')
  Future<void> setTextBackgroundColor(String color) async {
    await _evalJs('RE.prepareInsert();');
    await _evalJs('RE.setTextBackgroundColor(\'$color\');');
  }

  // ==================== Font Size ====================

  /// Set font size (1-7)
  Future<void> setFontSize(int size) async {
    if (size < 1 || size > 7) {
      throw ArgumentError('Font size must be between 1 and 7');
    }
    await _evalJs('RE.setFontSize($size);');
  }

  // ==================== Editor Appearance ====================

  /// Set base text color
  Future<void> setEditorFontColor(String color) async {
    await _evalJs('RE.setBaseTextColor(\'$color\');');
  }

  /// Set base font size in pixels
  Future<void> setEditorFontSize(int size) async {
    await _evalJs('RE.setBaseFontSize(\'${size}px\');');
  }

  /// Set editor background color
  Future<void> setEditorBackgroundColor(String color) async {
    await _evalJs('RE.setBackgroundColor(\'$color\');');
  }

  /// Set editor padding
  Future<void> setPadding(int left, int top, int right, int bottom) async {
    await _evalJs(
      'RE.setPadding(\'${left}px\', \'${top}px\', \'${right}px\', \'${bottom}px\');',
    );
  }

  // ==================== Media Insertion ====================

  /// Insert image
  Future<void> insertImage(
    String url, {
    String? alt,
    int? width,
    int? height,
  }) async {
    await _evalJs('RE.prepareInsert();');

    if (width != null && height != null) {
      await _evalJs(
        'RE.insertImageWH(\'$url\', \'${alt ?? ''}\', $width, $height);',
      );
    } else if (width != null) {
      await _evalJs('RE.insertImageW(\'$url\', \'${alt ?? ''}\', $width);');
    } else {
      await _evalJs('RE.insertImage(\'$url\', \'${alt ?? ''}\');');
    }
  }

  /// Insert video
  Future<void> insertVideo(String url, {int? width, int? height}) async {
    await _evalJs('RE.prepareInsert();');

    if (width != null && height != null) {
      await _evalJs('RE.insertVideoWH(\'$url\', $width, $height);');
    } else if (width != null) {
      await _evalJs('RE.insertVideoW(\'$url\', $width);');
    } else {
      await _evalJs('RE.insertVideo(\'$url\');');
    }
  }

  /// Insert audio
  Future<void> insertAudio(String url) async {
    await _evalJs('RE.prepareInsert();');
    await _evalJs('RE.insertAudio(\'$url\');');
  }

  /// Insert YouTube video
  Future<void> insertYoutubeVideo(String url, {int? width, int? height}) async {
    await _evalJs('RE.prepareInsert();');

    if (width != null && height != null) {
      await _evalJs('RE.insertYoutubeVideoWH(\'$url\', $width, $height);');
    } else if (width != null) {
      await _evalJs('RE.insertYoutubeVideoW(\'$url\', $width);');
    } else {
      await _evalJs('RE.insertYoutubeVideo(\'$url\');');
    }
  }

  /// Insert link
  Future<void> insertLink(String href, String title) async {
    await _evalJs('RE.prepareInsert();');
    await _evalJs('RE.insertLink(\'$href\', \'$title\');');
  }

  /// Insert checkbox (todo item)
  Future<void> insertTodo() async {
    await _evalJs('RE.prepareInsert();');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _evalJs('RE.setTodo(\'$timestamp\');');
  }

  // ==================== Emoji Methods ====================

  /// Insert emoji at cursor position
  Future<void> insertEmoji(Emoji emoji) async {
    final emojiJson = jsonEncode(emoji.toJson());
    await _evalJs('RE.insertEmoji($emojiJson);');
  }

  /// Get emoji at cursor position
  Future<Emoji?> getEmojiAtCursor() async {
    await _evalJs(
      'window.getEmojiAtCursor.postMessage(RE.getEmojiAtCursor());',
    );
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentEmoji;
  }

  /// Set current emoji (internal use)
  void setCurrentEmoji(Emoji? emoji) {
    _currentEmoji = emoji;
    onEmojiSelected?.call(emoji);
  }

  // ==================== Mention Methods ====================

  /// Insert mention at cursor position
  Future<void> insertMention(Mention mention) async {
    final mentionJson = jsonEncode(mention.toJson());
    await _evalJs('RE.insertMention($mentionJson);');
  }

  /// Get mention at cursor position
  Future<Mention?> getMentionAtCursor() async {
    await _evalJs(
      'window.getMentionAtCursor.postMessage(RE.getMentionAtCursor());',
    );
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentMention;
  }

  /// Get all mentions in the editor
  Future<List<Mention>> getAllMentions() async {
    await _evalJs('window.getAllMentions.postMessage(RE.getAllMentions());');
    await Future.delayed(const Duration(milliseconds: 100));
    return _allMentions;
  }

  /// Remove mention by user ID
  Future<void> removeMention(String userId) async {
    await _evalJs('RE.removeMention(\'$userId\');');
  }

  /// Update mention by user ID
  Future<void> updateMention(String userId, Mention newMention) async {
    final mentionJson = jsonEncode(newMention.toJson());
    await _evalJs('RE.updateMention(\'$userId\', $mentionJson);');
  }

  /// Get mention text at cursor (e.g., "@username")
  Future<String?> getMentionTextAtCursor() async {
    await _evalJs(
      'window.getMentionTextAtCursor.postMessage(RE.getMentionTextAtCursor());',
    );
    await Future.delayed(const Duration(milliseconds: 100));
    return _mentionTextAtCursor;
  }

  /// Set current mention (internal use)
  void setCurrentMention(Mention? mention) {
    _currentMention = mention;
    onMentionSelected?.call(mention?.user.username);
  }

  /// Set mention text at cursor (internal use)
  void setMentionTextAtCursor(String? text) {
    _mentionTextAtCursor = text;
    onMentionTrigger?.call(text ?? '');
  }

  /// Hide mention bottom sheet (called from JavaScript)
  void hideMentionBottomSheet() {
    onMentionHide?.call();
  }

  /// Set all mentions (internal use)
  void setAllMentions(List<Mention> mentions) {
    _allMentions = mentions;
  }

  // ==================== Editor Control ====================

  /// Undo last action
  Future<void> undo() async {
    await _evalJs('RE.undo();');
  }

  /// Redo last action
  Future<void> redo() async {
    await _evalJs('RE.redo();');
  }

  /// Remove formatting
  Future<void> removeFormat() async {
    await _evalJs('RE.removeFormat();');
  }

  /// Focus the editor
  Future<void> focus() async {
    await _evalJs('RE.focus();');
  }

  /// Blur (unfocus) the editor
  Future<void> blur() async {
    await _evalJs('RE.blurFocus();');
  }

  /// Enable/disable editing
  Future<void> setInputEnabled(bool enabled) async {
    await _evalJs('RE.setInputEnabled($enabled);');
  }

  // ==================== Private Methods ====================

  /// Evaluate JavaScript code
  Future<dynamic> _evalJs(String code) async {
    if (!_isReady || _webViewController == null) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _evalJs(code);
    }

    try {
      await _webViewController!.runJavaScript(code);
      return null;
    } catch (e) {
      debugPrint('Error evaluating JavaScript: $e\nCode: $code');
      rethrow;
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
