import 'emoji.dart';
import 'emoji_category.dart';

/// Metadata about an emoji source.
class EmojiSourceMetadata {
  /// Name of the emoji source
  final String name;

  /// Version of the emoji source
  final String version;

  /// Whether this source uses Unicode emojis
  final bool isUnicode;

  /// Total number of emojis in the source
  final int totalEmojis;

  /// Total number of categories
  final int totalCategories;

  /// Description of the emoji source
  final String? description;

  /// URL for more information about the source
  final String? infoUrl;

  const EmojiSourceMetadata({
    required this.name,
    required this.version,
    required this.isUnicode,
    required this.totalEmojis,
    required this.totalCategories,
    this.description,
    this.infoUrl,
  });

  /// Create metadata from JSON
  factory EmojiSourceMetadata.fromJson(Map<String, dynamic> json) {
    return EmojiSourceMetadata(
      name: json['name'] as String,
      version: json['version'] as String,
      isUnicode: json['isUnicode'] as bool,
      totalEmojis: json['totalEmojis'] as int,
      totalCategories: json['totalCategories'] as int,
      description: json['description'] as String?,
      infoUrl: json['infoUrl'] as String?,
    );
  }

  /// Convert metadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'isUnicode': isUnicode,
      'totalEmojis': totalEmojis,
      'totalCategories': totalCategories,
      'description': description,
      'infoUrl': infoUrl,
    };
  }

  @override
  String toString() {
    return 'EmojiSourceMetadata(name: $name, version: $version, isUnicode: $isUnicode)';
  }
}

/// Abstract interface for emoji data sources.
///
/// Implement this interface to provide custom emoji sources for the emoji picker.
/// The library provides several built-in implementations:
/// - [UnicodeEmojiSource]: Uses system Unicode emojis
/// - [JsonEmojiSource]: Loads emojis from a JSON file
/// - [RemoteEmojiSource]: Fetches emojis from a remote API
/// - [CustomEmojiSource]: Allows you to provide custom emoji data
abstract class EmojiSource {
  /// Load all emoji categories from this source.
  ///
  /// This method is called when the emoji picker is first initialized.
  /// Implementations should cache the results for better performance.
  Future<List<EmojiCategory>> loadCategories();

  /// Search emojis by query string.
  ///
  /// The query is matched against emoji names, shortcodes, and keywords.
  /// Returns an empty list if no matches are found.
  Future<List<Emoji>> searchEmojis(String query);

  /// Get an emoji by its shortcode.
  ///
  /// Returns null if the shortcode is not found.
  Emoji? getEmojiByShortcode(String shortcode);

  /// Get an emoji by its ID.
  ///
  /// Returns null if the ID is not found.
  Emoji? getEmojiById(String id);

  /// Get metadata about this emoji source.
  EmojiSourceMetadata get metadata;

  /// Initialize the emoji source.
  ///
  /// This method is called once when the source is first used.
  /// Override this method to perform any necessary setup, such as loading data.
  Future<void> initialize() async {
    // Default implementation: no initialization needed
  }

  /// Dispose of any resources held by this emoji source.
  ///
  /// Override this method to clean up resources, such as closing connections
  /// or clearing caches.
  void dispose() {
    // Default implementation: no cleanup needed
  }

  /// Get recently used emojis.
  ///
  /// Returns an empty list by default. Implementations can override this
  /// to provide a list of recently used emojis for quick access.
  Future<List<Emoji>> getRecentEmojis() async {
    return [];
  }

  /// Get frequently used emojis.
  ///
  /// Returns an empty list by default. Implementations can override this
  /// to provide a list of frequently used emojis for quick access.
  Future<List<Emoji>> getFrequentEmojis() async {
    return [];
  }

  /// Track when an emoji is used.
  ///
  /// Implementations can override this to track emoji usage statistics
  /// for features like "recently used" or "frequently used" emojis.
  Future<void> trackEmojiUsage(Emoji emoji) async {
    // Default implementation: no tracking
  }
}
