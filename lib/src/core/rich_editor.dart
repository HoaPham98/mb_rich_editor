import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  late InAppWebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _setupController();
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

  void _registerJavaScriptHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'onTextChange',
      callback: (args) {
        if (args.isNotEmpty) {
          widget.controller.updateHtml(args[0].toString());
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onDecorationState',
      callback: (args) {
        if (args.isNotEmpty) {
          widget.controller.updateDecorationState(args[0].toString());
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'getHtmlResult',
      callback: (args) {
        if (args.isNotEmpty) {
          widget.controller.setHtmlResult(args[0].toString());
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'getMentionAtCursor',
      callback: (args) {
        if (args.isNotEmpty) {
          debugPrint('DEBUG: getMentionAtCursor received: ${args[0]}');
          try {
            final mentionData = jsonDecode(args[0].toString());
            final mention = Mention.fromJson(mentionData);
            widget.controller.setCurrentMention(mention);
          } catch (e) {
            debugPrint('DEBUG: Error parsing mention: $e');
          }
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'getMentionTextAtCursor',
      callback: (args) {
        if (args.isNotEmpty) {
          debugPrint('DEBUG: getMentionTextAtCursor received: ${args[0]}');
          widget.controller.setMentionTextAtCursor(args[0].toString());
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'hideMentionBottomSheet',
      callback: (args) {
        debugPrint('DEBUG: hideMentionBottomSheet called');
        widget.controller.hideMentionBottomSheet();
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'getAllMentions',
      callback: (args) {
        if (args.isNotEmpty) {
          debugPrint('DEBUG: getAllMentions received: ${args[0]}');
          try {
            final List<dynamic> mentionsData = jsonDecode(args[0].toString());
            final mentions = mentionsData
                .map((data) => Mention.fromJson(data))
                .toList();
            widget.controller.setAllMentions(mentions);
          } catch (e) {
            debugPrint('DEBUG: Error parsing mentions: $e');
          }
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onFocus',
      callback: (args) {
        debugPrint('DEBUG: WebView focused');
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onBlur',
      callback: (args) {
        debugPrint('DEBUG: WebView blurred');
      },
    );
  }

  NavigationActionPolicy? _handleUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigation,
  ) {
    final uri = navigation.request.url;

    if (uri != null && uri.scheme == 're-callback') {
      final html = Uri.decodeComponent(uri.path);
      widget.controller.updateHtml(html);
      return NavigationActionPolicy.CANCEL;
    }

    if (uri != null && uri.scheme == 're-state') {
      final state = Uri.decodeComponent(uri.path);
      widget.controller.updateDecorationState(state);
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
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
      child: InAppWebView(
        initialFile: 'packages/mb_rich_editor/assets/rich_editor/index.html',
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          transparentBackground: widget.backgroundColor == null,
          isInspectable: true,
          useHybridComposition: true,
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
          widget.controller.registerViewController(controller);
        },
        onLoadStop: (controller, url) {
          _registerJavaScriptHandlers(controller);
          _applyInitialSettings();
          widget.controller.setReady(true);
        },
        shouldOverrideUrlLoading: (controller, navigation) async =>
            _handleUrlLoading(controller, navigation),
      ),
    );
  }

  Future<void> _applyInitialSettings() async {
    // Apply placeholder
    if (widget.placeholder.isNotEmpty) {
      await _webViewController.evaluateJavascript(
        source: 'RE.setPlaceholder(\'${widget.placeholder}\');',
      );
    }

    // Apply colors
    if (widget.textColor != null) {
      final color =
          '#${widget.textColor!.toARGB32().toRadixString(16).substring(2)}';
      await _webViewController.evaluateJavascript(
        source: 'RE.setBaseTextColor(\'$color\');',
      );
    }

    if (widget.backgroundColor != null) {
      final color =
          '#${widget.backgroundColor!.toARGB32().toRadixString(16).substring(2)}';
      await _webViewController.evaluateJavascript(
        source: 'RE.setBackgroundColor(\'$color\');',
      );
    }

    // Apply font size
    if (widget.fontSize != null) {
      await _webViewController.evaluateJavascript(
        source: 'RE.setBaseFontSize(\'${widget.fontSize}px\');',
      );
    }

    // Apply padding
    if (widget.padding != null) {
      await _webViewController.evaluateJavascript(
        source:
            'RE.setPadding(\'${widget.padding!.left}px\', \'${widget.padding!.top}px\', \'${widget.padding!.right}px\', \'${widget.padding!.bottom}px\');',
      );
    }

    // Set enabled state
    await _webViewController.evaluateJavascript(
      source: 'RE.setInputEnabled(${widget.enabled});',
    );
  }
}
