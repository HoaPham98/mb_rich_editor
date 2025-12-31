//Ayray contains node
function getAllNestedNodes(nodes, startNode, endNode) {
    let allNodes = new Set(); // Use a Set to avoid duplicates
    let startChild, endChild
    function traverse(node) {
        if (node.nodeType === Node.ELEMENT_NODE) {
            let text = node.textContent?.trim() || ""; // Ensure textContent exists
            let startText = startNode?.textContent?.trim() || "";
            let endText = endNode?.textContent?.trim() || "";

            if (startNode && text === startText) startChild = node;
            if (endNode && text === endText) endChild = node;
            allNodes.add(node);
        }
        for (let child of node.childNodes) {
            traverse(child);
        }
    }

    // Loop through each node in the provided array
    for (let node of nodes) {
        traverse(node);
    }

    return { node: Array.from(allNodes), start: startChild, end: endChild }; // Convert Set to array before returning
}

function setBlockQuotes() {
    const rangeDetails = getSelectionRangeDetails();
    const result = getWholeBlockFromSelection("BLOCKQUOTE");

    if (result.didUnrap) {
        const firstNode = result.nodes[0];
        const lastNode = result.nodes[result.nodes.length - 1];

        // Find first and last text nodes
        const firstTextNode = getFirstTextNode(firstNode) || firstNode;
        const lastTextNode = getLastTextNode(lastNode) || lastNode;

        setRange(firstTextNode, lastTextNode, 0, lastTextNode.textContent.length);
    }
     else {
        const block = result.nodes;
        const newBlockquote = document.createElement("blockquote");

        if (block.length > 0) {
            block.forEach(node => newBlockquote.appendChild(node.cloneNode(true)));
            block[0].parentNode.replaceChild(newBlockquote, block[0]);
            for (let i = 1; i < block.length; i++) {
                block[i].parentNode.removeChild(block[i]);
            }

            // **Set range to the whole blockquote**
            setRange(newBlockquote, newBlockquote, 0, newBlockquote.childNodes.length);
        } else {
            const newP = document.createElement("p");
            newP.appendChild(document.createElement("br"));
            newBlockquote.appendChild(newP);

            const targetParent = rangeDetails.startContainer.nodeType === Node.TEXT_NODE
                ? rangeDetails.startContainer.parentNode
                : rangeDetails.startContainer;
            targetParent.appendChild(newBlockquote);

            // **Set range to the blockquote itself**
            setRange(newBlockquote, newBlockquote, 0, 0);
        }
    }
}



function setNumber() {
    const before = getSelectionRangeDetails();
    if (!before) return;
    const wasCollapsed = window.getSelection().isCollapsed;
    // Step 2: Apply ordered list
    document.execCommand('insertOrderedList', false, null);
    // Step 3: Get updated blocks
    const nodes = getHighlightedNodes();
    if (!nodes || nodes.length === 0) return;

    if (wasCollapsed) {
        // Just restore cursor
        const cursorNode = getFirstTextNode(nodes[0]);
        const offset = Math.min(before.startOffset, cursorNode.textContent.length);
        setRange(cursorNode, cursorNode, offset, offset);
    } else {
        // Expand selection over whole blocks
        const firstNode = getFirstTextNode(nodes[0]);
        const lastNode = getLastTextNode(nodes[nodes.length - 1]);
        setRange(firstNode, lastNode, 0, lastNode.textContent.length);
    }
    wrapText()
}

function setBullet(){
    const before = getSelectionRangeDetails();
    if (!before) return;
    const wasCollapsed = window.getSelection().isCollapsed;
    // Step 2: Apply ordered list

    document.execCommand('insertUnorderedList', false, null);

    const nodes = getHighlightedNodes();
    if (!nodes || nodes.length === 0) return;

    if (wasCollapsed) {
        // Just restore cursor
        const cursorNode = getFirstTextNode(nodes[0]);
        const offset = Math.min(before.startOffset, cursorNode.textContent.length);
        setRange(cursorNode, cursorNode, offset, offset);
    } else {
        // Expand selection over whole blocks
        const firstNode = getFirstTextNode(nodes[0]);
        const lastNode = getLastTextNode(nodes[nodes.length - 1]);
        setRange(firstNode, lastNode, 0, lastNode.textContent.length);
    }
    wrapText()
}

window.setBlockQuotes = setBlockQuotes;