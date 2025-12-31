// import { replaceEmojis } from './rich_editor_emoji.js';


/**
 * Copyright (C) 2020 Wasabeef
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * See about document.execCommand: https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand
 */

var RE = {};
let keyboard = true
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
var endSpace = /\s$/;

RE.currentSelection = {
    "startContainer": 0,
    "startOffset": 0,
    "endContainer": 0,
    "endOffset": 0
};

RE.editor = document.getElementById('editor');


document.addEventListener("selectionchange", function () { RE.backuprange(); });

// Initializations
RE.editor.addEventListener("focus", function () {
    if (window.onFocus && window.onFocus.postMessage) {
        window.onFocus.postMessage('focused');
    }
});

RE.editor.addEventListener("blur", function () {
    if (window.onBlur && window.onBlur.postMessage) {
        window.onBlur.postMessage('blurred');
    }
});

RE.callback = function () {
    // Debounce callback to prevent infinite loops
    const currentHtml = RE.getHtml();

    // Only trigger if HTML has actually changed
    if (currentHtml !== lastCallbackHtml) {
        if (callbackTimeout) {
            clearTimeout(callbackTimeout);
        }

        callbackTimeout = setTimeout(function () {
            lastCallbackHtml = currentHtml;
            wrapText();
            // Use JavaScriptChannel if available, fallback to URL scheme
            if (window.onTextChange && window.onTextChange.postMessage) {
                window.onTextChange.postMessage(currentHtml);
            } else {
                window.location.href = "re-callback://" + encodeURIComponent(currentHtml);
            }
            RE.enabledEditingItems();
        }, 100); // 100ms debounce
    }
};


RE.setHtml = function (contents) {
    RE.editor.innerHTML = decodeURIComponent(contents.replace(/\+/g, '%20'));
}

RE.insertBlockQuote = function (contents) {
    RE.editor.innerHTML += decodeURIComponent(contents.replace(/\+/g, '%20'));
    // Move cursor to the end
    var range = document.createRange();
    var selection = window.getSelection();

    range.selectNodeContents(RE.editor);
    range.collapse(false); // Collapse to the end

    selection.removeAllRanges();
    selection.addRange(range);
    wrapText()
    RE.callback();
}

RE.getHtml = function () {
    return RE.editor.innerHTML;
}

RE.getText = function () {
    return RE.editor.innerText;
}

RE.setBaseTextColor = function (color) {
    RE.editor.style.color = color;
}

RE.setBaseFontSize = function (size) {
    RE.editor.style.fontSize = size;
}

RE.setPadding = function (left, top, right, bottom) {
    RE.editor.style.paddingLeft = left;
    RE.editor.style.paddingTop = top;
    RE.editor.style.paddingRight = right;
    RE.editor.style.paddingBottom = bottom;
}

RE.setBackgroundColor = function (color) {
    document.body.style.backgroundColor = color;
}

RE.setBackgroundImage = function (image) {
    RE.editor.style.backgroundImage = image;
}

RE.setWidth = function (size) {
    RE.editor.style.minWidth = size;
}

RE.setHeight = function (size) {
    RE.editor.style.height = size;
}

RE.setTextAlign = function (align) {
    RE.editor.style.textAlign = align;
}

RE.setVerticalAlign = function (align) {
    RE.editor.style.verticalAlign = align;
}

RE.setPlaceholder = function (placeholder) {
    RE.editor.setAttribute("placeholder", placeholder);
}

RE.setInputEnabled = function (inputEnabled) {
    RE.editor.contentEditable = String(inputEnabled);
}

RE.undo = function () {
    document.execCommand('undo', false, null);
}

RE.redo = function () {
    document.execCommand('redo', false, null);
}

RE.setBold = function () {
    document.execCommand('bold', false, null);
    const newBoldState = document.queryCommandState('bold');
    if (newBoldState !== lastStates.bold) {
        lastStates.bold = newBoldState;
        window.Android?.onBoldChanged(newBoldState);
    }
}

