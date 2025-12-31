import 'package:flutter/material.dart';

/// Configuration for emoji picker behavior.
class EmojiPickerConfig {
  /// Number of columns in the emoji grid
  final int columns;

  /// Number of rows visible at once
  final int rows;

  /// Whether to show search bar
  final bool showSearch;

  /// Whether to show category tabs
  final bool showCategories;

  /// Whether to show frequently used emojis
  final bool showFrequentlyUsed;

  /// Whether to show recently used emojis
  final bool showRecentlyUsed;

  /// List of favorite emoji shortcodes
  final List<String>? favoriteEmojis;

  /// Debounce duration for search queries
  final Duration searchDebounce;

  /// Maximum number of search results
  final int maxSearchResults;

  /// Whether to enable skin tone selector (for Unicode emojis)
  final bool enableSkinToneSelector;

  /// Whether to enable emoji variations (e.g., gender, hair)
  final bool enableVariations;

  /// Whether to animate emoji selection
  final bool animateSelection;

  /// Whether to show emoji count in category
  final bool showEmojiCount;

  /// Whether to allow custom emoji insertion
  final bool allowCustomEmoji;

  /// Maximum number of recent emojis to track
  final int maxRecentEmojis;

  /// Maximum number of frequent emojis to show
  final int maxFrequentEmojis;

  const EmojiPickerConfig({
    this.columns = 8,
    this.rows = 6,
    this.showSearch = true,
    this.showCategories = true,
    this.showFrequentlyUsed = true,
    this.showRecentlyUsed = true,
    this.favoriteEmojis,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.maxSearchResults = 50,
    this.enableSkinToneSelector = false,
    this.enableVariations = false,
    this.animateSelection = true,
    this.showEmojiCount = false,
    this.allowCustomEmoji = false,
    this.maxRecentEmojis = 20,
    this.maxFrequentEmojis = 20,
  });

  /// Default configuration
  static const defaultConfig = EmojiPickerConfig();

  /// Compact configuration for mobile devices
  static const compact = EmojiPickerConfig(
    columns: 6,
    rows: 4,
    showSearch: false,
    showFrequentlyUsed: false,
    showEmojiCount: false,
    showCategories: false,
  );

  /// Full-featured configuration
  static const full = EmojiPickerConfig(
    columns: 10,
    rows: 8,
    showSearch: true,
    showCategories: true,
    showFrequentlyUsed: true,
    showRecentlyUsed: true,
    enableSkinToneSelector: true,
    enableVariations: true,
    animateSelection: true,
    showEmojiCount: true,
  );

  /// Minimal configuration
  static const minimal = EmojiPickerConfig(
    columns: 6,
    rows: 4,
    showSearch: false,
    showCategories: false,
    showFrequentlyUsed: false,
    showRecentlyUsed: false,
    animateSelection: false,
  );

  /// Create a copy of this config with modified values
  EmojiPickerConfig copyWith({
    int? columns,
    int? rows,
    bool? showSearch,
    bool? showCategories,
    bool? showFrequentlyUsed,
    bool? showRecentlyUsed,
    List<String>? favoriteEmojis,
    Duration? searchDebounce,
    int? maxSearchResults,
    bool? enableSkinToneSelector,
    bool? enableVariations,
    bool? animateSelection,
    bool? showEmojiCount,
    bool? allowCustomEmoji,
    int? maxRecentEmojis,
    int? maxFrequentEmojis,
  }) {
    return EmojiPickerConfig(
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      showSearch: showSearch ?? this.showSearch,
      showCategories: showCategories ?? this.showCategories,
      showFrequentlyUsed: showFrequentlyUsed ?? this.showFrequentlyUsed,
      showRecentlyUsed: showRecentlyUsed ?? this.showRecentlyUsed,
      favoriteEmojis: favoriteEmojis ?? this.favoriteEmojis,
      searchDebounce: searchDebounce ?? this.searchDebounce,
      maxSearchResults: maxSearchResults ?? this.maxSearchResults,
      enableSkinToneSelector:
          enableSkinToneSelector ?? this.enableSkinToneSelector,
      enableVariations: enableVariations ?? this.enableVariations,
      animateSelection: animateSelection ?? this.animateSelection,
      showEmojiCount: showEmojiCount ?? this.showEmojiCount,
      allowCustomEmoji: allowCustomEmoji ?? this.allowCustomEmoji,
      maxRecentEmojis: maxRecentEmojis ?? this.maxRecentEmojis,
      maxFrequentEmojis: maxFrequentEmojis ?? this.maxFrequentEmojis,
    );
  }
}

