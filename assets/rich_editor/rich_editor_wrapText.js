function wrapText(nodes) {
    if (!nodes) {
        const editor = RE.editor;
        nodes = [...editor.childNodes];
    }

    const selectionDetails = window.getSelectionRangeDetails();
    let startNode = selectionDetails?.startContainer ?? null;
    let endNode = selectionDetails?.endContainer ?? null;
    const startOffset = selectionDetails?.startOffset ?? null;
    const endOffset = selectionDetails?.endOffset ?? null;

    const childNodes = nodes;
    let nodesToWrap = [];

    const wrapCollectedNodes = () => {
        if (nodesToWrap.length === 0) return;

        const firstNode = nodesToWrap[0];
        let p = firstNode.previousElementSibling;
        console.log(childNodes, !p || p.tagName !== "P")
        if (!p || p.tagName !== "P") {
            p = document.createElement("p");
            firstNode.parentNode.insertBefore(p, firstNode);
        }

        nodesToWrap.forEach((node, index) => {
            if (node.tagName === "BR") {
                const pChild = document.createElement("p");
                pChild.appendChild(node)
                if (startNode === node) startNode = pChild;
                if (endNode === node) endNode = pChild;
                node.remove()
                p = pChild;
            } else {
                p.appendChild(node);
            }
        });
        nodesToWrap = [];
    };

    const replaceParent = (node) => {
        const p = document.createElement("p");
        node.parentNode.insertBefore(p, node.nextSibling);
        while (node.firstChild) {
            p.appendChild(node.firstChild);
        }
        node.remove();
        // Update startNode/endNode if they match the replaced <DIV>
        if (startNode === node) startNode = p;
        if (endNode === node) endNode = p;
    };

    childNodes.forEach(node => {
        if (node.tagName === "DIV") {
            replaceParent(node);
            return;
        } else if (node.tagName === "P") {
            const pChildNodes = [...node.childNodes];
            if (pChildNodes.length > 0 && pChildNodes.every(child => ["UL", "OL"].includes(child.tagName))) {
                const movedNodes = [];
                while (node.firstChild) {
                    const child = node.firstChild;
                    node.parentNode.insertBefore(child, node);
                    movedNodes.push(child);
                }
                node.remove();
                if (startNode === node) startNode = movedNodes[0].firstChild || movedNodes[0];
                if (endNode === node) endNode = movedNodes[movedNodes.length - 1].firstChild || movedNodes[movedNodes.length - 1];
                if (movedNodes.some(moved => moved.contains(startNode))) {
                    startNode = moved.contains(startNode) ? startNode : movedNodes[0].firstChild || movedNodes[0];
                }
                if (movedNodes.some(moved => moved.contains(endNode))) {
                    endNode = moved.contains(endNode) ? endNode : movedNodes[movedNodes.length - 1].firstChild || movedNodes[movedNodes.length - 1];
                }
            } else if (!node.hasChildNodes()) {
                const br = document.createElement("br");
                node.appendChild(br);
                if (startNode === node) startNode = br;
                if (endNode === node) endNode = br;
            }
        } else if (["I", "B", "S", "SPAN", "BR", "IMG"].includes(node.tagName)) {
            nodesToWrap.push(node);
        } else if (node.tagName === "BLOCKQUOTE") {
            wrapText(node.childNodes);
        } else if (node.nodeType === Node.TEXT_NODE && node.textContent.trim().length > 0) {
            nodesToWrap.push(node);
        }
    });

    wrapCollectedNodes();

    // Validate and set the range using updated startNode/endNode
    // Re-check the current selection state
    const currentSelection = window.getSelectionRangeDetails();
    const currentStartNode = currentSelection?.startContainer ?? null;
    const currentEndNode = currentSelection?.endContainer ?? null;
    const currentStartOffset = currentSelection?.startOffset ?? null;
    const currentEndOffset = currentSelection?.endOffset ?? null;

    // Only set the range if it has changed or is invalid
    if (
        startNode && endNode && startOffset !== null && endOffset !== null &&
        (currentStartNode !== startNode || currentEndNode !== endNode ||
            currentStartOffset !== startOffset || currentEndOffset !== endOffset)
    ) {
        const newRange = document.createRange();
        try {
            newRange.setStart(startNode, startOffset);
            newRange.setEnd(endNode, endOffset);
            const selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(newRange);
        } catch (e) {
            console.error("Failed to set range:", e);
            // Fallback: collapse selection to start if invalid
            newRange.setStart(startNode, startOffset);
            newRange.collapse(true);
            selection.removeAllRanges();
            selection.addRange(newRange);
        }
    }
}

function setCursorAfterElement(element) {
    const range = document.createRange();
    const selection = window.getSelection();
    range.setStartAfter(element);
    range.collapse(true);
    selection.removeAllRanges();
    selection.addRange(range);
}



function scrollToCursorHelp(container = RE.editor) {
    if (!document.activeElement === RE.editor && !RE.editor.contains(document.activeElement)) {
        console.log("RE.editor is not focused, skipping scroll");
        return;
    }

    const selectionDetails = window.getSelectionRangeDetails();
    const startNode = selectionDetails?.startContainer ?? null;
    const startOffset = selectionDetails?.startOffset ?? 0;

    if (!startNode || startOffset === null) return;

    let targetElement = startNode.nodeType === Node.TEXT_NODE ? startNode.parentElement : startNode;

    if (!targetElement || !document.body.contains(targetElement)) return;

    const range = document.createRange();
    try {
        range.setStart(startNode, startOffset);
        range.collapse(true);

        const rects = range.getClientRects();
        const viewportHeight = window.innerHeight;
        const buffer = 50;

        if (rects.length > 0) {
            const cursorRect = rects[0];
            const cursorTop = cursorRect.top + window.scrollY;
            const cursorBottom = cursorRect.bottom + window.scrollY;
            const visibleAreaBottom = window.scrollY + viewportHeight - buffer;
            const visibleAreaTop = window.scrollY + buffer;

            // Check if cursor is outside visible area (above or below)
            if (cursorBottom > visibleAreaBottom || cursorTop < visibleAreaTop) {
                // For end-of-content, bias towards showing the cursor lower in viewport
                const scrollY = cursorBottom - viewportHeight + buffer * 2; // Position cursor near bottom with buffer
                window.scrollTo({
                    top: Math.max(0, scrollY), // Prevent negative scroll
                    behavior: 'smooth'
                });
            }
        } else {
            targetElement.scrollIntoView({ behavior: 'smooth', block: 'end' }); // Changed to 'end' from 'center'
        }
    } catch (e) {
        console.error("Error scrolling:", e);
        targetElement.scrollIntoView({ behavior: 'smooth', block: 'end' });
    }
}

window.scrollToCursorHelp = scrollToCursorHelp;
window.wrapText = wrapText;