RE.setItalic = function () {
    document.execCommand('italic', false, null);
    const newItalic = document.queryCommandState('italic');
    if (newItalic !== lastStates.italic) {
        lastStates.italic = newItalic;
        window.Android?.onItalicChanged(newItalic);
    }
}

RE.setSubscript = function () {
    document.execCommand('subscript', false, null);
}

RE.setSuperscript = function () {
    document.execCommand('superscript', false, null);
}

RE.setStrikeThrough = function () {
    document.execCommand('strikeThrough', false, null);
    lastStates.strikeThrough = !lastStates.strikeThrough;
    window.Android?.onStrikeThroughChanged(lastStates.strikeThrough);
}

RE.setUnderline = function () {
    document.execCommand('underline', false, null);
    lastStates.underline = !lastStates.underline;
    window.Android?.onUnderlineChanged(lastStates.underline);
}

RE.setBullets = setBullet


RE.setNumbers = setNumber

RE.setTextColor = function (color) {
    RE.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('foreColor', false, color);
    document.execCommand("styleWithCSS", null, false);
}

RE.setTextBackgroundColor = function (color) {
    RE.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('hiliteColor', false, color);
    document.execCommand("styleWithCSS", null, false);
}

RE.setFontSize = function (fontSize) {
    document.execCommand("fontSize", false, fontSize);
}

RE.setHeading = function (heading) {
    document.execCommand('formatBlock', false, '<h' + heading + '>');
}

RE.setIndent = function () {
    document.execCommand('indent', false, null);
}

RE.setOutdent = function () {
    document.execCommand('outdent', false, null);
}

RE.setJustifyLeft = function () {
    document.execCommand('justifyLeft', false, null);
}

RE.setJustifyCenter = function () {
    document.execCommand('justifyCenter', false, null);
}

RE.setJustifyRight = function () {
    document.execCommand('justifyRight', false, null);
}

RE.setBlockquote = setBlockQuotes

RE.insertImage = function (url, alt) {
    var html = '<img src="' + url + '" alt="' + alt + '" />';
    RE.insertHTML(html);
}

RE.insertImageAttach = function (url, dataAttachment) {
    var html = '<img src="' + url + '" data-attachment="' + dataAttachment + '" />';
    RE.insertHTML(html);
}

RE.insertEmoji = function (emojiData) {
    // emojiData is a JSON object with properties: id, name, imageUrl, category, metadata, etc.
    const url = emojiData.imageUrl || '';
    const alt = emojiData.metadata?.alt || emojiData.name || emojiData.shortcodes || 'emoji';
    const className = 'emoji';

    var html = '<img src="' + url + '" class="' + className + '" alt="' + alt + '" data-emoji-id="' + emojiData.id + '" />';
    RE.insertHTML(html);
}



RE.insertImageW = function (url, alt, width) {
    var html = '<img src="' + url + '" alt="' + alt + '" width="' + width + '"/>';
    RE.insertHTML(html);
}

RE.insertImageWH = function (url, alt, width, height) {
    var html = '<img src="' + url + '" alt="' + alt + '" style="width:' + width + 'px; height:' + height + 'px;" />';
    RE.insertHTML(html);
}

RE.insertVideo = function (url, alt) {
    var html = '<video src="' + url + '" controls></video><br>';
    RE.insertHTML(html);
}

RE.insertVideoW = function (url, width) {
    var html = '<video src="' + url + '" width="' + width + '" controls></video><br>';
    RE.insertHTML(html);
}

RE.insertVideoWH = function (url, width, height) {
    var html = '<video src="' + url + '" width="' + width + '" height="' + height + '" controls></video><br>';
    RE.insertHTML(html);
}

RE.insertAudio = function (url, alt) {
    var html = '<audio src="' + url + '" controls></audio><br>';
    RE.insertHTML(html);
}

RE.insertMediaBBCode = function (data) {
    var html = data;
    RE.insertHTML(html);
}

