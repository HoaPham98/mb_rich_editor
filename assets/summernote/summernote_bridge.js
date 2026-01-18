/**
 * Summernote Bridge for Flutter RichEditor
 * 
 * This file provides backward compatibility with the existing RE.* API
 * by mapping calls to Summernote methods and handling Flutter communication.
 * 
 * Copyright (C) 2024
 */

// Global editor object for backward compatibility - define immediately
var RE = window.RE || {};
window.RE = RE;

// Editor instance
var $editor = null;

// State tracking
let lastStates = {
  bold: false,
  italic: false,
  underline: false,
  strikeThrough: false,
  unorderedList: false,
  orderedList: false,
  justifyLeft: false,
  justifyCenter: false,
  justifyRight: false,
  subscript: false,
  superscript: false,
  justifyFull: false,
  horizontalRule: false,
  formatBlock: ''
};

let callbackTimeout = null;
let lastCallbackHtml = '';
let stateCallbackTimeout = null;
let lastStateString = '';

// Current selection backup
RE.currentSelection = {
  "startContainer": 0,
  "startOffset": 0,
  "endContainer": 0,
  "endOffset": 0
};

// ==================== Default Summernote Options ====================

const defaultSummernoteOptions = {
  placeholder: 'Enter text here...',
  tabsize: 2,
  toolbar: [], // Hide toolbar - we use Flutter toolbar
  callbacks: {
    onInit: function () {
      console.log('Summernote initialized');
      // Call Dart callback if registered
      _callDartCallback('onInit');
    },
    onChange: function (contents, $editable) {
      RE.callback();
      // Call Dart callback if registered
      _callDartCallback('onChange', contents);
    },
    onFocus: function () {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onFocus', 'focused');
      }
      // Call Dart callback if registered
      _callDartCallback('onFocus');
    },
    onBlur: function () {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onBlur', 'blurred');
      }
      // Call Dart callback if registered
      _callDartCallback('onBlur');
    },
    onKeyup: function (e) {
      RE.enabledEditingItems();
      RE.handleKeyup(e);
      // Call Dart callback if registered
      _callDartCallback('onKeyup', _eventToMap(e));
    },
    onKeydown: function (e) {
      RE.handleKeydown(e);
      // Call Dart callback if registered
      _callDartCallback('onKeydown', _eventToMap(e));
    },
    onMouseup: function (e) {
      RE.enabledEditingItems();
    },
    onPaste: function (e) {
      // Call Dart callback if registered
      _callDartCallback('onPaste', _eventToMap(e));
    },
    onImageUpload: function (files) {
      // Convert FileList to array of data URLs or names
      const fileInfos = [];
      for (let i = 0; i < files.length; i++) {
        fileInfos.push(files[i].name);
      }
      // Call Dart callback if registered
      _callDartCallback('onImageUpload', fileInfos);
    },
    onEnter: function () {
      // Call Dart callback if registered
      _callDartCallback('onEnter');
    }
  }
};

// ==================== Callback Bridge Utilities ====================

/**
 * Call a Dart callback if it has been registered
 * @param {string} callbackName - Name of the callback (e.g., 'onInit', 'onChange')
 * @param {*} arg - Argument to pass to the callback
 */
function _callDartCallback(callbackName, arg) {
  if (!window.availableSummernoteCallbacks) return;

  // Check if this callback was registered in Dart
  if (window.availableSummernoteCallbacks.includes(callbackName)) {
    const handlerName = 'summernote_' + callbackName;
    if (window.flutter_inappwebview) {
      // Single argument - pass as array
      if (arg !== undefined) {
        window.flutter_inappwebview.callHandler(handlerName, arg);
      } else {
        window.flutter_inappwebview.callHandler(handlerName);
      }
    }
  }
}

/**
 * Convert a DOM event to a plain object/map for passing to Dart
 * @param {Event} e - The DOM event
 * @returns {Object} Plain object representation of the event
 */
