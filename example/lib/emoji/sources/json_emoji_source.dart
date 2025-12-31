import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mb_rich_editor/mb_rich_editor.dart';

/// JSON-based emoji source.
///
/// Loads emojis from a JSON file, supporting the existing emoji_voz.json format.
class JsonEmojiSource implements EmojiSource {
  /// Path to the JSON file
  final String jsonPath;

  /// Base URL for emoji images (if emojis are remote)
  final String? baseUrl;

  /// Whether to load emojis on initialization
  final bool preload;

  final List<EmojiCategory> _categories = [];
  final Map<String, Emoji> _emojiByShortcode = {};
  bool _isInitialized = false;

  JsonEmojiSource({required this.jsonPath, this.baseUrl, this.preload = true});

  @override
  Future<List<Emoji>> getRecentEmojis() async => [];

  @override
  Future<List<Emoji>> getFrequentEmojis() async => [];

  @override
  Future<void> trackEmojiUsage(Emoji emoji) async {}

  @override
  EmojiSourceMetadata get metadata => EmojiSourceMetadata(
    name: 'JSON Emoji Source',
    version: '1.0.0',
    isUnicode: false,
    totalEmojis: _categories.fold(0, (sum, cat) => sum + cat.emojis.length),
    totalCategories: _categories.length,
    description: 'Loads emojis from a JSON file',
  );

  @override
  Future<List<EmojiCategory>> loadCategories() async {
    if (_isInitialized) {
      return _categories;
    }

    await initialize();
    return _categories;
  }

  @override
  Future<List<Emoji>> searchEmojis(String query) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (query.isEmpty) {
      return [];
    }

    final lowerQuery = query.toLowerCase();
    final results = <Emoji>[];

    for (final category in _categories) {
      for (final emoji in category.emojis) {
        if (_matchesQuery(emoji, lowerQuery)) {
          results.add(emoji);
        }
      }
    }

    return results;
  }

  @override
  Emoji? getEmojiByShortcode(String shortcode) {
    return _emojiByShortcode[shortcode];
  }

  @override
  Emoji? getEmojiById(String id) {
    for (final category in _categories) {
      for (final emoji in category.emojis) {
        if (emoji.id == id) {
          return emoji;
        }
      }
    }
    return null;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[JsonEmojiSource] Already initialized, skipping');
      return;
    }

    debugPrint('[JsonEmojiSource] Starting initialization from $jsonPath');
    try {
      final jsonString = await rootBundle.loadString(jsonPath);
      debugPrint('[JsonEmojiSource] Loaded JSON string');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse emoji data from JSON
      final emojis =
          (jsonData['emojis'] as List<dynamic>?)
              ?.map((e) => Emoji.fromVozJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      debugPrint('[JsonEmojiSource] Parsed ${emojis.length} emojis');

      // Build shortcode lookup map
      for (final emoji in emojis) {
        if (emoji.shortcodes != null) {
          _emojiByShortcode[emoji.shortcodes!] = emoji;
        }
      }

      // Create categories
      // Group emojis by category if categories are defined in JSON
      final categories = jsonData['categories'] as List<dynamic>?;
      if (categories == null) {
        // No categories defined, create a single "All" category
        _categories.add(EmojiCategory(id: 'all', name: 'All', emojis: emojis));
        debugPrint(
          '[JsonEmojiSource] Created default "All" category with ${emojis.length} emojis',
        );
      } else {
        // Create categories from JSON
        for (final categoryData in categories) {
          final categoryId = categoryData['id'] as String;
          final categoryName = categoryData['name'] as String;
          final categoryEmojis = emojis
              .where((e) => e.category == categoryId)
              .toList();

          _categories.add(
            EmojiCategory(
              id: categoryId,
              name: categoryName,
              emojis: categoryEmojis,
            ),
          );
        }
        debugPrint('[JsonEmojiSource] Created ${categories.length} categories');
      }

      _isInitialized = true;
      debugPrint(
        '[JsonEmojiSource] Initialization complete, _isInitialized = $_isInitialized',
      );
    } catch (e) {
      debugPrint('[JsonEmojiSource] Error loading emoji JSON: $e');
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _categories.clear();
    _emojiByShortcode.clear();
    _isInitialized = false;
  }

  /// Check if an emoji matches the search query
  bool _matchesQuery(Emoji emoji, String lowerQuery) {
    // Check name
    if (emoji.name.toLowerCase().contains(lowerQuery)) {
      return true;
    }

    // Check shortcodes
    if (emoji.shortcodes != null &&
        emoji.shortcodes!.toLowerCase().contains(lowerQuery)) {
      return true;
    }

    // Check keywords
    if (emoji.keywords != null) {
      for (final keyword in emoji.keywords!) {
        if (keyword.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get all emojis from all categories
  List<Emoji> get emojis => _categories.expand((c) => c.emojis).toList();
}
