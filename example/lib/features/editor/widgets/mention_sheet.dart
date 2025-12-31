import 'package:flutter/material.dart';
import 'package:mb_rich_editor/mb_rich_editor.dart' as mb;

class MentionSheet {
  static Future<mb.MentionUser?> show(
    BuildContext context,
    List<mb.MentionUser> users,
  ) {
    return showModalBottomSheet<mb.MentionUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.6,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mention Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop(user);
                          },
                          child: Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                _buildAvatar(user),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        user.displayName ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '@${user.username}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildAvatar(mb.MentionUser user) {
    if (user.avatarUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(user.avatarUrl!),
        backgroundColor: Colors.grey.shade300,
      );
    } else {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          _getInitials(user.displayName ?? '?'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