function _eventToMap(e) {
  if (!e) return {};

  return {
    type: e.type || '',
    key: e.key || '',
    code: e.code || '',
    keyCode: e.keyCode || 0,
    which: e.which || 0,
    ctrlKey: e.ctrlKey || false,
    shiftKey: e.shiftKey || false,
    altKey: e.altKey || false,
    metaKey: e.metaKey || false,
    preventDefault: typeof e.preventDefault === 'function',
  };
}

// ==================== Deep Merge Utility ====================

function deepMerge(target, source) {
  const output = { ...target };

  if (isObject(target) && isObject(source)) {
    Object.keys(source).forEach(key => {
      if (isObject(source[key])) {
        if (!(key in target)) {
          Object.assign(output, { [key]: source[key] });
        } else {
          output[key] = deepMerge(target[key], source[key]);
        }
      } else {
        Object.assign(output, { [key]: source[key] });
      }
    });
  }

  return output;
}

function isObject(item) {
  return item && typeof item === 'object' && !Array.isArray(item);
}

// ==================== Initialize Summernote ====================

// Wait for jQuery to be available
function initSummernote() {
  if (typeof $ === 'undefined' || typeof $.fn.summernote === 'undefined') {
    console.log('Waiting for jQuery and Summernote...');
    setTimeout(initSummernote, 50);
    return;
  }

  $editor = $('#editor');

  // Merge custom options from Dart with defaults (non-callback options only)
  const customOptions = window.customSummernoteOptions || {};

  // Remove 'callbacks' from custom options - we handle those separately
  delete customOptions.callbacks;

  const finalOptions = deepMerge(defaultSummernoteOptions, customOptions);

  // Initialize Summernote with merged options
  $editor.summernote(finalOptions);

  // Store reference to the editable element
  RE.editor = $editor.next('.note-editor').find('.note-editable')[0];
}

// Manual initialization trigger (called from Dart)
RE.initSummernote = function () {
  initSummernote();
};

// NOTE: Auto-initialization removed - will be triggered from Dart after options are set
// initSummernote();

// ==================== Callback System ====================

RE.callback = function () {
  const currentHtml = RE.getHtml();

  if (currentHtml !== lastCallbackHtml) {
    if (callbackTimeout) {
      clearTimeout(callbackTimeout);
    }

    callbackTimeout = setTimeout(function () {
      lastCallbackHtml = currentHtml;

      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onTextChange', currentHtml);
      }

      RE.enabledEditingItems();
    }, 100);
  }
};

// ==================== Content Methods ====================

RE.setHtml = function (contents) {
  const decoded = decodeURIComponent(contents.replace(/\+/g, '%20'));
  $editor.summernote('code', decoded);
};

RE.getHtml = function () {
  return $editor.summernote('code');
};

RE.getText = function () {
  return $editor.summernote('isEmpty') ? '' : $(RE.editor).text();
};

RE.insertHTML = function (html) {
  $editor.summernote('pasteHTML', html);
};

RE.insertBlockQuote = function (contents) {
  const decoded = decodeURIComponent(contents.replace(/\+/g, '%20'));
  $editor.summernote('pasteHTML', decoded);
  RE.callback();
};

// ==================== Text Formatting ====================

RE.setBold = function () {
  $editor.summernote('bold');
  RE.enabledEditingItems();
};

RE.setItalic = function () {
  $editor.summernote('italic');
  RE.enabledEditingItems();
};

RE.setUnderline = function () {
  $editor.summernote('underline');
  RE.enabledEditingItems();
};

RE.setStrikeThrough = function () {
  $editor.summernote('strikethrough');
  RE.enabledEditingItems();
};

RE.setSubscript = function () {
  $editor.summernote('subscript');
};

RE.setSuperscript = function () {
  $editor.summernote('superscript');
};

// ==================== Lists ====================

RE.setBullets = function () {
  $editor.summernote('insertUnorderedList');
  RE.enabledEditingItems();
};

RE.setNumbers = function () {
  $editor.summernote('insertOrderedList');
  RE.enabledEditingItems();
};

// ==================== Blocks ====================

RE.setBlockquote = function () {
  // Summernote doesn't have direct blockquote toggle, use formatBlock
  document.execCommand('formatBlock', false, 'blockquote');
  RE.enabledEditingItems();
};

