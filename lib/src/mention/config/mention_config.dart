import 'package:flutter/material.dart';
import '../models/mention.dart';

/// Configuration for mention behavior.
class MentionConfig {
  /// The trigger character (e.g., '@')
  final String trigger;

  /// Minimum number of characters before showing suggestions
  final int minLength;

  /// Maximum number of results to show
  final int maxResults;

  /// Whether to require a space before the trigger
  final bool requireSpaceBefore;

  /// Whether to allow multiple mentions in a row
  final bool allowMultiple;

  /// The default format for mentions
  final MentionFormat defaultFormat;

  /// Base URL for mention links (used with MentionFormat.link)
  final String? linkBaseUrl;

  /// Whether to show avatars in suggestions
  final bool showAvatars;

  /// Whether to show user roles
  final bool showRoles;

  /// Whether to show additional metadata
  final bool showMetadata;

  /// Debounce duration for search queries
  final Duration searchDebounce;

  /// Whether to highlight the matching text in suggestions
  final bool highlightMatches;

  /// Color for highlighting matches
  final Color? highlightColor;

  /// Whether to auto-select first result
  final bool autoSelectFirst;

  /// Whether to close suggestions on selection
  final bool closeOnSelection;

  /// Whether to show empty state message
  final bool showEmptyState;

  /// Message to show when no results are found
  final String emptyStateMessage;

  const MentionConfig({
    this.trigger = '@',
    this.minLength = 1,
    this.maxResults = 10,
    this.requireSpaceBefore = false,
    this.allowMultiple = true,
    this.defaultFormat = MentionFormat.link,
    this.linkBaseUrl,
    this.showAvatars = true,
    this.showRoles = false,
    this.showMetadata = false,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.highlightMatches = true,
    this.highlightColor,
    this.autoSelectFirst = true,
    this.closeOnSelection = true,
    this.showEmptyState = true,
    this.emptyStateMessage = 'No users found',
  });

  /// Default configuration
  static const defaultConfig = MentionConfig();

  /// Minimal configuration
  static const minimal = MentionConfig(
    showAvatars: false,
    showRoles: false,
    showMetadata: false,
    highlightMatches: false,
    showEmptyState: false,
  );

  /// Full-featured configuration
  static const full = MentionConfig(
    minLength: 1,
    maxResults: 15,
    showAvatars: true,
    showRoles: true,
    showMetadata: true,
    highlightMatches: true,
    autoSelectFirst: true,
    closeOnSelection: true,
    showEmptyState: true,
  );

  /// Create a copy of this config with modified values
  MentionConfig copyWith({
    String? trigger,
    int? minLength,
    int? maxResults,
    bool? requireSpaceBefore,
    bool? allowMultiple,
    MentionFormat? defaultFormat,
    String? linkBaseUrl,
    bool? showAvatars,
    bool? showRoles,
    bool? showMetadata,
    Duration? searchDebounce,
    bool? highlightMatches,
    Color? highlightColor,
    bool? autoSelectFirst,
    bool? closeOnSelection,
    bool? showEmptyState,
    String? emptyStateMessage,
  }) {
    return MentionConfig(
      trigger: trigger ?? this.trigger,
      minLength: minLength ?? this.minLength,
      maxResults: maxResults ?? this.maxResults,
      requireSpaceBefore: requireSpaceBefore ?? this.requireSpaceBefore,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      linkBaseUrl: linkBaseUrl ?? this.linkBaseUrl,
      showAvatars: showAvatars ?? this.showAvatars,
      showRoles: showRoles ?? this.showRoles,
      showMetadata: showMetadata ?? this.showMetadata,
      searchDebounce: searchDebounce ?? this.searchDebounce,
      highlightMatches: highlightMatches ?? this.highlightMatches,
      highlightColor: highlightColor ?? this.highlightColor,
      autoSelectFirst: autoSelectFirst ?? this.autoSelectFirst,
      closeOnSelection: closeOnSelection ?? this.closeOnSelection,
      showEmptyState: showEmptyState ?? this.showEmptyState,
      emptyStateMessage: emptyStateMessage ?? this.emptyStateMessage,
    );
  }
}

/// Styling for mention suggestions.
class MentionSuggestionsStyle {
  /// Background color of suggestions list
  final Color backgroundColor;

  /// Color of highlighted text
  final Color highlightColor;

  /// Color of user text
  final Color textColor;

  /// Color of username text
  final Color usernameColor;

  /// Color of role text
  final Color roleColor;

  /// Size of avatar in pixels
  final double avatarSize;

  /// Decoration for the suggestions container
  final BoxDecoration decoration;

  /// Padding around suggestions
  final EdgeInsets padding;

  /// Border radius for suggestion items
  final BorderRadius itemBorderRadius;

  /// Elevation of the suggestions
  final double elevation;

  /// Color of the divider between items
  final Color dividerColor;

  /// Color of the empty state message
  final Color emptyStateColor;

  /// Font size for username
  final double usernameFontSize;

  /// Font size for role
  final double roleFontSize;

  MentionSuggestionsStyle({
    this.backgroundColor = Colors.white,
    this.highlightColor = Colors.blue,
    this.textColor = Colors.black87,
    this.usernameColor = Colors.black87,
    this.roleColor = Colors.grey,
    this.avatarSize = 32.0,
    this.decoration = const BoxDecoration(),
    this.padding = const EdgeInsets.all(8.0),
    this.itemBorderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.elevation = 4.0,
    this.dividerColor = const Color(0xFFE0E0E0),
    this.emptyStateColor = Colors.grey,
    this.usernameFontSize = 14.0,
    this.roleFontSize = 12.0,
  });

  /// Default style
  static MentionSuggestionsStyle defaultStyle() => MentionSuggestionsStyle();

  /// Dark theme style
  static MentionSuggestionsStyle dark() => MentionSuggestionsStyle(
    backgroundColor: const Color(0xFF2C2C2C),
    highlightColor: Colors.blue,
    textColor: Colors.white70,
    usernameColor: Colors.white,
    roleColor: Colors.grey,
    decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
    dividerColor: const Color(0xFF4C4C4C),
    emptyStateColor: Colors.grey,
  );

  /// Create a copy of this style with modified values
  MentionSuggestionsStyle copyWith({
    Color? backgroundColor,
    Color? highlightColor,
    Color? textColor,
    Color? usernameColor,
    Color? roleColor,
    double? avatarSize,
    BoxDecoration? decoration,
    EdgeInsets? padding,
    BorderRadius? itemBorderRadius,
    double? elevation,
    Color? dividerColor,
    Color? emptyStateColor,
    double? usernameFontSize,
    double? roleFontSize,
  }) {
    return MentionSuggestionsStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      highlightColor: highlightColor ?? this.highlightColor,
      textColor: textColor ?? this.textColor,
      usernameColor: usernameColor ?? this.usernameColor,
      roleColor: roleColor ?? this.roleColor,
      avatarSize: avatarSize ?? this.avatarSize,
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      itemBorderRadius: itemBorderRadius ?? this.itemBorderRadius,
      elevation: elevation ?? this.elevation,
      dividerColor: dividerColor ?? this.dividerColor,
      emptyStateColor: emptyStateColor ?? this.emptyStateColor,
      usernameFontSize: usernameFontSize ?? this.usernameFontSize,
      roleFontSize: roleFontSize ?? this.roleFontSize,
    );
  }
}
