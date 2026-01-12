import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'rich_editor_controller.dart';
import '../mention/models/mention.dart';
import '../models/summernote_callbacks.dart';
import '../plugin/summernote_plugin.dart';

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

  /// Whether to use Summernote editor engine (default: true)
  /// Set to false to use the legacy rich_editor implementation
  final bool useSummernote;

  /// Summernote plugins to attach to the editor.
  ///
  /// Plugins can be loaded from:
  /// - CDN URLs (via `SummernotePlugin.fromUrl`)
  /// - Flutter asset bundles (via `SummernotePlugin.fromAsset`)
  /// - Raw JavaScript strings (via `SummernotePlugin.fromCode`)
  ///
  /// Example:
  /// ```dart
  /// plugins: [
  ///   SummernotePlugin.fromUrl(
  ///     'emoji',
  ///     'https://cdn.jsdelivr.net/npm/summernote-emoji/dist/plugin.min.js',
  ///     options: {'emojiPath': '/assets/emoji/'},
  ///     callbacks: {'onSelect': (emoji) => print('Emoji: $emoji')},
  ///   ),
  /// ]
  /// ```
  final List<SummernotePlugin> plugins;

  /// Custom Summernote options to inject at initialization.
  /// Use this for non-callback options like height, toolbar, styling, etc.
  ///
  /// Example:
  /// ```dart
  /// customSummernoteOptions: {
  ///   'height': 300,
  ///   'toolbar': [
  ///     ['style', ['style']],
  ///     ['font', ['bold', 'italic', 'underline']]
  ///   ],
  ///   'fontSizes': ['8', '9', '10', '11', '12', '14', '18', '24', '36'],
  /// }
  /// ```
  final Map<String, dynamic>? customSummernoteOptions;

  /// Custom Summernote callbacks provided as Dart functions.
  /// These are bridged to JavaScript and called when Summernote events occur.
  ///
  /// Example:
  /// ```dart
  /// summernoteCallbacks: SummernoteCallbacks(
  ///   onInit: () => print('Editor ready!'),
  ///   onChange: (contents) => print('Content changed: $contents'),
  ///   onStateChange: (state) => print('Bold: ${state.bold}'),
  /// )
  /// ```
  final SummernoteCallbacks? summernoteCallbacks;

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
    this.useSummernote = true,
    this.plugins = const [],
    this.customSummernoteOptions,
    this.summernoteCallbacks,
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
    final assetPath = widget.useSummernote
        ? 'packages/mb_rich_editor/assets/summernote/index_summernote.html'
        : 'packages/mb_rich_editor/assets/rich_editor/index.html';

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: InAppWebView(
        initialFile: assetPath,
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
        onLoadStop: (controller, url) async {
          _registerJavaScriptHandlers(controller);

          // Step 1: Register Summernote callback handlers BEFORE initialization
          if (widget.summernoteCallbacks != null) {
            await _registerSummernoteCallbackHandlers(controller);
          }

          // Step 2: Initialize Summernote plugins (load scripts, configure options)
          await _initializeSummernotePlugins(controller);

          // Step 3: Merge custom Summernote options (non-callback options)
          if (widget.customSummernoteOptions != null) {
            await _injectCustomSummernoteOptions(controller);
          }

          // Step 4: Initialize Summernote
          if (widget.useSummernote) {
            await controller.evaluateJavascript(source: 'RE.initSummernote();');
          }

          // Step 5: Apply initial settings and mark as ready
          _applyInitialSettings();
          widget.controller.setReady(true);
        },
        shouldOverrideUrlLoading: (controller, navigation) async =>
            _handleUrlLoading(controller, navigation),
      ),
    );
  }

  /// Register JavaScript handlers for Summernote callbacks
  Future<void> _registerSummernoteCallbackHandlers(
    InAppWebViewController controller,
  ) async {
    final callbacks = widget.summernoteCallbacks!;
    final callbackNames = callbacks.providedCallbackNames;

    // Register handler for each provided callback
    for (final name in callbackNames) {
      final handlerName = 'summernote_$name';
      controller.addJavaScriptHandler(
        handlerName: handlerName,
        callback: (args) {
          _handleSummernoteCallback(name, args);
        },
      );
    }

    // Notify JS which callbacks are available
    await controller.evaluateJavascript(
      source:
          'window.availableSummernoteCallbacks = ${jsonEncode(callbackNames)};',
    );
  }

  /// Handle incoming Summernote callback from JavaScript
  void _handleSummernoteCallback(String callbackName, List<dynamic> args) {
    final callbacks = widget.summernoteCallbacks!;

    switch (callbackName) {
      case 'onInit':
        callbacks.onInit?.call();
        break;
      case 'onChange':
        if (args.isNotEmpty) {
          callbacks.onChange?.call(args[0].toString());
        }
        break;
      case 'onBlur':
        callbacks.onBlur?.call();
        break;
      case 'onFocus':
        callbacks.onFocus?.call();
        break;
      case 'onKeydown':
        if (args.isNotEmpty && args[0] is Map) {
          callbacks.onKeydown?.call(Map<String, dynamic>.from(args[0] as Map));
        }
        break;
      case 'onKeyup':
        if (args.isNotEmpty && args[0] is Map) {
          callbacks.onKeyup?.call(Map<String, dynamic>.from(args[0] as Map));
        }
        break;
      case 'onPaste':
        if (args.isNotEmpty && args[0] is Map) {
          callbacks.onPaste?.call(Map<String, dynamic>.from(args[0] as Map));
        }
        break;
      case 'onImageUpload':
        if (args.isNotEmpty) {
          final files = (args[0] as List).map((e) => e.toString()).toList();
          callbacks.onImageUpload?.call(files);
        }
        break;
      case 'onEnter':
        callbacks.onEnter?.call();
        break;
      case 'onLanguage':
        if (args.isNotEmpty) {
          final locale = args[0].toString();
          callbacks.onLanguage?.call(locale);
        }
        break;
      case 'onStateChange':
        if (args.isNotEmpty && args[0] is Map) {
          final stateMap = Map<String, dynamic>.from(args[0] as Map);
          final toolbarState = SummernoteToolbarState.fromMap(stateMap);
          callbacks.onStateChange?.call(toolbarState);
        }
        break;
    }
  }

  /// Inject custom Summernote options before initialization
  Future<void> _injectCustomSummernoteOptions(
    InAppWebViewController controller,
  ) async {
    if (widget.customSummernoteOptions == null) return;

    try {
      final jsonString = jsonEncode(widget.customSummernoteOptions);
      await controller.evaluateJavascript(
        source: 'window.customSummernoteOptions = $jsonString;',
      );
    } catch (e) {
      debugPrint('Error injecting custom Summernote options: $e');
    }
  }

  /// Initialize all Summernote plugins before editor initialization.
  ///
  /// This method:
  /// 1. Registers Dart handlers for plugin callbacks
  /// 2. Loads plugin scripts from URL, asset, or raw code
  /// 3. Configures plugin options and language strings
  Future<void> _initializeSummernotePlugins(
    InAppWebViewController controller,
  ) async {
    for (final plugin in widget.plugins) {
      // Step 1: Register Dart handlers for plugin callbacks
      if (plugin.callbacks != null) {
        plugin.callbacks!.forEach((callbackName, _) {
          final handlerName = 'plugin_${plugin.pluginName}_$callbackName';
          controller.addJavaScriptHandler(
            handlerName: handlerName,
            callback: (args) {
              final data = args.isNotEmpty ? args[0] : null;
              plugin.callbacks![callbackName]?.call(data);
            },
          );
        });
      }

      // Step 2: Load plugin script
      if (plugin.scriptUrl != null) {
        await controller.evaluateJavascript(
          source:
              'RE.loadSummernotePluginFromUrl("${plugin.pluginName}", "${plugin.scriptUrl}")',
        );
      } else if (plugin.assetPath != null) {
        final assetContent = await rootBundle.loadString(plugin.assetPath!);
        final escapedContent = _escapeJavaScript(assetContent);
        await controller.evaluateJavascript(
          source:
              'RE.loadSummernotePluginFromAsset("${plugin.pluginName}", `$escapedContent`)',
        );
      } else if (plugin.rawJavaScript != null) {
        final escapedCode = _escapeJavaScript(plugin.rawJavaScript!);
        await controller.evaluateJavascript(
          source:
              'RE.loadSummernotePluginFromCode("${plugin.pluginName}", `$escapedCode`)',
        );
      }

      // Step 3: Configure plugin options
      if (plugin.options.isNotEmpty) {
        final optionsJson = jsonEncode(plugin.options);
        await controller.evaluateJavascript(
          source:
              'RE.configureSummernotePlugin("${plugin.pluginName}", $optionsJson)',
        );
      }

      // Step 4: Configure language strings
      if (plugin.language != null) {
        plugin.language!.forEach((langCode, strings) {
          final stringsJson = jsonEncode(strings);
          controller.evaluateJavascript(
            source:
                'RE.configureSummernotePluginLang("$langCode", "${plugin.pluginName}", $stringsJson)',
          );
        });
      }
    }
  }

  /// Escape a string for safe use in JavaScript.
  String _escapeJavaScript(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t')
        .replaceAll('\$', '\\\$')
        .replaceAll('/', '\\/');
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
