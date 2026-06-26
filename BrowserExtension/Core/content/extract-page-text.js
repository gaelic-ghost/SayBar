(function installSayBarPageTextExtractor(globalObject) {
  const maximumCharacterCount = 50000;
  const maximumHTMLCharacterCount = 300000;

  function candidateRoot() {
    return document.querySelector("article")
      || document.querySelector("main")
      || document.querySelector("[role='main']")
      || document.body
      || document.documentElement;
  }

  function visibleTextFrom(root) {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode(node) {
        const text = node.textContent || "";
        if (!text.trim()) {
          return NodeFilter.FILTER_REJECT;
        }

        const parentElement = node.parentElement;
        if (!parentElement) {
          return NodeFilter.FILTER_REJECT;
        }

        const tagName = parentElement.tagName.toLowerCase();
        if (["script", "style", "noscript", "template", "svg"].includes(tagName)) {
          return NodeFilter.FILTER_REJECT;
        }

        const style = window.getComputedStyle(parentElement);
        if (style.display === "none" || style.visibility === "hidden") {
          return NodeFilter.FILTER_REJECT;
        }

        return NodeFilter.FILTER_ACCEPT;
      }
    });

    const chunks = [];
    let characterCount = 0;
    let node = walker.nextNode();
    while (node && characterCount < maximumCharacterCount) {
      const chunk = node.textContent.trim();
      characterCount += chunk.length + 1;
      chunks.push(chunk);
      node = walker.nextNode();
    }

    return chunks
      .join(" ")
      .replace(/\s+/g, " ")
      .trim()
      .slice(0, maximumCharacterCount);
  }

  globalObject.saybarExtractPageText = function saybarExtractPageText() {
    const root = candidateRoot();
    const text = root ? visibleTextFrom(root) : "";
    const html = root && root.outerHTML ? root.outerHTML.slice(0, maximumHTMLCharacterCount) : "";

    return {
      title: document.title || "",
      url: location.href,
      text,
      html,
      captureMode: root ? root.tagName.toLowerCase() : "page",
      capturedAt: new Date().toISOString()
    };
  };
})(globalThis);