RE.insertYoutubeVideo = function (url) {
    const videoData = extractYouTubeVideoIdAndTime(url);
    console.log(videoData);
    if (!videoData) {
        console.log("Invalid YouTube URL.");
        return;
    }
    const formattedMediaTag = `[MEDIA=youtube]${videoData}[/MEDIA]`;
    RE.insertHTML(formattedMediaTag);
};

RE.insertYoutubeVideoW = function (url, width) {
    var html = '<iframe width="' + width + '" src="' + url + '" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe><br>'
    RE.insertHTML(html);
}

RE.insertYoutubeVideoWH = function (url, width, height) {
    var html = '<iframe width="' + width + '" height="' + height + '" src="' + url + '" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe><br>'
    RE.insertHTML(html);
}

RE.insertHTML = function (html) {
    RE.restorerange();
    document.execCommand('insertHTML', false, html);
}

RE.insertLink = function (url, title) {
    RE.restorerange();
    var sel = document.getSelection();
    if (sel.toString().length == 0) {
        document.execCommand("insertHTML", false, "<a href='" + url + "'>" + title + "</a>");
    } else if (sel.rangeCount) {
        var el = document.createElement("a");
        el.setAttribute("href", url);
        el.setAttribute("title", title);

        var range = sel.getRangeAt(0).cloneRange();
        range.surroundContents(el);
        sel.removeAllRanges();
        sel.addRange(range);
    }
    RE.callback();
}



RE.setTodo = function (text) {
    var html = '<input type="checkbox" name="' + text + '" value="' + text + '"/> &nbsp;';
    document.execCommand('insertHTML', false, html);
}

RE.prepareInsert = function () {
    RE.backuprange();
}

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
}

RE.restorerange = function () {
    var selection = window.getSelection();
    selection.removeAllRanges();
    var range = document.createRange();
    range.setStart(RE.currentSelection.startContainer, RE.currentSelection.startOffset);
    range.setEnd(RE.currentSelection.endContainer, RE.currentSelection.endOffset);
    selection.addRange(range);
}

RE.enabledEditingItems = function (e) {
    var items = [];
    const states = {
        bold: document.queryCommandState('bold'),
        italic: document.queryCommandState('italic'),
        underline: document.queryCommandState('underline'),
        strikeThrough: document.queryCommandState('strikeThrough'),
        unorderedList: document.queryCommandState('insertUnorderedList'),
        orderedList: document.queryCommandState('insertOrderedList'),
        justifyLeft: document.queryCommandState('justifyLeft'),
        justifyCenter: document.queryCommandState('justifyCenter'),
        justifyRight: document.queryCommandState('justifyRight')
    };

    if (document.queryCommandState('bold')) {
        items.push('bold');
    }
    if (document.queryCommandState('italic')) {
        items.push('italic');
    }
    if (document.queryCommandState('subscript')) {
        items.push('subscript');
    }
    if (document.queryCommandState('superscript')) {
        items.push('superscript');
    }
    if (document.queryCommandState('strikeThrough')) {
        items.push('strikeThrough');
    }
    if (document.queryCommandState('underline')) {
        items.push('underline');
    }
    if (document.queryCommandState('insertOrderedList')) {
        items.push('orderedList');
    }
    if (document.queryCommandState('insertUnorderedList')) {
        items.push('unorderedList');
    }
    if (document.queryCommandState('justifyCenter')) {
        items.push('justifyCenter');
    }
    if (document.queryCommandState('justifyFull')) {
        items.push('justifyFull');
    }
    if (document.queryCommandState('justifyLeft')) {
        items.push('justifyLeft');
    }
    if (document.queryCommandState('justifyRight')) {
        items.push('justifyRight');
    }
    if (document.queryCommandState('insertHorizontalRule')) {
        items.push('horizontalRule');
    }
    var formatBlock = document.queryCommandValue('formatBlock');
    if (formatBlock.length > 0) {
        items.push(formatBlock);
    }

    const stateString = items.join(',');

    // Debounce state updates to prevent infinite loops
    if (stateString !== lastStateString) {
        if (stateCallbackTimeout) {
            clearTimeout(stateCallbackTimeout);
        }

        stateCallbackTimeout = setTimeout(function () {
            lastStateString = stateString;
            // Use JavaScriptChannel if available, fallback to URL scheme
            if (window.onDecorationState && window.onDecorationState.postMessage) {
                window.onDecorationState.postMessage(stateString);
            } else {
                window.location.href = "re-state://" + encodeURI(stateString);
            }
        }, 50); // 50ms debounce
    }
    if (states.bold !== lastStates.bold) {
        lastStates.bold = states.bold;
        window.Android?.onBoldChanged(lastStates.bold);
    }
    if (states.italic !== lastStates.italic) {
        lastStates.italic = states.italic
        window.Android?.onItalicChanged(lastStates.italic);
    }
    if (states.underline !== lastStates.underline) {
        lastStates.underline = states.underline;
        window.Android?.onUnderlineChanged(lastStates.underline);
    }
    if (states.strikeThrough !== lastStates.strikeThrough) {
        lastStates.strikeThrough = states.strikeThrough;
        window.Android?.onStrikeThroughChanged(lastStates.strikeThrough);
    }
    // console.log(states)
    // console.log(items)
}

