import 'package:flutter/material.dart';

enum BottomAttachment {
  none,
  keyboard, // Not strictly "attached" but used to signify keyboard is dominant
  emoji,
  // Future extensions:
  // image,
  // voice,
  // etc.
}

class EditorUIState extends ChangeNotifier {
  BottomAttachment _activeAttachment = BottomAttachment.none;
  double _keyboardHeight = 0;
  double _savedKeyboardHeight = 250.0; // Default fallback

  BottomAttachment get activeAttachment => _activeAttachment;
  double get keyboardHeight => _keyboardHeight;
  double get savedKeyboardHeight => _savedKeyboardHeight;

  bool get isKeyboardVisible => _activeAttachment == BottomAttachment.keyboard;
  bool get isEmojiVisible => _activeAttachment == BottomAttachment.emoji;

  bool get isPickerVisible =>
      _activeAttachment != BottomAttachment.none &&
      _activeAttachment != BottomAttachment.keyboard;

  // Returns the height that should be reserved at the bottom
  double get bottomAreaHeight {
    if (isKeyboardVisible) {
      return _keyboardHeight > 0 ? _keyboardHeight : _savedKeyboardHeight;
    } else if (isEmojiVisible) {
      return _savedKeyboardHeight;
    }
    return 0.0;
  }

  void updateKeyboardHeight(double height) {
    _keyboardHeight = height;
    if (height > 0) {
      _savedKeyboardHeight = height;
    }
    notifyListeners();
  }

  void showKeyboard() {
    if (_activeAttachment != BottomAttachment.keyboard) {
      _activeAttachment = BottomAttachment.keyboard;
      notifyListeners();
    }
  }

  void showEmojiPicker() {
    if (_activeAttachment != BottomAttachment.emoji) {
      _activeAttachment = BottomAttachment.emoji;
      notifyListeners();
    }
  }

  void closeBottomAttachment() {
    if (_activeAttachment != BottomAttachment.none) {
      _activeAttachment = BottomAttachment.none;
      notifyListeners();
    }
  }

  void toggleEmojiPicker() {
    if (isEmojiVisible) {
      // If emoji is showing, we want to go back to keyboard?
      // Or close? Usually tapping the icon again might focus the keyboard
      // OR close everything.
      // Let's assume standard behavior: Toggle OFF means focus editor (keyboard)
      showKeyboard();
    } else {
      showEmojiPicker();
    }
  }
}
