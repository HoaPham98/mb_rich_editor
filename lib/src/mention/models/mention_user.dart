/// Represents a user that can be mentioned.
class MentionUser {
  /// Unique identifier for the user
  final String id;

  /// Username/handle (e.g., "johndoe")
  final String username;

  /// Display name (e.g., "John Doe")
  final String? displayName;

  /// URL to user's avatar image
  final String? avatarUrl;

  /// User's role or title
  final String? role;

  /// Additional metadata about the user
  final Map<String, dynamic>? metadata;

  const MentionUser({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.role,
    this.metadata,
  });

  /// Get the display text for this user
  String get displayText => displayName ?? username;

  /// Create a MentionUser from JSON
  factory MentionUser.fromJson(Map<String, dynamic> json) {
    return MentionUser(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert this MentionUser to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role,
      'metadata': metadata,
    };
  }

  /// Create a copy of this user with modified values
  MentionUser copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? role,
    Map<String, dynamic>? metadata,
  }) {
    return MentionUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentionUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MentionUser(id: $id, username: $username, displayName: $displayName)';
  }
}
