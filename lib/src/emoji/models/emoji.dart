import 'package:flutter/material.dart';

/// Represents a single emoji.
class Emoji {
  /// Unique identifier for the emoji
  final String id;

  /// Display name of the emoji
  final String name;

  /// Shortcodes for the emoji (e.g., ":smile:", ":)")
  final String? shortcodes;

  /// Unicode character for the emoji
  final String? unicode;

  /// URL to the emoji image (for custom emoji)
  final String? imageUrl;

  /// Category this emoji belongs to
  final String category;

  /// Search keywords for finding this emoji
  final List<String>? keywords;

  /// Additional metadata for the emoji
  final Map<String, dynamic>? metadata;

  const Emoji({
    required this.id,
    required this.name,
    this.shortcodes,
    this.unicode,
    this.imageUrl,
    required this.category,
    this.keywords,
    this.metadata,
  });

  /// Check if this is a Unicode emoji
  bool get isUnicode => unicode != null && unicode!.isNotEmpty;

  /// Check if this is an image-based emoji
  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Get the display text for this emoji
  String get displayText => unicode ?? (imageUrl != null ? '🖼️' : '');

  /// Create an Emoji from JSON
  factory Emoji.fromJson(Map<String, dynamic> json) {
    return Emoji(
      id: json['id'] as String,
      name: json['name'] as String,
      shortcodes: json['shortcodes'] as String?,
      unicode: json['unicode'] as String?,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String,
      keywords: (json['keywords'] as List<dynamic>?)?.cast<String>(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert this Emoji to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortcodes': shortcodes,
      'unicode': unicode,
      'imageUrl': imageUrl,
      'category': category,
      'keywords': keywords,
      'metadata': metadata,
    };
  }

  /// Create an Emoji from the existing JSON format (emoji_voz.json)
  factory Emoji.fromVozJson(Map<String, dynamic> json) {
    return Emoji(
      id: json['emoji_alt'] as String? ?? '',
      name: json['emoji_name'] as String? ?? '',
      shortcodes: json['emoji_alt'] as String?,
      unicode: null,
      imageUrl: json['emoji_url'] as String?,
      category: 'custom',
      keywords: [
        json['emoji_name'] as String? ?? '',
        json['emoji_alt'] as String? ?? '',
      ],
      metadata: {'alt': json['emoji_alt'] as String?},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Emoji && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Emoji(id: $id, name: $name, unicode: $unicode, imageUrl: $imageUrl)';
  }
}

/// Configuration for emoji display
class EmojiDisplayConfig {
  /// Size of the emoji in pixels
  final double size;

  /// Whether to show shortcodes as tooltips
  final bool showShortcodes;

  /// Whether to show tooltips
  final bool showTooltip;

  /// Padding around the emoji
  final EdgeInsets padding;

  /// Decoration for the emoji container
  final BoxDecoration decoration;

  /// Whether to animate the emoji on selection
  final bool animateOnSelection;

  const EmojiDisplayConfig({
    this.size = 32.0,
    this.showShortcodes = false,
    this.showTooltip = true,
    this.padding = const EdgeInsets.all(4.0),
    this.decoration = const BoxDecoration(),
    this.animateOnSelection = false,
  });

  /// Default configuration
  static const defaultConfig = EmojiDisplayConfig();

  /// Compact configuration (smaller size)
  static const compact = EmojiDisplayConfig(
    size: 24.0,
    padding: EdgeInsets.all(2.0),
  );

  /// Large configuration (larger size)
  static const large = EmojiDisplayConfig(
    size: 48.0,
    padding: EdgeInsets.all(8.0),
  );
}
