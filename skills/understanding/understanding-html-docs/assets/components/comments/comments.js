/* comments component — a Google-Docs-style review layer for an
   understanding-html-docs document.

   Vanilla JS, no dependencies, no build step, no network. It layers on top of a
   page that already reads correctly: select text (or right-click a block) inside
   the document, write a comment, and it appears in a list panel in the right
   gutter. Comments persist to localStorage keyed per document, and can be
   exported/imported as JSON (round-trip) or Markdown (for a human or an agent).

   It deliberately does NOT depend on base.js: the anchor scope is `main` (not
   `main article`), so it works both on a base.js reading page and on an
   understanding-explain-diff page (many `article.chunk` under `main`, no base.js).

   Anchoring uses the CSS Custom Highlight API so the document DOM is never
   mutated (no wrapper <mark>): the highlight is painted over a Range rebuilt from
   a stored text quote. Browsers without the API fall back to a class on the
   block. Nothing here carries a semantic meaning-color — comments are chrome. */
(function () {
  "use strict";

  var scope = document.querySelector("main");
  if (!scope) return;

  /* ---------- identity + storage --------------------------------------- */
  function docId() {
    var m = document.querySelector('meta[name="comments-doc-id"]');
    if (m && m.content) return m.content;
    return location.pathname + "::" + (document.title || "");
  }
  var STORE_KEY = "html-docs-comments:" + docId();

  var comments = [];
  function load() {
    try {
      var raw = localStorage.getItem(STORE_KEY);
      comments = raw ? JSON.parse(raw) : [];
      if (!Array.isArray(comments)) comments = [];
    } catch (e) { comments = []; }
  }
  function persist() {
    try {
      localStorage.setItem(STORE_KEY, JSON.stringify(comments.map(function (c) {
        return { id: c.id, body: c.body, anchor: c.anchor, resolved: !!c.resolved,
                 createdAt: c.createdAt, updatedAt: c.updatedAt };
      })));
    } catch (e) {}
  }
  function uid() {
    return "c" + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }
  function nowISO() { return new Date().toISOString(); }

  /* ---------- text-node maps for quote <-> range ----------------------- */
  function buildText(root) {
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
    var text = "", map = [], node;
    while ((node = walker.nextNode())) {
      map.push({ node: node, start: text.length });
      text += node.nodeValue;
    }
    return { text: text, map: map };
  }
  function locate(map, offset) {
    for (var i = map.length - 1; i >= 0; i--) {
      if (offset >= map[i].start) return { node: map[i].node, offset: offset - map[i].start };
    }
    return map[0] ? { node: map[0].node, offset: 0 } : null;
  }

  var CTX = 32; // chars of prefix/suffix stored to disambiguate a quote

  /* ---------- element selector (stable-ish, no DOM mutation) ------------ */
  function esc(s) {
    return (window.CSS && CSS.escape) ? CSS.escape(s) : String(s).replace(/[^\w-]/g, "\\$&");
  }
  function elSelector(el) {
    var parts = [], cur = el;
    while (cur && cur.nodeType === 1 && cur !== document.body) {
      if (cur.id) { parts.unshift("#" + esc(cur.id)); break; }
      if (cur.dataset && cur.dataset.chunkId) {
        parts.unshift('[data-chunk-id="' + esc(cur.dataset.chunkId) + '"]'); break;
      }
      var tag = cur.tagName.toLowerCase(), parent = cur.parentNode;
      if (parent && parent.children) {
        var same = Array.prototype.filter.call(parent.children, function (c) {
          return c.tagName === cur.tagName;
        });
        if (same.length > 1) tag += ":nth-of-type(" + (same.indexOf(cur) + 1) + ")";
      }
      parts.unshift(tag);
      cur = cur.parentNode;
    }
    return parts.join(" > ");
  }

  var BLOCKS = "p,li,h1,h2,h3,h4,h5,h6,blockquote,pre,td,th,figure,figcaption," +
               "article,section,dd,dt,.callout,.card,.keypoints,.review-point";
  function closestBlock(el) {
    while (el && el.nodeType !== 1) el = el.parentNode;
    if (!el) return null;
    var m = el.closest ? el.closest(BLOCKS) : null;
    if (m && scope.contains(m)) return m;
    return scope.contains(el) ? el : null;
  }

  /* ---------- build an anchor from a live selection / a block ----------- */
  // Character offset of a boundary point (container, offset) within `block`,
  // measured the same way the text is concatenated. Using a Range's toString()
  // works whether the boundary lands in a text node or on an element edge — the
  // latter is what a double-/triple-click selection (whole word/line/paragraph)
  // produces, where the old text-node lookup returned -1 and the anchor failed.
  function measureOffset(block, container, offset) {
    if (container !== block && !block.contains(container)) return -1;
    try {
      var r = document.createRange();
      r.selectNodeContents(block);
      r.setEnd(container, offset);
      return r.toString().length;
    } catch (e) { return -1; }
  }
  function anchorFromSelection(range) {
    var common = range.commonAncestorContainer;
    var block = common.nodeType === 1 ? common : common.parentNode;
    if (!block || !scope.contains(block)) return null;
    var s = measureOffset(block, range.startContainer, range.startOffset);
    var e = measureOffset(block, range.endContainer, range.endOffset);
    if (s < 0 || e < 0 || e <= s) return null;
    var text = buildText(block).text;
    return {
      selector: elSelector(block),
      exact: text.slice(s, e),
      prefix: text.slice(Math.max(0, s - CTX), s),
      suffix: text.slice(e, e + CTX)
    };
  }
  function anchorFromBlock(el) {
    var block = closestBlock(el);
    if (!block) return null;
    return { selector: elSelector(block), exact: "", prefix: "", suffix: "" };
  }

  /* ---------- resolve an anchor back to a live Range ------------------- */
  function rangeFromQuote(root, a) {
    if (!a.exact) return null;
    var built = buildText(root), text = built.text, idx = -1, p;
    var ctx = (a.prefix || "") + a.exact + (a.suffix || "");
    p = text.indexOf(ctx);
    if (p >= 0) idx = p + (a.prefix ? a.prefix.length : 0);
    if (idx < 0) {
      var pre = (a.prefix || "") + a.exact;
      p = text.indexOf(pre);
      if (p >= 0) idx = p + (a.prefix ? a.prefix.length : 0);
    }
    if (idx < 0) idx = text.indexOf(a.exact);
    if (idx < 0) return null;
    var sLoc = locate(built.map, idx), eLoc = locate(built.map, idx + a.exact.length);
    if (!sLoc || !eLoc) return null;
    try {
      var r = document.createRange();
      r.setStart(sLoc.node, sLoc.offset);
      r.setEnd(eLoc.node, eLoc.offset);
      return r;
    } catch (e) { return null; }
  }

  /* ---------- highlighting (Custom Highlight API + fallback) ----------- */
  var supportsHL = typeof Highlight !== "undefined" && window.CSS && CSS.highlights;
  var hlNormal = supportsHL ? new Highlight() : null;
  var hlActive = supportsHL ? new Highlight() : null;
  if (supportsHL) {
    CSS.highlights.set("comment-highlight", hlNormal);
    CSS.highlights.set("comment-active", hlActive);
  }
  var markedEls = []; // block elements carrying a fallback/whole-block class

  function reanchor() {
    comments.forEach(function (c) {
      var el = null;
      try { el = document.querySelector(c.anchor.selector); } catch (e) {}
      c._el = el;
      c._range = el && c.anchor.exact ? rangeFromQuote(el, c.anchor) : null;
      c._orphaned = !el;
    });
  }
  function paint() {
    if (supportsHL) { hlNormal.clear(); hlActive.clear(); }
    markedEls.forEach(function (el) {
      el.classList.remove("comment-anchored", "comment-anchored-active");
    });
    markedEls = [];
    comments.forEach(function (c) {
      if (c.resolved) return;
      var active = c.id === activeId;
      if (c._range && supportsHL) {
        (active ? hlActive : hlNormal).add(c._range);
      } else if (c._el) {
        // whole-block comment, or a text quote with no Highlight API: rail marker
        c._el.classList.add("comment-anchored");
        if (active) c._el.classList.add("comment-anchored-active");
        markedEls.push(c._el);
      }
    });
  }

  /* ---------- ordering: document order, orphans last ------------------- */
  function sortKey(c) {
    var t = c._range || c._el;
    if (!t) return Number.MAX_SAFE_INTEGER;
    try { return t.getBoundingClientRect().top + window.scrollY; }
    catch (e) { return Number.MAX_SAFE_INTEGER; }
  }
  function ordered() {
    return comments.slice().sort(function (a, b) {
      var d = sortKey(a) - sortKey(b);
      return d !== 0 ? d : (a.createdAt < b.createdAt ? -1 : 1);
    });
  }

  /* ---------- panel + list --------------------------------------------- */
  var activeId = null;
  var editingId = null;   // id of the comment currently edited inline in its card
  var panel, listEl, countEl, fab, fabCount, backdrop;

  function fmtTime(iso) {
    try {
      var d = new Date(iso);
      var pad = function (n) { return (n < 10 ? "0" : "") + n; };
      return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) +
             " " + pad(d.getHours()) + ":" + pad(d.getMinutes());
    } catch (e) { return iso; }
  }

  function buildPanel() {
    panel = document.createElement("aside");
    panel.className = "comments-panel";
    panel.setAttribute("aria-label", "コメント");
    panel.innerHTML =
      '<div class="comments-head">' +
        '<span class="comments-title">コメント <span class="comments-count">0</span></span>' +
        '<div class="comments-tools">' +
          '<button data-act="export-md" title="Markdownで書き出す">⤓md</button>' +
          '<button data-act="export-json" title="JSONで書き出す">⤓{}</button>' +
          '<button data-act="import" title="JSONを読み込む">⤒</button>' +
          '<button data-act="close" class="comments-close" title="閉じる">✕</button>' +
        '</div>' +
      '</div>' +
      '<ul class="comments-list"></ul>';
    document.body.appendChild(panel);
    listEl = panel.querySelector(".comments-list");
    countEl = panel.querySelector(".comments-count");

    backdrop = document.createElement("div");
    backdrop.className = "comments-backdrop";
    document.body.appendChild(backdrop);
    backdrop.addEventListener("click", closePanel);

    // toggle button: reuse base.js's .fab stack if present, else stand alone
    fab = document.createElement("button");
    fab.type = "button";
    fab.setAttribute("aria-label", "コメントを開く");
    fab.innerHTML = '💬 <span class="comments-fab-count">0</span>';
    fabCount = fab.querySelector(".comments-fab-count");
    var fabStack = document.querySelector(".fab");
    if (fabStack) {
      fab.className = "comments-fab in-stack";
      fabStack.insertBefore(fab, fabStack.firstChild);
    } else {
      fab.className = "comments-fab";
      document.body.appendChild(fab);
    }
    fab.addEventListener("click", openPanel);

    panel.addEventListener("click", onPanelClick);
  }

  function renderList() {
    var items = ordered();
    countEl.textContent = items.length;
    fabCount.textContent = items.length;
    fab.classList.toggle("hide-empty", items.length === 0);
    listEl.innerHTML = "";
    if (!items.length) {
      var empty = document.createElement("p");
      empty.className = "comments-empty";
      empty.textContent = "まだコメントはありません。本文のテキストを選択するか、右クリックしてコメントを追加してください。";
      listEl.appendChild(empty);
      return;
    }
    items.forEach(function (c) {
      var li = document.createElement("li");
      li.className = "comment-card" + (c._orphaned ? " orphaned" : "") + (c.id === activeId ? " active" : "");
      li.setAttribute("data-id", c.id);
      if (c.resolved) li.setAttribute("data-resolved", "1");
      var quoteText = c.anchor.exact || (c._el ? "（ブロック全体へのコメント）" : "");
      var quote = "";
      if (quoteText) {
        quote = '<blockquote class="comment-quote' + (c._orphaned ? " orphaned" : "") + '"></blockquote>';
      }
      if (c.id === editingId) {
        // inline editor, right inside the card
        li.innerHTML = quote +
          '<textarea class="comment-edit"></textarea>' +
          '<div class="comment-actions">' +
            '<button data-act="save-edit" class="primary">保存</button>' +
            '<button data-act="cancel-edit">キャンセル</button>' +
          '</div>';
        if (quoteText) li.querySelector(".comment-quote").textContent = quoteText;
        li.querySelector(".comment-edit").value = c.body;
      } else {
        li.innerHTML = quote +
          '<p class="comment-body"></p>' +
          '<div class="comment-meta"></div>' +
          '<div class="comment-actions">' +
            '<button data-act="resolve">' + (c.resolved ? "未解決に戻す" : "解決") + '</button>' +
            '<button data-act="edit">編集</button>' +
            '<button data-act="delete" class="danger">削除</button>' +
          '</div>';
        if (quoteText) li.querySelector(".comment-quote").textContent = quoteText;
        li.querySelector(".comment-body").textContent = c.body;
        li.querySelector(".comment-meta").textContent = fmtTime(c.updatedAt || c.createdAt);
      }
      listEl.appendChild(li);
    });
    // focus the inline editor once it is in the DOM, cursor at the end
    if (editingId) {
      var ta = listEl.querySelector('.comment-card[data-id="' + editingId + '"] .comment-edit');
      if (ta) { ta.focus(); ta.setSelectionRange(ta.value.length, ta.value.length); }
    }
  }

  function render() { reanchor(); paint(); renderList(); }

  function onPanelClick(e) {
    var toolBtn = e.target.closest(".comments-tools button");
    if (toolBtn) {
      var act = toolBtn.getAttribute("data-act");
      if (act === "export-md") exportMarkdown();
      else if (act === "export-json") exportJSON();
      else if (act === "import") importJSON();
      else if (act === "close") closePanel();
      return;
    }
    var card = e.target.closest(".comment-card");
    if (!card) return;
    var id = card.getAttribute("data-id");
    var c = byId(id);
    if (!c) return;
    var actBtn = e.target.closest(".comment-actions button");
    if (actBtn) {
      var a = actBtn.getAttribute("data-act");
      if (a === "resolve") { c.resolved = !c.resolved; c.updatedAt = nowISO(); persist(); render(); }
      else if (a === "delete") { comments = comments.filter(function (x) { return x.id !== id; }); persist(); render(); }
      else if (a === "edit") { editingId = id; render(); }
      else if (a === "cancel-edit") { editingId = null; render(); }
      else if (a === "save-edit") saveEdit(card);
      return;
    }
    // clicking inside the inline editor (or its card while editing) must not
    // scroll the body away from what the reviewer is typing about
    if (e.target.closest(".comment-edit") || id === editingId) return;
    activate(id, true);
  }

  function saveEdit(card) {
    var id = card.getAttribute("data-id");
    var c = byId(id);
    var ta = card.querySelector(".comment-edit");
    if (c && ta) {
      var body = ta.value.trim();
      if (body) { c.body = body; c.updatedAt = nowISO(); persist(); }
    }
    editingId = null;
    render();
  }

  function byId(id) {
    for (var i = 0; i < comments.length; i++) if (comments[i].id === id) return comments[i];
    return null;
  }

  function activate(id, scrollTo) {
    activeId = id;
    paint();
    Array.prototype.forEach.call(listEl.querySelectorAll(".comment-card"), function (el) {
      el.classList.toggle("active", el.getAttribute("data-id") === id);
    });
    var c = byId(id);
    if (scrollTo && c) {
      var target = c._el;
      if (target && target.scrollIntoView) target.scrollIntoView({ behavior: "smooth", block: "center" });
      if (window.matchMedia && !window.matchMedia("(min-width: 79rem)").matches) closePanel();
    }
  }

  function openPanel() { panel.classList.add("open"); backdrop.classList.add("open"); }
  function closePanel() { panel.classList.remove("open"); backdrop.classList.remove("open"); }

  /* ---------- composer -------------------------------------------------- */
  var composer = null;
  function composerOutside(e) {
    if (composer && !composer.contains(e.target)) closeComposer();
  }
  function closeComposer() {
    document.removeEventListener("mousedown", composerOutside, true);
    if (composer) { composer.remove(); composer = null; }
  }

  function openComposer(anchor, x, y, existing) {
    closeComposer();
    closeMenu();
    composer = document.createElement("div");
    composer.className = "comments-composer";
    var quoteHtml = anchor && anchor.exact
      ? '<p class="composer-quote"></p>' : "";
    composer.innerHTML = quoteHtml +
      '<textarea placeholder="コメントを入力…"></textarea>' +
      '<div class="composer-actions">' +
        '<span class="composer-hint">⌘/Ctrl+Enter で保存</span>' +
        '<button class="comments-btn" data-act="cancel">キャンセル</button>' +
        '<button class="comments-btn primary" data-act="save" disabled>保存</button>' +
      '</div>';
    document.body.appendChild(composer);
    if (anchor && anchor.exact) composer.querySelector(".composer-quote").textContent = anchor.exact;

    // position within viewport
    var w = composer.offsetWidth, h = composer.offsetHeight;
    var left = Math.min(Math.max(8, x - w / 2), window.innerWidth - w - 8);
    var top = y + 8;
    if (top + h > window.innerHeight - 8) top = Math.max(8, y - h - 8);
    composer.style.left = left + "px";
    composer.style.top = top + "px";

    var ta = composer.querySelector("textarea");
    var saveBtn = composer.querySelector('[data-act="save"]');
    if (existing) ta.value = existing.body;
    ta.addEventListener("input", function () { saveBtn.disabled = !ta.value.trim(); });
    saveBtn.disabled = !ta.value.trim();
    ta.focus();

    function doSave() {
      var body = ta.value.trim();
      if (!body) return;
      if (existing) {
        existing.body = body; existing.updatedAt = nowISO();
      } else {
        var c = { id: uid(), body: body, anchor: anchor, resolved: false,
                  createdAt: nowISO(), updatedAt: nowISO() };
        comments.push(c);
        activeId = c.id;
      }
      persist();
      closeComposer();
      clearSelection();
      render();
    }
    saveBtn.addEventListener("click", doSave);
    composer.querySelector('[data-act="cancel"]').addEventListener("click", function () {
      closeComposer();
    });
    ta.addEventListener("keydown", function (e) {
      if ((e.metaKey || e.ctrlKey) && e.key === "Enter") { e.preventDefault(); doSave(); }
      else if (e.key === "Escape") { e.preventDefault(); closeComposer(); }
    });

    // close when clicking outside — registered on the next tick so the very
    // click/press that opened the composer does not immediately dismiss it
    setTimeout(function () {
      document.addEventListener("mousedown", composerOutside, true);
    }, 0);
  }

  /* ---------- body -> sidebar: focus the comment for a clicked location -- */
  // The Custom Highlight API paints over ranges without any DOM node to bind a
  // listener to, so a click on a highlighted span is resolved by hit-testing the
  // live ranges (and anchored blocks) against the click point.
  function commentAtPoint(x, y, targetEl) {
    for (var i = 0; i < comments.length; i++) {
      var c = comments[i];
      if (c.resolved || !c._range) continue;
      var rects = c._range.getClientRects();
      for (var j = 0; j < rects.length; j++) {
        var r = rects[j];
        if (x >= r.left && x <= r.right && y >= r.top && y <= r.bottom) return c;
      }
    }
    var block = targetEl && targetEl.closest ? targetEl.closest(".comment-anchored") : null;
    if (block) {
      for (var k = 0; k < comments.length; k++) {
        if (!comments[k].resolved && comments[k]._el === block && !comments[k]._range) return comments[k];
      }
    }
    return null;
  }
  function focusCardInSidebar(id) {
    var card = listEl.querySelector('.comment-card[data-id="' + id + '"]');
    if (!card) return;
    if (card.scrollIntoView) card.scrollIntoView({ behavior: "smooth", block: "nearest" });
    card.classList.remove("flash");
    void card.offsetWidth;          // restart the animation if re-clicked
    card.classList.add("flash");
  }

  /* ---------- selection action button ---------------------------------- */
  var selBtn = null;
  function hideSelBtn() { if (selBtn) { selBtn.remove(); selBtn = null; } }
  function showSelBtn() {
    var sel = window.getSelection();
    if (!sel || sel.isCollapsed || sel.rangeCount === 0) { hideSelBtn(); return; }
    var range = sel.getRangeAt(0);
    var common = range.commonAncestorContainer;
    var node = common.nodeType === 1 ? common : common.parentNode;
    if (!node || !scope.contains(node)) { hideSelBtn(); return; }
    if (!range.toString().trim()) { hideSelBtn(); return; }
    var rect = range.getBoundingClientRect();
    hideSelBtn();
    selBtn = document.createElement("button");
    selBtn.type = "button";
    selBtn.className = "comments-selbtn";
    selBtn.innerHTML = "💬 コメント";
    selBtn.style.left = (rect.left + rect.width / 2 + window.scrollX) + "px";
    selBtn.style.top = (rect.bottom + window.scrollY) + "px";
    document.body.appendChild(selBtn);
    selBtn.addEventListener("mousedown", function (e) {
      e.preventDefault(); // keep the selection alive
      var a = anchorFromSelection(range);
      hideSelBtn();
      if (a) openComposer(a, rect.left + rect.width / 2, rect.bottom);
    });
  }

  function clearSelection() {
    var sel = window.getSelection();
    if (sel && sel.removeAllRanges) sel.removeAllRanges();
    hideSelBtn();
  }

  /* ---------- right-click context menu --------------------------------- */
  var menu = null;
  function closeMenu() { if (menu) { menu.remove(); menu = null; } }
  function openMenu(x, y, anchor) {
    closeMenu();
    menu = document.createElement("div");
    menu.className = "comments-cmenu";
    menu.innerHTML = '<button data-act="comment">💬 コメントを追加</button>';
    document.body.appendChild(menu);
    var w = menu.offsetWidth, h = menu.offsetHeight;
    menu.style.left = Math.min(x, window.innerWidth - w - 8) + "px";
    menu.style.top = Math.min(y, window.innerHeight - h - 8) + "px";
    menu.querySelector('[data-act="comment"]').addEventListener("click", function () {
      var mx = parseFloat(menu.style.left), my = parseFloat(menu.style.top);
      closeMenu();
      openComposer(anchor, mx, my);
    });
  }

  /* ---------- export / import ------------------------------------------ */
  // Export shows the text in an in-page panel, pre-selected, with a copy button.
  // No file download: the panel works everywhere (including a sandboxed Artifact
  // iframe where a[download] is blocked) and is the more convenient flow — copy
  // and paste wherever it needs to go. `label` names the format / suggested file.
  function showExportText(label, text) {
    var back = document.createElement("div");
    back.className = "comments-export-backdrop";
    back.innerHTML =
      '<div class="comments-export" role="dialog" aria-label="書き出し">' +
        '<div class="comments-export-head">' +
          '<span class="comments-export-name"></span>' +
          '<button class="comments-btn primary" data-x="copy">コピー</button>' +
          '<button class="comments-btn" data-x="close">閉じる</button>' +
        '</div>' +
        '<p class="comments-export-hint">「コピー」を押すか、テキストを選択してコピーしてください。</p>' +
        '<textarea readonly></textarea>' +
      '</div>';
    back.querySelector(".comments-export-name").textContent = label;
    var ta = back.querySelector("textarea");
    ta.value = text;
    document.body.appendChild(back);
    ta.focus(); ta.select();
    function close() { back.remove(); }
    document.addEventListener("keydown", function esc(e) {
      if (e.key === "Escape") { close(); document.removeEventListener("keydown", esc); }
    });
    back.addEventListener("click", function (e) {
      var x = e.target.getAttribute && e.target.getAttribute("data-x");
      if (e.target === back || x === "close") { close(); return; }
      if (x === "copy") {
        ta.focus(); ta.select();
        var ok = false;
        try { ok = document.execCommand("copy"); } catch (er) {}
        if (!ok && navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).catch(function () {});
        }
        e.target.textContent = "コピーしました";
        setTimeout(function () { e.target.textContent = "コピー"; }, 1500);
      }
    });
  }
  function slug() {
    // Keep the document's own script (Japanese etc.); only drop characters that
    // are illegal in a filename, and collapse whitespace — used for the suggested
    // filename label shown above the export text.
    var t = (document.title || "document")
      .replace(/[\\/:*?"<>|\s]+/g, "-")   // illegal chars + whitespace -> dash
      .replace(/^[-.]+|[-.]+$/g, "")                // trim dashes/dots
      .slice(0, 60);
    return t || "document";
  }
  function exportJSON() {
    var payload = {
      docId: docId(), url: location.href, title: document.title,
      exportedAt: nowISO(),
      comments: comments.map(function (c) {
        return { id: c.id, body: c.body, anchor: c.anchor, resolved: !!c.resolved,
                 createdAt: c.createdAt, updatedAt: c.updatedAt };
      })
    };
    showExportText("comments-" + slug() + ".json", JSON.stringify(payload, null, 2));
  }
  function exportMarkdown() {
    var items = ordered();
    var lines = ["# コメント — " + (document.title || docId()), "",
                 location.href, "", "計 " + items.length + " 件", ""];
    items.forEach(function (c, i) {
      lines.push("## " + (i + 1) + ". " + (c.resolved ? "[解決済] " : "") + fmtTime(c.updatedAt || c.createdAt));
      if (c.anchor.exact) lines.push("> " + c.anchor.exact.replace(/\n/g, " "));
      lines.push("");
      lines.push(c.body);
      lines.push("");
      lines.push("`" + c.anchor.selector + "`" + (c._orphaned ? " ⚠️ 対象が見つかりません" : ""));
      lines.push("");
    });
    showExportText("comments-" + slug() + ".md", lines.join("\n"));
  }
  // Merge an exported-JSON string into the current comments (dedup by id).
  // Returns the number added, or -1 if the text is not valid comment JSON.
  function mergeImported(text) {
    var data;
    try { data = JSON.parse(text); } catch (e) { return -1; }
    var incoming = Array.isArray(data) ? data : (data && data.comments) || [];
    if (!Array.isArray(incoming)) return -1;
    var have = {}, added = 0;
    comments.forEach(function (c) { have[c.id] = true; });
    incoming.forEach(function (c) {
      if (c && c.id && c.anchor && !have[c.id]) { comments.push(c); have[c.id] = true; added++; }
    });
    if (added) { persist(); render(); }
    return added;
  }
  // Paste-in import: the counterpart to the copy-out export panel (no file
  // picker) — paste an exported JSON and merge it.
  function importJSON() {
    var back = document.createElement("div");
    back.className = "comments-export-backdrop";
    back.innerHTML =
      '<div class="comments-export" role="dialog" aria-label="取り込み">' +
        '<div class="comments-export-head">' +
          '<span class="comments-export-name">JSON を取り込み</span>' +
          '<button class="comments-btn primary" data-x="import">取り込む</button>' +
          '<button class="comments-btn" data-x="close">閉じる</button>' +
        '</div>' +
        '<p class="comments-export-hint">書き出した JSON を貼り付けて「取り込む」を押してください。</p>' +
        '<textarea placeholder="{ … } を貼り付け"></textarea>' +
      '</div>';
    var ta = back.querySelector("textarea");
    var hint = back.querySelector(".comments-export-hint");
    document.body.appendChild(back);
    ta.focus();
    function close() { back.remove(); document.removeEventListener("keydown", onEsc); }
    function onEsc(e) { if (e.key === "Escape") close(); }
    document.addEventListener("keydown", onEsc);
    back.addEventListener("click", function (e) {
      var x = e.target.getAttribute && e.target.getAttribute("data-x");
      if (e.target === back || x === "close") { close(); return; }
      if (x === "import") {
        var n = mergeImported(ta.value.trim());
        if (n < 0) {
          hint.textContent = "JSON を解釈できませんでした。書き出した内容をそのまま貼り付けてください。";
          hint.classList.add("error");
          ta.focus();
        } else {
          close();
        }
      }
    });
  }

  /* ---------- wiring ---------------------------------------------------- */
  function init() {
    load();
    buildPanel();
    render();

    // selection button
    document.addEventListener("mouseup", function (e) {
      if (composer && composer.contains(e.target)) return;
      setTimeout(showSelBtn, 0);
    });
    document.addEventListener("mousedown", function (e) {
      if (selBtn && selBtn.contains(e.target)) return;
      hideSelBtn();
      if (menu && !menu.contains(e.target)) closeMenu();
    });

    // click a commented location in the body -> focus its card in the sidebar
    scope.addEventListener("click", function (e) {
      if (panel.contains(e.target) || (selBtn && selBtn.contains(e.target))) return;
      var sel = window.getSelection();
      if (sel && !sel.isCollapsed) return;            // a real selection, not a focus click
      var c = commentAtPoint(e.clientX, e.clientY, e.target);
      if (!c) return;
      if (window.matchMedia && !window.matchMedia("(min-width: 79rem)").matches) openPanel();
      activate(c.id, false);
      focusCardInSidebar(c.id);
    });

    // inline editor shortcuts: Cmd/Ctrl+Enter saves, Escape cancels
    panel.addEventListener("keydown", function (e) {
      var ta = e.target.closest ? e.target.closest(".comment-edit") : null;
      if (!ta) return;
      if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
        e.preventDefault();
        saveEdit(ta.closest(".comment-card"));
      } else if (e.key === "Escape") {
        e.preventDefault();
        editingId = null;
        render();
      }
    });

    // right-click inside the document -> our menu
    scope.addEventListener("contextmenu", function (e) {
      if (panel.contains(e.target)) return;
      var sel = window.getSelection();
      var anchor = null;
      if (sel && !sel.isCollapsed && sel.rangeCount) {
        var r = sel.getRangeAt(0);
        var n = r.commonAncestorContainer;
        n = n.nodeType === 1 ? n : n.parentNode;
        if (n && scope.contains(n) && r.toString().trim()) anchor = anchorFromSelection(r);
      }
      if (!anchor) anchor = anchorFromBlock(e.target);
      if (!anchor) return;
      e.preventDefault();
      openMenu(e.clientX, e.clientY, anchor);
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") { closeMenu(); hideSelBtn(); closeComposer(); }
    });
    window.addEventListener("resize", function () { hideSelBtn(); closeMenu(); });
    // keep highlights/ordering correct after layout shifts (e.g. diff expand)
    window.addEventListener("hashchange", render);
    // re-anchor once late-rendering engines (diff2html, mermaid) have run, so a
    // comment whose target only exists after render is not left orphaned
    window.addEventListener("load", render);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
