import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'rich_editor_controller.dart';
import '../mention/models/mention.dart';

///
/// A WebView-based rich text editor for Flutter.
///
/// Example usage:
/// ```dart
/// final controller = RichEditorController();
///
/// RichEditor(
///   controller: controller,
///   height: 300,
///   placeholder: 'Start typing...',
///   onTextChange: (html) => print(html),
/// )
/// ```
///
class RichEditor extends StatefulWidget {
  /// Controller for this editor
  final RichEditorController controller;

  /// Height of the editor
  final double? height;

  /// Width of the editor
  final double? width;

  /// Placeholder text when editor is empty
  final String placeholder;

  /// Background color of the editor
  final Color? backgroundColor;

  /// Text color of the editor
  final Color? textColor;

  /// Base font size in pixels
  final int? fontSize;

  /// Padding around the editor content
  final EdgeInsets? padding;

  /// Whether to enable user input
  final bool enabled;

  /// Callback when text content changes
  final ValueChanged<String>? onTextChange;

  /// Callback when decoration state changes (e.g., bold, italic active)
  final ValueChanged<List<String>>? onDecorationChange;

  /// Callback when editor is ready
  final VoidCallback? onReady;

  /// Auto-focus the editor when it's ready
  final bool autoFocus;

  const RichEditor({
    super.key,
    required this.controller,
    this.height,
    this.width,
    this.placeholder = 'Enter text here...',
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.enabled = true,
    this.onTextChange,
    this.onDecorationChange,
    this.onReady,
    this.autoFocus = false,
  });

  @override
  State<RichEditor> createState() => _RichEditorState();
}

class _RichEditorState extends State<RichEditor> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _setupController();
    _initWebViewController();
  }

  void _setupController() {
    widget.controller.onTextChange = (html) {
      widget.onTextChange?.call(html);
    };

    widget.controller.onDecorationChange = (states) {
      widget.onDecorationChange?.call(states);
    };

    widget.controller.onReady = () {
      widget.onReady?.call();
      if (widget.autoFocus) {
        widget.controller.focus();
      }
    };
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor ?? Colors.transparent)
      ..addJavaScriptChannel(
        'onTextChange',
        onMessageReceived: (JavaScriptMessage message) {
          widget.controller.updateHtml(message.message);
        },
      )
      ..addJavaScriptChannel(
        'onDecorationState',
        onMessageReceived: (JavaScriptMessage message) {
          widget.controller.updateDecorationState(message.message);
        },
      )
      ..addJavaScriptChannel(
        'getHtmlResult',
        onMessageReceived: (JavaScriptMessage message) {
          widget.controller.setHtmlResult(message.message);
        },
      )
      ..addJavaScriptChannel(
        'getMentionAtCursor',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('DEBUG: getMentionAtCursor received: ${message.message}');
          // Parse and set mention
          if (message.message.isNotEmpty) {
            try {
              final mentionData = jsonDecode(message.message);
              final mention = Mention.fromJson(mentionData);
              widget.controller.setCurrentMention(mention);
            } catch (e) {
              debugPrint('DEBUG: Error parsing mention: $e');
            }
          }
        },
      )
      ..addJavaScriptChannel(
        'getMentionTextAtCursor',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint(
            'DEBUG: getMentionTextAtCursor received: ${message.message}',
          );
          widget.controller.setMentionTextAtCursor(message.message);
        },
      )
      ..addJavaScriptChannel(
        'hideMentionBottomSheet',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('DEBUG: hideMentionBottomSheet called');
          widget.controller.hideMentionBottomSheet();
        },
      )
      ..addJavaScriptChannel(
        'getAllMentions',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('DEBUG: getAllMentions received: ${message.message}');
          if (message.message.isNotEmpty) {
            try {
              final List<dynamic> mentionsData = jsonDecode(message.message);
              final mentions = mentionsData
                  .map((data) => Mention.fromJson(data))
                  .toList();
              widget.controller.setAllMentions(mentions);
            } catch (e) {
              debugPrint('DEBUG: Error parsing mentions: $e');
            }
          }
        },
      )
      ..addJavaScriptChannel(
        'onFocus',
        onMessageReceived: (JavaScriptMessage message) {
          // Notify external listeners if needed, but do not steal focus
          // to the ghost text field as this breaks WebView input
          debugPrint('DEBUG: WebView focused');
        },
      )
      ..addJavaScriptChannel(
        'onBlur',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('DEBUG: WebView blurred');
        },
      )
      ..loadFlutterAsset(
        'packages/mb_rich_editor/assets/rich_editor/index.html',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _applyInitialSettings();
            widget.controller.setReady(true);
          },
          onNavigationRequest: (NavigationRequest navigation) {
            final uri = Uri.parse(navigation.url);

            // Handle text change callback via URL scheme
            if (uri.scheme == 're-callback') {
              final html = Uri.decodeComponent(uri.path);
              widget.controller.updateHtml(html);
              return NavigationDecision.prevent;
            }

            // Handle decoration state callback via URL scheme
            if (uri.scheme == 're-state') {
              final state = Uri.decodeComponent(uri.path);
              widget.controller.updateDecorationState(state);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // Register with the controller
    widget.controller.registerViewController(_webViewController);
  }

  @override
  void didUpdateWidget(RichEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _setupController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: WebViewWidget(controller: _webViewController),
    );
  }

  Future<void> _applyInitialSettings() async {
    // Apply placeholder
    if (widget.placeholder.isNotEmpty) {
      await _webViewController.runJavaScript(
        'RE.setPlaceholder(\'${widget.placeholder}\');',
      );
    }

    // Apply colors
    if (widget.textColor != null) {
      final color =
          '#${widget.textColor!.toARGB32().toRadixString(16).substring(2)}';
      await _webViewController.runJavaScript(
        'RE.setBaseTextColor(\'$color\');',
      );
    }

    if (widget.backgroundColor != null) {
      final color =
          '#${widget.backgroundColor!.toARGB32().toRadixString(16).substring(2)}';
      await _webViewController.runJavaScript(
        'RE.setBackgroundColor(\'$color\');',
      );
    }

    // Apply font size
    if (widget.fontSize != null) {
      await _webViewController.runJavaScript(
        'RE.setBaseFontSize(\'${widget.fontSize}px\');',
      );
    }

    // Apply padding
    if (widget.padding != null) {
      await _webViewController.runJavaScript(
        'RE.setPadding(\'${widget.padding!.left}px\', \'${widget.padding!.top}px\', \'${widget.padding!.right}px\', \'${widget.padding!.bottom}px\');',
      );
    }

    // Set enabled state
    await _webViewController.runJavaScript(
      'RE.setInputEnabled(${widget.enabled});',
    );
  }
}
