import 'mention_user.dart';

/// Format for rendering mentions.
enum MentionFormat {
  /// Plain text: @username
  text,

  /// HTML link: <a href="...">@username</a>
  link,

  /// Custom HTML template
  customHtml,

  /// Custom Flutter widget
  customWidget,
}

/// Represents a mention inserted in the editor.
class Mention {
  /// The user being mentioned
  final MentionUser user;

  /// The trigger character (e.g., '@')
  final String trigger;

  /// The format for rendering this mention
  final MentionFormat format;

  /// Custom HTML template (used when format is customHtml)
  final String? customHtmlTemplate;

  /// Additional attributes for the mention element
  final Map<String, dynamic>? attributes;

  const Mention({
    required this.user,
    required this.trigger,
    required this.format,
    this.customHtmlTemplate,
    this.attributes,
  });

  /// Create a text mention
  factory Mention.text({required MentionUser user, String trigger = '@'}) {
    return Mention(user: user, trigger: trigger, format: MentionFormat.text);
  }

  /// Create a link mention
  factory Mention.link({
    required MentionUser user,
    String trigger = '@',
    String? baseUrl,
  }) {
    return Mention(
      user: user,
      trigger: trigger,
      format: MentionFormat.link,
      attributes: {
        'href': baseUrl != null ? '$baseUrl/${user.id}' : null,
        'class': 'mention',
        'data-user-id': user.id,
        'data-username': user.username,
      },
    );
  }

  /// Create a custom HTML mention
  factory Mention.customHtml({
    required MentionUser user,
    required String htmlTemplate,
    String trigger = '@',
    Map<String, dynamic>? attributes,
  }) {
    return Mention(
      user: user,
      trigger: trigger,
      format: MentionFormat.customHtml,
      customHtmlTemplate: htmlTemplate,
      attributes: attributes,
    );
  }

  /// Get the display text for this mention
  String get displayText => '$trigger${user.username}';

  /// Create a Mention from JSON
  factory Mention.fromJson(Map<String, dynamic> json) {
    return Mention(
      user: MentionUser.fromJson(json['user'] as Map<String, dynamic>),
      trigger: json['trigger'] as String,
      format: MentionFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => MentionFormat.text,
      ),
      customHtmlTemplate: json['customHtmlTemplate'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>?,
    );
  }

  /// Convert this Mention to JSON
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'trigger': trigger,
      'format': format.name,
      'customHtmlTemplate': customHtmlTemplate,
      'attributes': attributes,
    };
  }

  /// Generate HTML for this mention
  String toHtml() {
    switch (format) {
      case MentionFormat.text:
        return displayText;

      case MentionFormat.link:
        final href = attributes?['href'] as String?;
        final className = attributes?['class'] as String? ?? 'mention';
        final userId = attributes?['data-user-id'] as String? ?? user.id;
        final username =
            attributes?['data-username'] as String? ?? user.username;
        return '<a href="$href" class="$className" data-user-id="$userId" data-username="$username">$displayText</a>';

      case MentionFormat.customHtml:
        if (customHtmlTemplate == null) {
          return displayText;
        }
        return _replaceTemplateVariables(customHtmlTemplate!);

      case MentionFormat.customWidget:
        // Custom widgets are handled in Flutter layer
        return displayText;
    }
  }

  /// Replace template variables in custom HTML
  String _replaceTemplateVariables(String template) {
    return template
        .replaceAll('{trigger}', trigger)
        .replaceAll('{username}', user.username)
        .replaceAll('{displayName}', user.displayName ?? user.username)
        .replaceAll('{userId}', user.id)
        .replaceAll('{avatarUrl}', user.avatarUrl ?? '')
        .replaceAll('{role}', user.role ?? '');
  }

  /// Create a copy of this mention with modified values
  Mention copyWith({
    MentionUser? user,
    String? trigger,
    MentionFormat? format,
    String? customHtmlTemplate,
    Map<String, dynamic>? attributes,
  }) {
    return Mention(
      user: user ?? this.user,
      trigger: trigger ?? this.trigger,
      format: format ?? this.format,
      customHtmlTemplate: customHtmlTemplate ?? this.customHtmlTemplate,
      attributes: attributes ?? this.attributes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mention &&
          runtimeType == other.runtimeType &&
          user.id == other.user.id &&
          trigger == other.trigger;

  @override
  int get hashCode => user.id.hashCode ^ trigger.hashCode;

  @override
  String toString() {
    return 'Mention(user: $user, trigger: $trigger, format: $format)';
  }
}
