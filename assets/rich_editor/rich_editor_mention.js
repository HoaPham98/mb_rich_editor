/**
 * Mention-related JavaScript functions for rich editor.
 * This file handles mention insertion, trigger detection, and management.
 */

// Track when we've just inserted a mention to prevent re-triggering
let _justInsertedMention = false;
let _mentionInsertTimeout = null;

/**
 * Insert a mention at the current cursor position.
 * @param {Object} mentionData - The mention data object
 * @param {Object} mentionData.user - The user being mentioned
 * @param {string} mentionData.trigger - The trigger character (e.g., '@')
 * @param {string} mentionData.format - The format for rendering (text, link, customHtml, customWidget)
 * @param {string} [mentionData.customHtmlTemplate] - Custom HTML template (if format is customHtml)
 * @param {Object} [mentionData.attributes] - Additional attributes for the mention element
 */
RE.insertMention = function (mentionData) {
  RE.restorerange();

  // Set flag to prevent re-triggering mention detection
  _justInsertedMention = true;
  if (_mentionInsertTimeout) {
    clearTimeout(_mentionInsertTimeout);
  }
  // Reset flag after 500ms - enough time for user to type space
  _mentionInsertTimeout = setTimeout(function() {
    _justInsertedMention = false;
  }, 500);

  // Get the text around the cursor to find and replace mention text
  const textAroundCursor = RE.getTextAroundCursor(50);
  const triggerEvent = RE.detectMentionTrigger(textAroundCursor, textAroundCursor.length, mentionData.trigger || '@');

  if (triggerEvent) {
    // Replace the mention text with a formatted mention
    const html = mentionToHtml(mentionData);
    const selection = window.getSelection();

    if (selection.rangeCount > 0) {
      const range = selection.getRangeAt(0);

      // Get the text content
      const textContent = RE.editor.innerText || RE.editor.textContent;

      // Replace the mention text with the mention HTML
      const beforeMention = textContent.substring(0, triggerEvent.position);
      const afterMention = textContent.substring(triggerEvent.position + triggerEvent.query.length + 1); // +1 for trigger character
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = beforeMention + html + afterMention;

      RE.editor.innerHTML = tempDiv.innerHTML;

      // Move the cursor after the mention
      const newRange = document.createRange();
      newRange.selectNodeContents(RE.editor);
      newRange.collapse(false);
      selection.removeAllRanges();
      selection.addRange(newRange);
    }
  } else {
    // Fallback: just insert the mention
    const html = mentionToHtml(mentionData);
    document.execCommand('insertHTML', false, html);
  }

  RE.callback();
};

/**
 * Convert mention data to HTML.
 * @param {Object} mentionData - The mention data object
 * @returns {string} The HTML representation of the mention
 */
function mentionToHtml(mentionData) {
  const user = mentionData.user;
  const trigger = mentionData.trigger || '@';
  const format = mentionData.format || 'link';
  const attributes = mentionData.attributes || {};

  switch (format) {
    case 'text':
      return trigger + user.username;

    case 'link':
      const href = attributes.href || '#';
      const className = attributes.className || 'mention';
      const userId = attributes['data-user-id'] || user.id;
      const username = attributes['data-username'] || user.username;
      return `<a href="${href}" class="${className}" data-user-id="${userId}" data-username="${username}">${trigger}${user.username}</a>`;

    case 'customHtml':
      if (!mentionData.customHtmlTemplate) {
        return trigger + user.username;
      }
      return replaceMentionTemplateVariables(mentionData.customHtmlTemplate, user, trigger, attributes);

    case 'customWidget':
      // Custom widgets are handled in Flutter layer
      return trigger + user.username;

    default:
      return trigger + user.username;
  }
}

/**
 * Replace template variables in custom HTML.
 * @param {string} template - The HTML template
 * @param {Object} user - The user object
 * @param {string} trigger - The trigger character
 * @param {Object} attributes - Additional attributes
 * @returns {string} The HTML with variables replaced
 */
function replaceMentionTemplateVariables(template, user, trigger, attributes) {
  return template
    .replace(/\{trigger\}/g, trigger)
    .replace(/\{username\}/g, user.username)
    .replace(/\{displayName\}/g, user.displayName || user.username)
    .replace(/\{userId\}/g, user.id)
    .replace(/\{avatarUrl\}/g, user.avatarUrl || '')
    .replace(/\{role\}/g, user.role || '');
}

/**
 * Detect mention trigger in text at the current cursor position.
 * @param {string} text - The text content
 * @param {number} position - The cursor position
 * @param {string} trigger - The trigger character (e.g., '@')
 * @returns {Object|null} The trigger event or null if not found
 */
RE.detectMentionTrigger = function (text, position, trigger) {
  // Find the last occurrence of the trigger before the cursor position
  let lastTriggerIndex = -1;
  for (let i = position - 1; i >= 0; i--) {
    if (text[i] === trigger) {
      lastTriggerIndex = i;
      break;
    }
    // Stop at word boundaries or newlines
    if (text[i] === ' ' || text[i] === '\n' || text[i] === '\t') {
      break;
    }
  }

  if (lastTriggerIndex === -1) {
    return null;
  }

  // Extract the query (text between trigger and cursor)
  const query = text.substring(lastTriggerIndex + 1, position).trim();

  // Check if there's a space before the trigger
  const hasSpaceBefore = lastTriggerIndex === 0 || /\s/.test(text[lastTriggerIndex - 1]);

  return {
    trigger: trigger,
    query: query,
    position: lastTriggerIndex,
    hasSpaceBefore: hasSpaceBefore,
    range: {
      start: lastTriggerIndex,
      end: position
    }
  };
};