RE.setHeading = function (level) {
  $editor.summernote('formatH' + level);
};

RE.setIndent = function () {
  $editor.summernote('indent');
};

RE.setOutdent = function () {
  $editor.summernote('outdent');
};

// ==================== Alignment ====================

RE.setJustifyLeft = function () {
  $editor.summernote('justifyLeft');
};

RE.setJustifyCenter = function () {
  $editor.summernote('justifyCenter');
};

RE.setJustifyRight = function () {
  $editor.summernote('justifyRight');
};

RE.setJustifyFull = function () {
  $editor.summernote('justifyFull');
};

// ==================== Colors ====================

RE.setTextColor = function (color) {
  $editor.summernote('foreColor', color);
};

RE.setTextBackgroundColor = function (color) {
  $editor.summernote('backColor', color);
};

// ==================== Font Size ====================

RE.setFontSize = function (size) {
  $editor.summernote('fontSize', size);
};

// ==================== Editor Appearance ====================

RE.setBaseTextColor = function (color) {
  $(RE.editor).css('color', color);
};

RE.setBaseFontSize = function (size) {
  $(RE.editor).css('font-size', size);
};

RE.setPadding = function (left, top, right, bottom) {
  $(RE.editor).css({
    'padding-left': left,
    'padding-top': top,
    'padding-right': right,
    'padding-bottom': bottom
  });
};

RE.setBackgroundColor = function (color) {
  $('body').css('background-color', color);
  $(RE.editor).css('background-color', color);
};

RE.setWidth = function (size) {
  $(RE.editor).css('min-width', size);
};

RE.setHeight = function (size) {
  $(RE.editor).css('height', size);
};

RE.setPlaceholder = function (placeholder) {
  // Update placeholder through Summernote options
  $('.note-placeholder').text(placeholder);
};

RE.setInputEnabled = function (enabled) {
  if (enabled) {
    $editor.summernote('enable');
  } else {
    $editor.summernote('disable');
  }
};

// ==================== Media Insertion ====================

RE.insertImage = function (url, alt) {
  $editor.summernote('insertImage', url, alt || '');
};

RE.insertImageAttach = function (url, dataAttachment) {
  var html = '<img src="' + url + '" data-attachment="' + dataAttachment + '" />';
  $editor.summernote('pasteHTML', html);
};

RE.insertImageW = function (url, alt, width) {
  var html = '<img src="' + url + '" alt="' + (alt || '') + '" width="' + width + '"/>';
  $editor.summernote('pasteHTML', html);
};

RE.insertImageWH = function (url, alt, width, height) {
  var html = '<img src="' + url + '" alt="' + (alt || '') + '" style="width:' + width + 'px; height:' + height + 'px;" />';
  $editor.summernote('pasteHTML', html);
};

RE.insertVideo = function (url) {
  var html = '<video src="' + url + '" controls></video><br>';
  $editor.summernote('pasteHTML', html);
};

RE.insertVideoW = function (url, width) {
  var html = '<video src="' + url + '" width="' + width + '" controls></video><br>';
  $editor.summernote('pasteHTML', html);
};

RE.insertVideoWH = function (url, width, height) {
  var html = '<video src="' + url + '" width="' + width + '" height="' + height + '" controls></video><br>';
  $editor.summernote('pasteHTML', html);
};

RE.insertAudio = function (url) {
  var html = '<audio src="' + url + '" controls></audio><br>';
  $editor.summernote('pasteHTML', html);
};

RE.insertYoutubeVideo = function (url) {
  const videoData = extractYouTubeVideoIdAndTime(url);
  if (!videoData) {
    console.log("Invalid YouTube URL.");
    return;
  }
  const formattedMediaTag = '[MEDIA=youtube]' + videoData + '[/MEDIA]';
  $editor.summernote('pasteHTML', formattedMediaTag);
};

RE.insertMediaBBCode = function (data) {
  $editor.summernote('pasteHTML', data);
};

