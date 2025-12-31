import 'package:flutter/material.dart';
import 'emoji.dart';

/// Represents an emoji category.
class EmojiCategory {
  /// Unique identifier for the category
  final String id;

  /// Display name of the category
  final String name;

  /// Icon for the category
  final IconData? icon;

  /// List of emojis in this category
  final List<Emoji> emojis;

  /// Whether this category is shown by default
  final bool isDefault;

  /// Sort order (lower values appear first)
  final int sortOrder;

  const EmojiCategory({
    required this.id,
    required this.name,
    this.icon,
    required this.emojis,
    this.isDefault = true,
    this.sortOrder = 0,
  });

  /// Create an EmojiCategory from JSON
  factory EmojiCategory.fromJson(Map<String, dynamic> json) {
    return EmojiCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['iconCodePoint'] != null
          ? IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons')
          : null,
      emojis: (json['emojis'] as List<dynamic>)
          .map((e) => Emoji.fromJson(e as Map<String, dynamic>))
          .toList(),
      isDefault: json['isDefault'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  /// Convert this EmojiCategory to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon?.codePoint,
      'emojis': emojis.map((e) => e.toJson()).toList(),
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  /// Get the total number of emojis in this category
  int get emojiCount => emojis.length;

  /// Create a copy of this category with different emojis
  EmojiCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    List<Emoji>? emojis,
    bool? isDefault,
    int? sortOrder,
  }) {
    return EmojiCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      emojis: emojis ?? this.emojis,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmojiCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EmojiCategory(id: $id, name: $name, emojiCount: $emojiCount)';
  }
}

/// Common emoji categories
class EmojiCategories {
  /// Smiley and people emojis
  static const smileysAndPeople = EmojiCategory(
    id: 'smileys_people',
    name: 'Smileys & People',
    icon: Icons.sentiment_satisfied,
    emojis: [],
    sortOrder: 1,
  );

  /// Animals and nature emojis
  static const animalsAndNature = EmojiCategory(
    id: 'animals_nature',
    name: 'Animals & Nature',
    icon: Icons.pets,
    emojis: [],
    sortOrder: 2,
  );

  /// Food and drink emojis
  static const foodAndDrink = EmojiCategory(
    id: 'food_drink',
    name: 'Food & Drink',
    icon: Icons.restaurant,
    emojis: [],
    sortOrder: 3,
  );

  /// Activities emojis
  static const activities = EmojiCategory(
    id: 'activities',
    name: 'Activities',
    icon: Icons.sports_soccer,
    emojis: [],
    sortOrder: 4,
  );

  /// Travel and places emojis
  static const travelAndPlaces = EmojiCategory(
    id: 'travel_places',
    name: 'Travel & Places',
    icon: Icons.flight,
    emojis: [],
    sortOrder: 5,
  );

  /// Objects emojis
  static const objects = EmojiCategory(
    id: 'objects',
    name: 'Objects',
    icon: Icons.category,
    emojis: [],
    sortOrder: 6,
  );

  /// Symbols emojis
  static const symbols = EmojiCategory(
    id: 'symbols',
    name: 'Symbols',
    icon: Icons.tag,
    emojis: [],
    sortOrder: 7,
  );

  /// Flags emojis
  static const flags = EmojiCategory(
    id: 'flags',
    name: 'Flags',
    icon: Icons.flag,
    emojis: [],
    sortOrder: 8,
  );

  /// Custom emoji category
  static const custom = EmojiCategory(
    id: 'custom',
    name: 'Custom',
    icon: Icons.extension,
    emojis: [],
    sortOrder: 9,
  );

  /// Default category list
  static const List<EmojiCategory> defaultCategories = [
    smileysAndPeople,
    animalsAndNature,
    foodAndDrink,
    activities,
    travelAndPlaces,
    objects,
    symbols,
    flags,
  ];

  /// All categories including custom
  static const List<EmojiCategory> allCategories = [
    ...defaultCategories,
    custom,
  ];
}