/// Styling for emoji picker.
class EmojiPickerStyle {
  /// Background color of the picker
  final Color backgroundColor;

  /// Color of category tabs
  final Color categoryColor;

  /// Color of selected category
  final Color selectedCategoryColor;

  /// Color of search bar
  final Color searchColor;

  /// Size of emoji in pixels
  final double emojiSize;

  /// Size of category icon in pixels
  final double categoryIconSize;

  /// Decoration for the picker container
  final BoxDecoration decoration;

  /// Padding around the picker content
  final EdgeInsets padding;

  /// Spacing between emojis
  final double emojiSpacing;

  /// Border radius for emoji items
  final BorderRadius emojiBorderRadius;

  /// Border radius for the picker
  final BorderRadius borderRadius;

  /// Elevation of the picker
  final double elevation;

  /// Color of the search bar text
  final Color searchTextColor;

  /// Color of the search bar hint
  final Color searchHintColor;

  /// Color of the divider
  final Color dividerColor;

  EmojiPickerStyle({
    this.backgroundColor = Colors.white,
    this.categoryColor = Colors.grey,
    this.selectedCategoryColor = Colors.blue,
    this.searchColor = const Color(0xFFE0E0E0),
    this.emojiSize = 32.0,
    this.categoryIconSize = 24.0,
    this.decoration = const BoxDecoration(),
    this.padding = const EdgeInsets.all(8.0),
    this.emojiSpacing = 4.0,
    this.emojiBorderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.elevation = 4.0,
    this.searchTextColor = Colors.black,
    this.searchHintColor = Colors.grey,
    this.dividerColor = const Color(0xFFE0E0E0),
  });

  /// Default style
  static final defaultStyle = EmojiPickerStyle();

  /// Dark theme style
  static EmojiPickerStyle dark() => EmojiPickerStyle(
    backgroundColor: const Color(0xFF2C2C2C),
    categoryColor: Colors.grey,
    selectedCategoryColor: Colors.blue,
    searchColor: const Color(0xFF3C3C3C),
    emojiSize: 32.0,
    categoryIconSize: 24.0,
    padding: const EdgeInsets.all(8.0),
    emojiSpacing: 4.0,
    searchTextColor: Colors.white,
    searchHintColor: Colors.grey,
    dividerColor: const Color(0xFF4C4C4C),
  );

  /// Create a copy of this style with modified values
  EmojiPickerStyle copyWith({
    Color? backgroundColor,
    Color? categoryColor,
    Color? selectedCategoryColor,
    Color? searchColor,
    double? emojiSize,
    double? categoryIconSize,
    BoxDecoration? decoration,
    EdgeInsets? padding,
    double? emojiSpacing,
    BorderRadius? emojiBorderRadius,
    BorderRadius? borderRadius,
    double? elevation,
    Color? searchTextColor,
    Color? searchHintColor,
    Color? dividerColor,
  }) {
    return EmojiPickerStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      categoryColor: categoryColor ?? this.categoryColor,
      selectedCategoryColor:
          selectedCategoryColor ?? this.selectedCategoryColor,
      searchColor: searchColor ?? this.searchColor,
      emojiSize: emojiSize ?? this.emojiSize,
      categoryIconSize: categoryIconSize ?? this.categoryIconSize,
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      emojiSpacing: emojiSpacing ?? this.emojiSpacing,
      emojiBorderRadius: emojiBorderRadius ?? this.emojiBorderRadius,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      searchTextColor: searchTextColor ?? this.searchTextColor,
      searchHintColor: searchHintColor ?? this.searchHintColor,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }
}