RE.insertLink = function (url, title) {
  RE.restorerange();
  var sel = document.getSelection();
  if (sel.toString().length == 0) {
    $editor.summernote('pasteHTML', '<a href="' + url + '">' + title + '</a>');
  } else {
    $editor.summernote('createLink', {
      url: url,
      text: title,
      isNewWindow: false
    });
  }
  RE.callback();
};

RE.insertEmoji = function (emojiData) {
  const url = emojiData.imageUrl || '';
  const alt = emojiData.metadata?.alt || emojiData.name || emojiData.shortcodes || 'emoji';
  const className = 'emoji';

  var html = '<img src="' + url + '" class="' + className + '" alt="' + alt + '" data-emoji-id="' + emojiData.id + '" />';
  $editor.summernote('pasteHTML', html);
};

RE.setTodo = function (text) {
  var html = '<input type="checkbox" name="' + text + '" value="' + text + '"/> &nbsp;';
  $editor.summernote('pasteHTML', html);
};

// ==================== Editor Control ====================

RE.undo = function () {
  $editor.summernote('undo');
};

RE.redo = function () {
  $editor.summernote('redo');
};

RE.removeFormat = function () {
  $editor.summernote('removeFormat');
};

RE.focus = function () {
  $editor.summernote('focus');
};

RE.blurFocus = function () {
  $(RE.editor).blur();
};

// ==================== Selection Management ====================

RE.prepareInsert = function () {
  RE.backuprange();
};

RE.backuprange = function () {
  var selection = window.getSelection();
  if (selection.rangeCount > 0) {
    var range = selection.getRangeAt(0);
    RE.currentSelection = {
      "startContainer": range.startContainer,
      "startOffset": range.startOffset,
      "endContainer": range.endContainer,
      "endOffset": range.endOffset
    };
  }
};

RE.restorerange = function () {
  var selection = window.getSelection();
  selection.removeAllRanges();
  var range = document.createRange();
  try {
    range.setStart(RE.currentSelection.startContainer, RE.currentSelection.startOffset);
    range.setEnd(RE.currentSelection.endContainer, RE.currentSelection.endOffset);
    selection.addRange(range);
  } catch (e) {
    console.log('Could not restore range:', e);
  }
};

// ==================== State Detection ====================

// Track previous states to avoid duplicate callbacks
let previousStateMap = {};

RE.enabledEditingItems = function () {
  var items = [];

  if (document.queryCommandState('bold')) items.push('bold');
  if (document.queryCommandState('italic')) items.push('italic');
  if (document.queryCommandState('subscript')) items.push('subscript');
  if (document.queryCommandState('superscript')) items.push('superscript');
  if (document.queryCommandState('strikeThrough')) items.push('strikeThrough');
  if (document.queryCommandState('underline')) items.push('underline');
  if (document.queryCommandState('insertOrderedList')) items.push('orderedList');
  if (document.queryCommandState('insertUnorderedList')) items.push('unorderedList');
  if (document.queryCommandState('justifyCenter')) items.push('justifyCenter');
  if (document.queryCommandState('justifyFull')) items.push('justifyFull');
  if (document.queryCommandState('justifyLeft')) items.push('justifyLeft');
  if (document.queryCommandState('justifyRight')) items.push('justifyRight');

  var formatBlock = document.queryCommandValue('formatBlock');
  if (formatBlock.length > 0) {
    items.push(formatBlock);
  }

  // Check if cursor is inside a blockquote
  var selection = window.getSelection();
  if (selection.rangeCount > 0) {
    var range = selection.getRangeAt(0);
    var node = range.startContainer;

    // If cursor is in a text node, get its parent element
    if (node.nodeType === 3) {
      node = node.parentElement;
    }

    // Check if the cursor or any of its ancestors is a blockquote
    var blockquote = node.closest('blockquote');
    if (blockquote) {
      items.push('blockquote');
    }
  }

  const stateString = items.join(',');

  // Original callback for backward compatibility
  if (stateString !== lastStateString) {
    if (stateCallbackTimeout) {
      clearTimeout(stateCallbackTimeout);
    }

    stateCallbackTimeout = setTimeout(function () {
      lastStateString = stateString;
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onDecorationState', stateString);
      }
    }, 50);
  }

  // NEW: Also call Dart callback if registered (as Map<String, bool> + String>)
  const stateMap = {};
  stateMap['bold'] = items.includes('bold');
  stateMap['italic'] = items.includes('italic');
  stateMap['underline'] = items.includes('underline');
  stateMap['strikeThrough'] = items.includes('strikeThrough');
  stateMap['subscript'] = items.includes('subscript');
  stateMap['superscript'] = items.includes('superscript');
  stateMap['orderedList'] = items.includes('orderedList');
  stateMap['unorderedList'] = items.includes('unorderedList');
  stateMap['justifyLeft'] = items.includes('justifyLeft');
  stateMap['justifyCenter'] = items.includes('justifyCenter');
  stateMap['justifyRight'] = items.includes('justifyRight');
  stateMap['justifyFull'] = items.includes('justifyFull');
  stateMap['blockquote'] = items.includes('blockquote');
  stateMap['formatBlock'] = formatBlock || ''; // Include format block

  // Check if state changed
  let stateChanged = false;
  for (const key in stateMap) {
    if (previousStateMap[key] !== stateMap[key]) {
      stateChanged = true;
      break;
    }
  }

  if (stateChanged) {
    previousStateMap = { ...stateMap };
    _callDartCallback('onStateChange', stateMap);
  }
};

