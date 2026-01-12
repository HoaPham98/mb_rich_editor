import 'package:flutter/material.dart';
import '../models/emoji.dart';
import '../models/emoji_category.dart';
import '../models/emoji_source.dart';
import '../config/emoji_picker_config.dart';

/// Customizable emoji picker widget.
class EmojiPicker extends StatefulWidget {
  final EmojiSource emojiSource;
  final EmojiPickerConfig config;
  final EmojiPickerStyle? style;
  final ValueChanged<Emoji>? onEmojiSelected;
  final Widget Function(BuildContext, EmojiCategory)? categoryBuilder;
  final Widget Function(BuildContext, Emoji)? emojiBuilder;

  EmojiPicker({
    super.key,
    required this.emojiSource,
    this.config = EmojiPickerConfig.defaultConfig,
    this.style,
    this.onEmojiSelected,
    this.categoryBuilder,
    this.emojiBuilder,
  });

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  late List<EmojiCategory> _categories;
  String _selectedCategoryId = 'all';
  List<Emoji> _filteredEmojis = [];
  bool _isLoaded = false;

  EmojiPickerStyle get _style => widget.style ?? EmojiPickerStyle.defaultStyle;

  @override
  void initState() {
    super.initState();
    debugPrint('[EmojiPicker] initState called - starting async load');
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    debugPrint('[EmojiPicker] _loadCategories: Starting async load');
    final categories = await widget.emojiSource.loadCategories();
    debugPrint(
      '[EmojiPicker] _loadCategories: Loaded ${categories.length} categories',
    );
    setState(() {
      _categories = categories;
      _filteredEmojis = categories.expand((cat) => cat.emojis).toList();
      _isLoaded = true;
      debugPrint(
        '[EmojiPicker] _loadCategories: setState completed, _isLoaded = $_isLoaded',
      );
    });
  }

  void _filterEmojis(String query) {
    setState(() {
      if (query.isEmpty) {
        // Show all emojis from selected category
        final selectedCategory = _categories.firstWhere(
          (cat) => cat.id == _selectedCategoryId,
          orElse: () => _categories.first,
        );
        _filteredEmojis = selectedCategory.emojis;
      } else {
        // Search across all categories
        _filteredEmojis = _categories
            .expand((cat) => cat.emojis)
            .where((emoji) => _matchesQuery(emoji, query.toLowerCase()))
            .take(widget.config.maxSearchResults)
            .toList();
      }
    });
  }

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

  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      final selectedCategory = _categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse: () => _categories.first,
      );
      _filteredEmojis = selectedCategory.emojis;
    });
  }

  void _selectEmoji(Emoji emoji) {
    widget.onEmojiSelected?.call(emoji);
    widget.emojiSource.trackEmojiUsage(emoji);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[EmojiPicker] build called - _isLoaded = $_isLoaded');

    if (!_isLoaded) {
      return Container(
        decoration: _style.decoration,
        padding: _style.padding,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: _style.decoration,
      padding: _style.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.config.showCategories) _buildCategoryTabs(),
          if (widget.config.showSearch) _buildSearchBar(),
          Expanded(child: _buildEmojiGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    debugPrint(
      '[EmojiPicker] _buildCategoryTabs called - about to access _categories',
    );
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _style.backgroundColor,
        border: Border(
          bottom: BorderSide(color: _style.dividerColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final isSelected = category.id == _selectedCategoryId;
            return InkWell(
              onTap: () => _selectCategory(category.id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category.icon != null)
                      Icon(
                        category.icon,
                        size: _style.categoryIconSize,
                        color: isSelected
                            ? _style.selectedCategoryColor
                            : _style.categoryColor,
                      ),
                    if (widget.config.showEmojiCount)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${category.emojiCount}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? _style.selectedCategoryColor
                                : _style.categoryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search emojis...',
          hintStyle: TextStyle(color: _style.searchHintColor),
          filled: true,
          fillColor: _style.searchColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => _filterEmojis(value),
      ),
    );
  }

  Widget _buildEmojiGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.config.columns,
        childAspectRatio: 1,
        crossAxisSpacing: _style.emojiSpacing,
        mainAxisSpacing: _style.emojiSpacing,
      ),
      padding: const EdgeInsets.all(8),
      itemCount: _filteredEmojis.length,
      itemBuilder: (context, index) {
        final emoji = _filteredEmojis[index];
        return widget.emojiBuilder?.call(context, emoji) ??
            _buildDefaultEmojiItem(emoji);
      },
    );
  }

  Widget _buildDefaultEmojiItem(Emoji emoji) {
    final displayText = emoji.isUnicode ? emoji.unicode ?? '🖼️' : '🖼️';

    return InkWell(
      onTap: () => _selectEmoji(emoji),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: _style.emojiBorderRadius,
        ),
        padding: EdgeInsets.all(_style.emojiSize / 4),
        child: emoji.imageUrl != null
            ? Image.network(emoji.imageUrl!, width: 40, height: 40)
            : Text(displayText, style: TextStyle(fontSize: _style.emojiSize)),
      ),
    );
  }
}