/**
 * Get the mention at the current cursor position.
 * @returns {Object|null} The mention data or null if not found
 */
RE.getMentionAtCursor = function () {
  const selection = window.getSelection();
  if (!selection.rangeCount) return null;

  const range = selection.getRangeAt(0);
  let node = range.startContainer;

  // If the cursor is in a text node, get its parent
  if (node.nodeType === 3) {
    node = node.parentElement;
  }

  // Check if the cursor is inside a mention element
  const mentionElement = node.closest('.mention, a[data-user-id]');
  if (!mentionElement) {
    return null;
  }

  return {
    userId: mentionElement.getAttribute('data-user-id'),
    username: mentionElement.getAttribute('data-username'),
    html: mentionElement.outerHTML,
    element: mentionElement
  };
};

/**
 * Replace mention text with a formatted mention.
 * @param {number} start - Start position of the mention text
 * @param {number} end - End position of the mention text
 * @param {Object} mentionData - The mention data object
 */
RE.replaceMentionText = function (start, end, mentionData) {
  const selection = window.getSelection();
  if (!selection.rangeCount) return;

  const range = selection.getRangeAt(0);

  // Get the text content
  const textContent = RE.editor.innerText || RE.editor.textContent;

  // Get the mention text to replace
  const mentionText = textContent.substring(start, end);

  // Create the mention HTML
  const mentionHtml = mentionToHtml(mentionData);

  // Replace the mention text with the mention HTML
  // This is a simplified implementation - in production, you'd need more sophisticated text node handling
  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = textContent.substring(0, start) + mentionHtml + textContent.substring(end);

  RE.editor.innerHTML = tempDiv.innerHTML;

  // Move the cursor after the mention
  const newRange = document.createRange();
  newRange.selectNodeContents(RE.editor);
  newRange.collapse(false);
  selection.removeAllRanges();
  selection.addRange(newRange);

  RE.callback();
};

/**
 * Get all mentions in the editor content.
 * @returns {Array} Array of mention objects
 */
RE.getAllMentions = function () {
  const mentions = [];
  const mentionElements = RE.editor.querySelectorAll('.mention, a[data-user-id]');

  mentionElements.forEach(function (element) {
    mentions.push({
      userId: element.getAttribute('data-user-id'),
      username: element.getAttribute('data-username'),
      html: element.outerHTML,
      element: element
    });
  });

  return mentions;
};

/**
 * Remove a mention by its user ID.
 * @param {string} userId - The user ID of the mention to remove
 */
RE.removeMention = function (userId) {
  const mentions = RE.editor.querySelectorAll(`.mention[data-user-id="${userId}"]`);
  mentions.forEach(function (mention) {
    mention.remove();
  });
  RE.callback();
};

/**
 * Update a mention by its user ID.
 * @param {string} userId - The user ID of the mention to update
 * @param {Object} newMentionData - The new mention data
 */
RE.updateMention = function (userId, newMentionData) {
  const mentions = RE.editor.querySelectorAll(`.mention[data-user-id="${userId}"]`);
  mentions.forEach(function (mention) {
    const newHtml = mentionToHtml(newMentionData);
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = newHtml;
    mention.replaceWith(tempDiv.firstChild);
  });
  RE.callback();
};

/**
 * Get the text content around the cursor for mention trigger detection.
 * @param {number} [lookBack=50] - Number of characters to look back
 * @returns {string} The text content around the cursor
 */
RE.getTextAroundCursor = function (lookBack) {
  lookBack = lookBack || 50;
  const selection = window.getSelection();
  if (!selection.rangeCount) return '';

  const range = selection.getRangeAt(0);
  let node = range.startContainer;

  // Get the text content
  const textContent = RE.editor.innerText || RE.editor.textContent;
  const cursorPosition = getCaretCharacterOffset(RE.editor);

  // Get the text before the cursor
  const start = Math.max(0, cursorPosition - lookBack);
  return textContent.substring(start, cursorPosition);
};

/**
 * Get the character offset of the caret within an element.
 * @param {HTMLElement} element - The element to get the offset in
 * @returns {number} The character offset
 */
function getCaretCharacterOffset(element) {
  const selection = window.getSelection();
  if (selection.rangeCount === 0) return 0;

  const range = selection.getRangeAt(0).cloneRange();
  range.selectNodeContents(element);
  range.setEnd(selection.getRangeAt(0).endContainer, selection.getRangeAt(0).endOffset);

  return range.toString().length;
}

/**
 * Check if the cursor is currently inside a mention or we just inserted one.
 * @returns {boolean} True if mention detection should be skipped
 */
RE.isCursorInsideMention = function () {
  // If we just inserted a mention, skip mention trigger detection
  if (_justInsertedMention) {
    return true;
  }

  const selection = window.getSelection();
  if (!selection.rangeCount) return false;

  const range = selection.getRangeAt(0);
  let node = range.startContainer;

  // If the cursor is in a text node, get its parent
  if (node.nodeType === 3) {
    node = node.parentElement;
  }

  // Check if the cursor is inside a mention element
  return node.closest('.mention, a[data-user-id]') !== null;
};

/**
 * Get the mention text at the cursor (e.g., "@username").
 * @returns {string|null} The mention text or null if not found
 */
RE.getMentionTextAtCursor = function () {
  const textAroundCursor = RE.getTextAroundCursor(50);
  const triggerEvent = RE.detectMentionTrigger(textAroundCursor, textAroundCursor.length, '@');

  if (!triggerEvent) {
    return null;
  }

  return textAroundCursor.substring(triggerEvent.position);
};