RE.focus = function () {
    var range = document.createRange();
    range.selectNodeContents(RE.editor);
    range.collapse(false);
    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    RE.editor.focus();
    keyboard = false
}


RE.blurFocus = function () {
    RE.editor.blur();
    keyboard = true
}

RE.scrollToCursor = scrollToCursorHelp

RE.removeFormat = function () {
    document.execCommand('removeFormat', false, null);
}

RE.editor.addEventListener("input", function (e) {
    RE.callback();

    // DEBUG: Log input events
    console.log('DEBUG: input event - data:', e.data, 'inputType:', e.inputType);

    // Check if user typed space - hide mention bottom sheet
    if (e.data === ' ' || e.inputType === 'insertText' && e.data === ' ') {
        console.log('DEBUG: Space typed, hiding mention bottom sheet');
        if (window.hideMentionBottomSheet && window.hideMentionBottomSheet.postMessage) {
            window.hideMentionBottomSheet.postMessage('');
        }
        return;
    }

    // Check for mention trigger (@) - only if cursor is NOT inside a mention
    if (!RE.isCursorInsideMention()) {
        const textAroundCursor = RE.getTextAroundCursor(50);
        console.log('DEBUG: Text around cursor:', textAroundCursor);
        if (endSpace.test(textAroundCursor)) {
            console.log('DEBUG: ends with space, hiding mention bottom sheet');
            if (window.hideMentionBottomSheet && window.hideMentionBottomSheet.postMessage) {
                window.hideMentionBottomSheet.postMessage('');
            }
            return;
        }

        const triggerEvent = RE.detectMentionTrigger(textAroundCursor, textAroundCursor.length, '@');
        console.log('DEBUG: Mention trigger detected:', triggerEvent);

        if (triggerEvent && triggerEvent.query.length >= 1) {
            console.log('DEBUG: Triggering mention with query:', triggerEvent.query);
            // Send mention trigger to Flutter
            if (window.getMentionTextAtCursor && window.getMentionTextAtCursor.postMessage) {
                const mentionText = textAroundCursor.substring(triggerEvent.position);
                window.getMentionTextAtCursor.postMessage(mentionText);
            }
        }
    }
});

RE.editor.addEventListener("keyup", function (e) {
    var KEY_LEFT = 37, KEY_RIGHT = 39;
    if (e.which == KEY_LEFT || e.which == KEY_RIGHT) {
        RE.enabledEditingItems(e);
    }
});
RE.editor.addEventListener("click", RE.enabledEditingItems);

