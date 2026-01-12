import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../core/rich_editor_controller.dart';

/// Base class for RichEditor plugins.
///
/// Plugins can inject JavaScript handlers and receive callbacks from the editor.
/// This allows for extensible functionality like mentions and emojis without
/// modifying the core editor code.
///
/// Example usage:
/// ```dart
/// class MyPlugin extends RichEditorPlugin {
///   @override
///   String get id => 'my_plugin';
///
///   @override
///   String get javascriptToInject => '''
///     RE.myCustomMethod = function() { ... };
///   ''';
///
///   @override
///   List<String> get handlerNames => ['myHandler'];
///
///   @override
///   void onHandlerCalled(String handlerName, dynamic args) {
///     // Handle callback from JS
///   }
/// }
/// ```
abstract class RichEditorPlugin {
  RichEditorController? _controller;

  /// Unique identifier for this plugin
  String get id;

  /// JavaScript code to inject into the editor.
  /// This runs after Summernote is initialized.
  String get javascriptToInject;

  /// Handler names this plugin registers.
  /// Each handler will be registered with flutter_inappwebview and
  /// will call [onHandlerCalled] when invoked from JavaScript.
  List<String> get handlerNames;

  /// Called when a JavaScript handler receives data.
  ///
  /// [handlerName] is one of the names from [handlerNames].
  /// [args] is the data passed from JavaScript.
  void onHandlerCalled(String handlerName, dynamic args);

  /// Called when the plugin is attached to an editor.
  ///
  /// Use this to set up any state or callbacks needed.
  void onAttach(RichEditorController controller) {
    _controller = controller;
  }

  /// Called when the plugin is detached from the editor.
  ///
  /// Use this to clean up any resources.
  void onDetach() {
    _controller = null;
  }

  /// Get the attached controller, if any.
  RichEditorController? get controller => _controller;

  /// Register this plugin's JavaScript handlers with the WebView controller.
  void registerHandlers(InAppWebViewController webController) {
    for (final handlerName in handlerNames) {
      webController.addJavaScriptHandler(
        handlerName: handlerName,
        callback: (args) {
          onHandlerCalled(handlerName, args.isNotEmpty ? args[0] : null);
        },
      );
    }
  }

  /// Inject this plugin's JavaScript into the WebView.
  Future<void> injectJavaScript(InAppWebViewController webController) async {
    if (javascriptToInject.isNotEmpty) {
      await webController.evaluateJavascript(source: javascriptToInject);
    }
  }
}
