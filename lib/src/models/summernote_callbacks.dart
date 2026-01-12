/// Callback types for Summernote events
typedef SummernoteInitCallback = void Function();
typedef SummernoteChangeCallback = void Function(String contents);
typedef SummernoteBlurCallback = void Function();
typedef SummernoteFocusCallback = void Function();
typedef SummernoteKeydownCallback = void Function(Map<String, dynamic> event);
typedef SummernoteKeyupCallback = void Function(Map<String, dynamic> event);
typedef SummernotePasteCallback = void Function(Map<String, dynamic> event);
typedef SummernoteImageUploadCallback = void Function(List<String> files);
typedef SummernoteEnterCallback = void Function();
typedef SummernoteLanguageCallback = String Function(String locale);

/// Callback for toolbar state changes (e.g., bold, italic enabled/disabled)
/// Provides a typed SummernoteToolbarState object
typedef SummernoteStateChangeCallback = void Function(SummernoteToolbarState state);

/// Represents the current state of toolbar formatting options
class SummernoteToolbarState {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikeThrough;
  final bool subscript;
  final bool superscript;
  final bool orderedList;
  final bool unorderedList;
  final bool justifyLeft;
  final bool justifyCenter;
  final bool justifyRight;
  final bool justifyFull;
  final String formatBlock; // e.g., 'h1', 'h2', 'p', 'blockquote', 'pre', ''

  const SummernoteToolbarState({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikeThrough = false,
    this.subscript = false,
    this.superscript = false,
    this.orderedList = false,
    this.unorderedList = false,
    this.justifyLeft = false,
    this.justifyCenter = false,
    this.justifyRight = false,
    this.justifyFull = false,
    this.formatBlock = '',
  });

  /// Create from a Map (received from JavaScript)
  factory SummernoteToolbarState.fromMap(Map<String, dynamic> map) {
    return SummernoteToolbarState(
      bold: map['bold'] == true,
      italic: map['italic'] == true,
      underline: map['underline'] == true,
      strikeThrough: map['strikeThrough'] == true,
      subscript: map['subscript'] == true,
      superscript: map['superscript'] == true,
      orderedList: map['orderedList'] == true,
      unorderedList: map['unorderedList'] == true,
      justifyLeft: map['justifyLeft'] == true,
      justifyCenter: map['justifyCenter'] == true,
      justifyRight: map['justifyRight'] == true,
      justifyFull: map['justifyFull'] == true,
      formatBlock: map['formatBlock']?.toString() ?? '',
    );
  }

  /// Check if any formatting is active
  bool get hasAnyFormatting =>
      bold || italic || underline || strikeThrough || subscript || superscript;

  /// Check if any list is active
  bool get hasList => orderedList || unorderedList;

  /// Check if any alignment is active
  bool get hasAlignment =>
      justifyLeft || justifyCenter || justifyRight || justifyFull;

  /// Check if currently in a heading
  bool get isHeading => formatBlock.startsWith('h');

  /// Get heading level (1-6), or null if not in heading
  int? get headingLevel {
    if (!isHeading) return null;
    final level = formatBlock.substring(1);
    return int.tryParse(level);
  }

  /// Check if currently in a blockquote
  bool get isBlockquote => formatBlock == 'blockquote';

  /// Check if currently in a code block (pre)
  bool get isCodeBlock => formatBlock == 'pre';

  /// Check if currently in a paragraph (or empty)
  bool get isParagraph => formatBlock.isEmpty || formatBlock == 'p';

  @override
  String toString() {
    return 'SummernoteToolbarState('
        'bold: $bold, italic: $italic, underline: $underline, '
        'orderedList: $orderedList, unorderedList: $unorderedList, '
        'justifyLeft: $justifyLeft, justifyCenter: $justifyCenter, '
        'justifyRight: $justifyRight, justifyFull: $justifyFull, '
        'formatBlock: $formatBlock)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummernoteToolbarState &&
          runtimeType == other.runtimeType &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          strikeThrough == other.strikeThrough &&
          subscript == other.subscript &&
          superscript == other.superscript &&
          orderedList == other.orderedList &&
          unorderedList == other.unorderedList &&
          justifyLeft == other.justifyLeft &&
          justifyCenter == other.justifyCenter &&
          justifyRight == other.justifyRight &&
          justifyFull == other.justifyFull &&
          formatBlock == other.formatBlock;

  @override
  int get hashCode =>
      bold.hashCode ^
      italic.hashCode ^
      underline.hashCode ^
      strikeThrough.hashCode ^
      subscript.hashCode ^
      superscript.hashCode ^
      orderedList.hashCode ^
      unorderedList.hashCode ^
      justifyLeft.hashCode ^
      justifyCenter.hashCode ^
      justifyRight.hashCode ^
      justifyFull.hashCode ^
      formatBlock.hashCode;
}

/// Custom Summernote callbacks provided by the user
class SummernoteCallbacks {
  final SummernoteInitCallback? onInit;
  final SummernoteChangeCallback? onChange;
  final SummernoteBlurCallback? onBlur;
  final SummernoteFocusCallback? onFocus;
  final SummernoteKeydownCallback? onKeydown;
  final SummernoteKeyupCallback? onKeyup;
  final SummernotePasteCallback? onPaste;
  final SummernoteImageUploadCallback? onImageUpload;
  final SummernoteEnterCallback? onEnter;
  final SummernoteLanguageCallback? onLanguage;
  final SummernoteStateChangeCallback? onStateChange;

  const SummernoteCallbacks({
    this.onInit,
    this.onChange,
    this.onBlur,
    this.onFocus,
    this.onKeydown,
    this.onKeyup,
    this.onPaste,
    this.onImageUpload,
    this.onEnter,
    this.onLanguage,
    this.onStateChange,
  });

  /// Get all callback names that have been provided
  List<String> get providedCallbackNames {
    final names = <String>[];
    if (onInit != null) names.add('onInit');
    if (onChange != null) names.add('onChange');
    if (onBlur != null) names.add('onBlur');
    if (onFocus != null) names.add('onFocus');
    if (onKeydown != null) names.add('onKeydown');
    if (onKeyup != null) names.add('onKeyup');
    if (onPaste != null) names.add('onPaste');
    if (onImageUpload != null) names.add('onImageUpload');
    if (onEnter != null) names.add('onEnter');
    if (onLanguage != null) names.add('onLanguage');
    if (onStateChange != null) names.add('onStateChange');
    return names;
  }
}
