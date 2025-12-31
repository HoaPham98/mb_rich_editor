import 'package:flutter/material.dart';
import '../models/mention_user.dart';
import '../models/mention_provider.dart';
import '../config/mention_config.dart';

/// Widget that displays mention suggestions when user types @ symbol.
class MentionSuggestions extends StatefulWidget {
  final MentionProvider mentionProvider;
  final MentionConfig config;
  final MentionSuggestionsStyle? style;
  final ValueChanged<MentionUser>? onUserSelected;
  final Widget Function(BuildContext, MentionUser)? userBuilder;
  final VoidCallback? onDismiss;
  final String? query; // Add query parameter

  const MentionSuggestions({
    super.key,
    required this.mentionProvider,
    this.config = MentionConfig.defaultConfig,
    this.style,
    this.onUserSelected,
    this.userBuilder,
    this.onDismiss,
    this.query, // Add query parameter
  });

  @override
  State<MentionSuggestions> createState() => _MentionSuggestionsState();
}

class _MentionSuggestionsState extends State<MentionSuggestions> {
  String _query = '';
  List<MentionUser> _filteredUsers = [];
  int _selectedIndex = 0;
  bool _isLoading = false;

  MentionSuggestionsStyle get _style =>
      widget.style ?? MentionSuggestionsStyle.defaultStyle();

  @override
  void initState() {
    super.initState();
  }

  void setQuery(String query) async {
    setState(() {
      _query = query;
      _isLoading = true;
      _selectedIndex = 0;
    });

    if (query.length < widget.config.minLength) {
      setState(() {
        _filteredUsers = [];
        _isLoading = false;
      });
      return;
    }

    final users = await widget.mentionProvider.searchUsers(query);
    final limitedUsers = users.take(widget.config.maxResults).toList();

    if (mounted) {
      setState(() {
        _filteredUsers = limitedUsers;
        _isLoading = false;
      });
    }
  }

  void selectPrevious() {
    if (_filteredUsers.isEmpty) return;
    setState(() {
      _selectedIndex =
          (_selectedIndex - 1 + _filteredUsers.length) % _filteredUsers.length;
    });
  }

  void selectNext() {
    if (_filteredUsers.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % _filteredUsers.length;
    });
  }

  void selectCurrent() {
    if (_filteredUsers.isEmpty) return;
    final user = _filteredUsers[_selectedIndex];
    widget.onUserSelected?.call(user);
    widget.mentionProvider.trackMention(user);
  }

  void clear() {
    setState(() {
      _query = '';
      _filteredUsers = [];
      _selectedIndex = 0;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always show the suggestions if query is provided (even if empty)
    if (widget.query == null || widget.query!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 300,
        minWidth: 200,
        maxWidth: 400,
      ),
      decoration: BoxDecoration(
        color: _style.backgroundColor,
        borderRadius: _style.itemBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _style.itemBorderRadius,
        child: _isLoading ? _buildLoadingIndicator() : _buildUserList(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: _style.padding,
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final isSelected = index == _selectedIndex;
        return widget.userBuilder?.call(context, user) ??
            _buildDefaultUserItem(user, isSelected);
      },
    );
  }

  Widget _buildDefaultUserItem(MentionUser user, bool isSelected) {
    return InkWell(
      onTap: () {
        widget.onUserSelected?.call(user);
        widget.mentionProvider.trackMention(user);
      },
      child: Container(
        height: _style.avatarSize + 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _style.highlightColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: _style.itemBorderRadius,
        ),
        child: Row(
          children: [
            _buildAvatar(user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.displayName ?? 'Unknown',
                    style: TextStyle(
                      color: _style.textColor,
                      fontSize: _style.usernameFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      color: _style.usernameColor,
                      fontSize: _style.roleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (user.role != null && widget.config.showRoles)
              _buildRoleBadge(user.role!),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(MentionUser user) {
    if (user.avatarUrl != null) {
      return CircleAvatar(
        radius: _style.avatarSize / 2,
        backgroundImage: NetworkImage(user.avatarUrl!),
        backgroundColor: _style.dividerColor,
      );
    } else {
      return CircleAvatar(
        radius: _style.avatarSize / 2,
        backgroundColor: _style.dividerColor,
        child: Text(
          _getInitials(user.displayName ?? '?'),
          style: TextStyle(
            color: _style.textColor,
            fontSize: _style.roleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _style.highlightColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: _style.highlightColor,
          fontSize: _style.roleFontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
