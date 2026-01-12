export 'src/core/rich_editor.dart';
export 'src/core/rich_editor_controller.dart';

export 'src/toolbar/rich_editor_toolbar.dart';
export 'src/toolbar/toolbar_button.dart';

export 'src/emoji/models/emoji.dart';
export 'src/emoji/models/emoji_category.dart';
export 'src/emoji/models/emoji_source.dart';
export 'src/emoji/config/emoji_picker_config.dart';
export 'src/emoji/widgets/emoji_picker.dart';

export 'src/mention/models/mention_user.dart';
export 'src/mention/models/mention.dart';
export 'src/mention/models/mention_provider.dart';
export 'src/mention/config/mention_config.dart';
export 'src/mention/widgets/mention_suggestions.dart';
export 'src/mention/providers/static_mention_provider.dart';

// Plugin exports
export 'src/plugin/summernote_plugin.dart';

// Built-in Summernote plugins (ready-to-use)
export 'src/plugin/built_in/smart_blockquote.dart';

// Deprecated plugin exports (will be removed in v2.0.0)
// Use SummernotePlugin for native Summernote plugin support instead
export 'src/plugin/rich_editor_plugin.dart';
export 'src/plugin/mention_plugin.dart';
export 'src/plugin/emoji_plugin.dart';