// ==================== Keyboard Handling ====================

RE.handleKeyup = function (e) {
  // Mention detection will be handled by plugins
};

RE.handleKeydown = function (e) {
  // Special key handling (e.g., Enter in blockquote) will be handled here if needed
};

// ==================== Utility Functions ====================

function extractYouTubeVideoIdAndTime(url) {
  const regex = /(?:https?:\/\/(?:www\.)?(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11}))(?:.*(?:[?&]t=)(\d+))?/;
  const match = url.match(regex);
  if (match) {
    const videoId = match[1];
    const time = match[2];
    return time ? videoId + ':' + time : videoId;
  }
  return null;
}

RE.scrollToCursor = function () {
  var selection = window.getSelection();
  if (selection.rangeCount) {
    var range = selection.getRangeAt(0);
    var rect = range.getBoundingClientRect();
    if (rect.bottom > window.innerHeight) {
      window.scrollTo(0, rect.bottom - window.innerHeight + 50);
    }
  }
};

// Export RE globally
window.RE = RE;

// ==================== Summernote Plugin Loading Support ====================

// Store loaded plugin scripts to avoid duplicates
RE.loadedPlugins = new Set();

/**
 * Load a Summernote plugin from a CDN URL.
 * @param {string} pluginName - The name of the plugin (for tracking)
 * @param {string} scriptUrl - The CDN URL to load the plugin from
 * @returns {Promise} Resolves when loaded, rejects on error
 */
RE.loadSummernotePluginFromUrl = function (pluginName, scriptUrl) {
  return new Promise((resolve, reject) => {
    // Check if already loaded
    if (RE.loadedPlugins.has(scriptUrl)) {
      console.log('Summernote plugin already loaded:', scriptUrl);
      resolve();
      return;
    }

    const script = document.createElement('script');
    script.src = scriptUrl;
    script.onload = () => {
      RE.loadedPlugins.add(scriptUrl);
      console.log('Summernote plugin loaded from URL:', scriptUrl);
      resolve();
    };
    script.onerror = () => reject(new Error('Failed to load plugin: ' + scriptUrl));
    document.getElementById('summernote-plugin-scripts').appendChild(script);
  });
};

/**
 * Load a Summernote plugin from a Flutter asset (content injected as string).
 * @param {string} pluginName - The name of the plugin
 * @param {string} assetContent - The JavaScript content from the asset
 * @returns {Promise} Resolves when loaded, rejects on error
 */
RE.loadSummernotePluginFromAsset = function (pluginName, assetContent) {
  return new Promise((resolve, reject) => {
    try {
      const script = document.createElement('script');
      script.textContent = assetContent;
      document.getElementById('summernote-plugin-scripts').appendChild(script);
      console.log('Summernote plugin loaded from asset:', pluginName);
      resolve();
    } catch (e) {
      reject(new Error('Failed to load plugin from asset: ' + e));
    }
  });
};

