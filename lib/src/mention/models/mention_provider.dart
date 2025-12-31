import 'mention_user.dart';

/// Metadata about a mention provider.
class MentionProviderMetadata {
  /// Name of the mention provider
  final String name;

  /// The trigger character (e.g., '@')
  final String trigger;

  /// Maximum number of results to return
  final int maxResults;

  /// Whether search is case sensitive
  final bool caseSensitive;

  /// Description of the mention provider
  final String? description;

  const MentionProviderMetadata({
    required this.name,
    required this.trigger,
    this.maxResults = 10,
    this.caseSensitive = false,
    this.description,
  });

  /// Create metadata from JSON
  factory MentionProviderMetadata.fromJson(Map<String, dynamic> json) {
    return MentionProviderMetadata(
      name: json['name'] as String,
      trigger: json['trigger'] as String,
      maxResults: json['maxResults'] as int? ?? 10,
      caseSensitive: json['caseSensitive'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  /// Convert metadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'trigger': trigger,
      'maxResults': maxResults,
      'caseSensitive': caseSensitive,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'MentionProviderMetadata(name: $name, trigger: $trigger)';
  }
}

/// Abstract interface for mention data providers.
///
/// Implement this interface to provide custom user data sources for mentions.
/// The library provides several built-in implementations:
/// - [StaticMentionProvider]: Uses a static list of users
/// - [ApiMentionProvider]: Fetches users from a remote API
/// - [FirestoreMentionProvider]: Fetches users from Cloud Firestore
/// - [CustomMentionProvider]: Allows you to provide custom user data
abstract class MentionProvider {
  /// Search users by query string.
  ///
  /// The query is matched against usernames and display names.
  /// Returns an empty list if no matches are found.
  Future<List<MentionUser>> searchUsers(String query);

  /// Get a user by their ID.
  ///
  /// Returns null if the user is not found.
  Future<MentionUser?> getUserById(String id);

  /// Get metadata about this mention provider.
  MentionProviderMetadata get metadata;

  /// Initialize the mention provider.
  ///
  /// This method is called once when the provider is first used.
  /// Override this method to perform any necessary setup.
  Future<void> initialize() async {
    // Default implementation: no initialization needed
  }

  /// Dispose of any resources held by this mention provider.
  ///
  /// Override this method to clean up resources, such as closing connections
  /// or clearing caches.
  void dispose() {
    // Default implementation: no cleanup needed
  }

  /// Get recently mentioned users.
  ///
  /// Returns an empty list by default. Implementations can override this
  /// to provide a list of recently mentioned users for quick access.
  Future<List<MentionUser>> getRecentUsers() async {
    return [];
  }

  /// Track when a user is mentioned.
  ///
  /// Implementations can override this to track mention statistics
  /// for features like "recently mentioned" users.
  Future<void> trackMention(MentionUser user) async {
    // Default implementation: no tracking
  }

  /// Validate if a user can be mentioned.
  ///
  /// Override this method to implement custom validation logic,
  /// such as checking if the user is active or has permission to be mentioned.
  Future<bool> canMention(MentionUser user) async {
    return true;
  }
}
