import '../models/mention_user.dart';
import '../models/mention_provider.dart';

/// Static list-based mention provider.
///
/// Provides mentions from a pre-defined list of users.
class StaticMentionProvider implements MentionProvider {
  /// List of users available for mentioning
  final List<MentionUser> users;

  const StaticMentionProvider({required this.users});

  @override
  MentionProviderMetadata get metadata => MentionProviderMetadata(
    name: 'Static Mention Provider',
    trigger: '@',
    maxResults: users.length,
    caseSensitive: false,
    description: 'Provides mentions from a static list of users',
  );

  @override
  Future<List<MentionUser>> searchUsers(String query) async {
    if (query.isEmpty) {
      return users.take(10).toList();
    }

    final lowerQuery = query.toLowerCase();
    final results = <MentionUser>[];

    for (final user in users) {
      // Check username
      if (user.username.toLowerCase().contains(lowerQuery)) {
        results.add(user);
        continue;
      }

      // Check display name
      if (user.displayName != null &&
          user.displayName!.toLowerCase().contains(lowerQuery)) {
        results.add(user);
      }
    }

    return results.take(metadata.maxResults).toList();
  }

  @override
  Future<MentionUser?> getUserById(String id) async {
    for (final user in users) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<void> initialize() async {
    // No initialization needed for static provider
  }

  @override
  Future<List<MentionUser>> getRecentUsers() async {
    // No recent users for static provider
    return [];
  }

  @override
  Future<void> trackMention(MentionUser user) async {
    // No tracking for static provider
  }

  @override
  Future<bool> canMention(MentionUser user) async {
    // All users can be mentioned
    return true;
  }

  @override
  void dispose() {
    // No cleanup needed for static provider
  }
}