/**
 * Load a Summernote plugin from raw JavaScript code.
 * @param {string} pluginName - The name of the plugin
 * @param {string} jsCode - The JavaScript code to inject
 * @returns {Promise} Resolves when loaded, rejects on error
 */
RE.loadSummernotePluginFromCode = function (pluginName, jsCode) {
  return new Promise((resolve, reject) => {
    try {
      const script = document.createElement('script');
      script.textContent = jsCode;
      document.getElementById('summernote-plugin-scripts').appendChild(script);
      console.log('Summernote plugin loaded from code:', pluginName);
      resolve();
    } catch (e) {
      reject(new Error('Failed to inject plugin code: ' + e));
    }
  });
};

/**
 * Configure plugin options before Summernote initialization.
 * This merges the provided options into $.summernote.options.
 * @param {string} pluginName - The name of the plugin
 * @param {Object} options - The options to configure
 */
RE.configureSummernotePlugin = function (pluginName, options) {
  if (!$.summernote.options) $.summernote.options = {};
  $.summernote.options[pluginName] = options;
  console.log('Summernote plugin options configured:', pluginName, options);
};

/**
 * Configure plugin language strings before Summernote initialization.
 * This merges the provided strings into $.summernote.lang.
 * @param {string} langCode - The language code (e.g., 'en-US')
 * @param {string} pluginName - The name of the plugin
 * @param {Object} strings - The language strings to configure
 */
RE.configureSummernotePluginLang = function (langCode, pluginName, strings) {
  if (!$.summernote.lang) $.summernote.lang = {};
  if (!$.summernote.lang[langCode]) $.summernote.lang[langCode] = {};
  $.summernote.lang[langCode][pluginName] = strings;
  console.log('Summernote plugin language configured:', langCode, pluginName, strings);
};

/**
 * Create a callback handler that bridges plugin events to Dart.
 * Use this in your plugin JavaScript to call Dart callbacks.
 * @param {string} pluginName - The name of the plugin
 * @param {string} callbackName - The name of the callback
 * @returns {Function} A function that calls the Dart handler
 */
RE.registerPluginCallback = function (pluginName, callbackName) {
  return function (data) {
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('plugin_' + pluginName + '_' + callbackName, data);
    }
  };
};

// ==================== Custom CSS Injection Support ====================

// Store injected CSS styles for management
RE.injectedCSS = new Map(); // name -> {element, source, timestamp}

/**
 * Inject custom CSS from a raw CSS string.
 * @param {string} cssName - Unique identifier for this CSS
 * @param {string} cssContent - The CSS content to inject
 * @param {Object} options - Optional configuration
 * @returns {boolean} True if injected successfully
 */
RE.injectCustomCSS = function (cssName, cssContent, options = {}) {
  const { scope = 'editor', priority = 100 } = options;

  // Remove existing CSS with same name if it exists
  if (RE.injectedCSS.has(cssName)) {
    RE.removeCustomCSS(cssName);
  }

  // Create style element
  const styleElement = document.createElement('style');
  styleElement.setAttribute('data-css-name', cssName);
  styleElement.setAttribute('data-priority', priority);
  styleElement.textContent = cssContent;

  // Determine insertion point based on scope
  if (scope === 'global') {
    styleElement.id = `custom-css-global-${cssName}`;
    document.head.appendChild(styleElement);
  } else {
    styleElement.id = `custom-css-editor-${cssName}`;
    const editorContainer = document.querySelector('.note-editor');
    if (editorContainer) {
      editorContainer.appendChild(styleElement);
    } else {
      document.head.appendChild(styleElement);
    }
  }

  // Store reference
  RE.injectedCSS.set(cssName, {
    element: styleElement,
    source: 'string',
    timestamp: Date.now(),
    scope: scope,
    priority: priority
  });

  console.log('Custom CSS injected:', cssName, 'Scope:', scope);
  return true;
};

/**
 * Inject custom CSS from a URL (external stylesheet).
 * @param {string} cssName - Unique identifier for this CSS
 * @param {string} cssUrl - The URL to load the CSS from
 * @returns {Promise} Resolves when loaded, rejects on error
 */
