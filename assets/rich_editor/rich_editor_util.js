// Return all parent block in editor
// editor [p(text), p, img]
// return p, p, img
function getHighlightedNodes() {
    const selection = window.getSelection();
    if (!selection.rangeCount) {
        console.log("Nothing is selected.");
        return [];
    }

    const range = selection.getRangeAt(0);
    const commonAncestor = range.commonAncestorContainer;

    // Helper to climb to the top non-editor parent
    const getTopNonEditorParent = (node) => {
        let current = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
        while (current && current.parentElement?.id !== 'editor') {
            current = current.parentElement;
        }
        return current?.id !== 'editor' ? current : null;
    };

    // Handle collapsed selection (cursor)
    if (selection.isCollapsed) {
        const topParent = getTopNonEditorParent(range.startContainer);
        return topParent ? [topParent] : [];
    }

    // Handle highlighted text
    const selectedNodes = new Set(); // Use Set for automatic deduplication

    if (commonAncestor.id === 'editor') {
        for (const node of commonAncestor.children) {
            if (range.intersectsNode(node)) {
                const topParent = getTopNonEditorParent(node);
                if (topParent) selectedNodes.add(topParent);
            }
        }
    } else {
        const startNode = getTopNonEditorParent(range.startContainer);
        const endNode = getTopNonEditorParent(range.endContainer);

        if (startNode && endNode) {
            if (startNode === endNode) {
                selectedNodes.add(startNode);
            } else {
                // If selection spans multiple nodes, check all siblings between start and end
                let current = startNode;
                while (current && current !== endNode) {
                    if (range.intersectsNode(current)) {
                        selectedNodes.add(current);
                    }
                    current = current.nextSibling;
                }
                if (range.intersectsNode(endNode)) {
                    selectedNodes.add(endNode);
                }
            }
        }
    }

    return Array.from(selectedNodes);
}



// It will call -> getHighlightedNodes
// Then loops in there, if you want any tag that unwrap,
// It will automatic unwrap for ya
// and return true if it wrapped, and also list of node
function getWholeBlockFromSelection(unWrap) {
    const sel = document.getSelection();
    let didUnrap = false
    if (!sel || sel.rangeCount === 0) {
        return { nodes: [], didUnrap };
    }

    const range = sel.getRangeAt(0);
    const selectedNodes = [];
    // Get the editor element (adjust this selector based on your setup)
    const editor = getHighlightedNodes();
    if (!editor) {
        console.log('Editor not found');
        return [];
    }

    // Loop through all child nodes of the editor
    editor.forEach(node => {
        if (range.intersectsNode(node)) {
            if (unWrap != null && node.nodeName === unWrap) {
                const unWrapNode = unwrapBlock(node)
                selectedNodes.push(...unWrapNode);
                didUnrap = true
            } else selectedNodes.push(node);
        }
    });

    return {
        nodes: selectedNodes,
        didUnrap: didUnrap
    };
}


// Get first node and last node
function getFirstTextNode(node) {
    console.log(node);
    if (node.nodeType === Node.TEXT_NODE) return node;
    for (let child of node.childNodes) {
        let found = getFirstTextNode(child);
        if (found) return found;
    }
    return node; // Instead of null, return the original node
}

function getLastTextNode(node) {
    if (node.nodeType === Node.TEXT_NODE) return node;
    for (let i = node.childNodes.length - 1; i >= 0; i--) {
        let found = getLastTextNode(node.childNodes[i]);
        if (found) return found;
    }
    return node;
}
function setRange(firstNode, lastNode, startOffset, endOffset) {
    const range = document.createRange();
    const selection = window.getSelection();
    range.setStart(firstNode, startOffset);
    range.setEnd(lastNode, endOffset);
    selection.removeAllRanges();
    selection.addRange(range);
}


// Get range that current selected
function getSelectionRangeDetails() {
    const sel = document.getSelection();
    if (!sel || sel.rangeCount === 0) {
        return null;
    }

    const range = sel.getRangeAt(0);

    return {
        startContainer: range.startContainer,  // The node where the selection starts
        startOffset: range.startOffset,        // Character offset within startContainer
        endContainer: range.endContainer,      // The node where the selection ends
        endOffset: range.endOffset             // Character offset within endContainer
    };
}


// If there is a block unwant,
// If p inside blockquote
// Then remove blockquote, only p
function unwrapBlock(TAGName) {
    let insertNode = []
    const parent = TAGName.parentNode;
    while (TAGName.firstChild) {
        insertNode.push(parent.insertBefore(TAGName.firstChild, TAGName))
    }
    parent.removeChild(TAGName);
    return insertNode
}


function extractYouTubeVideoIdAndTime(url) {
    const regex = /(?:https?:\/\/(?:www\.)?(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11}))(?:.*(?:[?&]t=)(\d+))?/;
    const match = url.match(regex);
    if (match) {
        const videoId = match[1];        // Video ID (e.g., "7-Rsu2GFrM0")
        const time = match[2];           // Time (e.g., "1812" or undefined)
        return time ? `${videoId}:${time}` : videoId; // Return "id:time" if time exists, else just "id"
    }
    return null;
}

window.getLastTextNode = getLastTextNode;
window.getFirstTextNode = getFirstTextNode;
window.getHighlightedNodes = getHighlightedNodes;
window.getWholeBlockFromSelection = getWholeBlockFromSelection;
window.setRange = setRange;
window.getSelectionRangeDetails = getSelectionRangeDetails;
window.unwrapBlock = unwrapBlock;