RE.editor.addEventListener("keydown", function (e) {
    const selection = window.getSelection();
    if (!selection.rangeCount) return;

    const range = selection.getRangeAt(0);
    let currentNode = range.startContainer;

    // Normalize text nodes to their parent elements
    if (currentNode.nodeType === 3) {
        currentNode = currentNode.parentElement;
    }

    // DEBUG: Log keydown events
    console.log('DEBUG: keydown event - key:', e.key, 'code:', e.code);

    if (e.key === "Enter" && RE.editor.innerHTML.trim() === "") {
        e.preventDefault();

        // Create an empty paragraph
        const newP = document.createElement("p");
        newP.innerHTML = "<br>";

        // Append the paragraph to the editor
        RE.editor.appendChild(newP);

        // Move cursor to the new paragraph
        setCursorAtElement(newP, selection);
        return;
    }

    const blockquote = currentNode.closest("blockquote");
    const listItem = currentNode.closest("li");
    const list = currentNode.closest("ol, ul");

    // Exit early if not pressing Enter
    if (e.key !== "Enter") return;

    // Handle exiting list when pressing Enter on an empty <li>
    if (listItem) {
        if (listItem.innerHTML.trim() === "<br>") {
            e.preventDefault();
            exitList(list, listItem, selection);
        }
    }

    // Handle exiting blockquote when pressing Enter in the last empty <p>
    if (blockquote) {
        const paragraphs = Array.from(blockquote.querySelectorAll("p"));
        if (paragraphs.length < 2) return
        const lastParagraph = paragraphs[paragraphs.length - 1];
        const lastParagraph2 = paragraphs[paragraphs.length - 2];
        console.log(lastParagraph, lastParagraph2)
        let nodeBlock = currentNode
        while (true) {
            if (nodeBlock.parentElement.tagName !== "BLOCKQUOTE") {
                nodeBlock = nodeBlock.parentElement
            } else break
        }
        if (nodeBlock === lastParagraph && lastParagraph.innerHTML === lastParagraph2.innerHTML) {
            e.preventDefault();
            exitBlockquote(blockquote, lastParagraph, selection);
        }
        return;
    }
});
// Function to exit a blockquote and move cursor to a new paragraph
function exitBlockquote(blockquote, lastParagraph, selection) {
    // Create a new <p> outside the blockquote
    const newP = document.createElement("p");
    newP.innerHTML = "<br>";

    // Insert new <p> after the blockquote
    blockquote.after(newP);

    // Remove the last empty paragraph inside the blockquote
    console.log(lastParagraph.previousElementSibling.remove())
    lastParagraph.remove();


    // If the blockquote is now empty, remove it
    if (blockquote.innerHTML.trim() === "") {
        blockquote.remove();
    }

    // Move cursor inside the new <p>
    setCursorAtElement(newP, selection);

    console.log("Exited blockquote, cursor moved to new <p>");
}

// Function to exit a list and move cursor to a new paragraph
function exitList(list, listItem, selection) {
    // Create a new <p> after the list
    const newP = document.createElement("p");
    newP.innerHTML = "<br>";
    list.after(newP);

    // Remove the empty <li>
    listItem.remove();

    // If the list is now empty, remove it
    if (list.innerHTML.trim() === "") {
        list.remove();
    }

    // Move cursor to the new paragraph
    setCursorAtElement(newP, selection);

    console.log("Exited list and created new <p>");
}

// Function to move the cursor inside a newly created element
function setCursorAtElement(element, selection) {
    const newRange = document.createRange();
    newRange.selectNodeContents(element);
    newRange.collapse(true);

    selection.removeAllRanges();
    selection.addRange(newRange);
}

// Global Click Handler
document.addEventListener('DOMContentLoaded', () => {
    const editor = document.getElementById('editor');
    document.addEventListener('click', (e) => {
        const target = e.target;

        if (target.tagName === 'IMG') {
            // Toggle display style
            const currentDisplay = target.style.display;

            if (currentDisplay === 'block') {
                target.style.display = 'inline';
            } else {
                target.style.display = 'block';
            }

            // Optional: Focus the image to indicate it's selected (visual cue)
            target.style.outline = '2px dashed #00f';
            setTimeout(() => {
                target.style.outline = '';
            }, 500);
        }


        if (!editor.contains(target)) {
            const target = e.target;
            if (keyboard) {
                window.Android?.onClickEditor();
                RE.focus();
            } else keyboard = true
        }

    });
});





window.RE = RE;