RE.injectCustomCSSFromUrl = function (cssName, cssUrl, options = {}) {
  return new Promise((resolve, reject) => {
    // Check if already loaded
    if (RE.injectedCSS.has(cssName)) {
      console.log('CSS already loaded:', cssName);
      resolve();
      return;
    }

    const { scope = 'editor', priority = 100 } = options;

    // Create link element
    const linkElement = document.createElement('link');
    linkElement.rel = 'stylesheet';
    linkElement.href = cssUrl;
    linkElement.setAttribute('data-css-name', cssName);
    linkElement.setAttribute('data-priority', priority);

    linkElement.onload = () => {
      RE.injectedCSS.set(cssName, {
        element: linkElement,
        source: 'url',
        url: cssUrl,
        timestamp: Date.now(),
        scope: scope,
        priority: priority
      });
      console.log('Custom CSS loaded from URL:', cssName, cssUrl);
      resolve();
    };

    linkElement.onerror = () => {
      reject(new Error('Failed to load CSS: ' + cssUrl));
    };

    // Insert based on scope
    if (scope === 'global') {
      linkElement.id = `custom-css-global-${cssName}`;
      document.head.appendChild(linkElement);
    } else {
      linkElement.id = `custom-css-editor-${cssName}`;
      const editorContainer = document.querySelector('.note-editor');
      if (editorContainer) {
        editorContainer.appendChild(linkElement);
      } else {
        document.head.appendChild(linkElement);
      }
    }
  });
};

/**
 * Inject custom CSS from a Flutter asset (content injected as string).
 * @param {string} cssName - Unique identifier for this CSS
 * @param {string} assetContent - The CSS content from the asset
 * @returns {boolean} True if injected successfully
 */
RE.injectCustomCSSFromAsset = function (cssName, assetContent, options = {}) {
  return RE.injectCustomCSS(cssName, assetContent, {
    ...options,
    source: 'asset'
  });
};

/**
 * Remove a previously injected CSS by name.
 * @param {string} cssName - The name of the CSS to remove
 * @returns {boolean} True if removed, false if not found
 */
RE.removeCustomCSS = function (cssName) {
  const cssData = RE.injectedCSS.get(cssName);
  if (!cssData) {
    console.warn('CSS not found:', cssName);
    return false;
  }

  // Remove the element from DOM
  if (cssData.element && cssData.element.parentNode) {
    cssData.element.parentNode.removeChild(cssData.element);
  }

  // Remove from tracking
  RE.injectedCSS.delete(cssName);
  console.log('Custom CSS removed:', cssName);
  return true;
};

/**
 * Clear all injected custom CSS.
 * @param {Object} options - Optional filters
 * @returns {number} Number of CSS rules removed
 */
RE.clearAllCustomCSS = function (options = {}) {
  const { scope } = options;
  let removedCount = 0;

  const namesToRemove = [];
  for (const [name, cssData] of RE.injectedCSS.entries()) {
    if (scope && cssData.scope !== scope) {
      continue;
    }
    namesToRemove.push(name);
  }

  namesToRemove.forEach(name => {
    if (RE.removeCustomCSS(name)) {
      removedCount++;
    }
  });

  console.log('Cleared', removedCount, 'custom CSS rules');
  return removedCount;
};

/**
 * Check if a CSS with the given name is currently injected.
 * @param {string} cssName - The name to check
 * @returns {boolean} True if injected
 */
RE.hasCustomCSS = function (cssName) {
  return RE.injectedCSS.has(cssName);
};

/**
 * Get information about all injected CSS.
 * @returns {Array} Array of objects with CSS metadata
 */
RE.getInjectedCSSInfo = function () {
  const info = [];
  for (const [name, cssData] of RE.injectedCSS.entries()) {
    info.push({
      name: name,
      source: cssData.source,
      scope: cssData.scope,
      priority: cssData.priority,
      timestamp: cssData.timestamp,
      url: cssData.url
    });
  }
  return info;
};

// Re-export RE globally (in case it was already referenced before)
window.RE = RE;
