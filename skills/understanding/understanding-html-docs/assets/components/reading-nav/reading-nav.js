/* reading-nav — reading-site navigation widgets (Tier 2 opt-in component of
   understanding-html-docs). Loads alongside base.js (which provides the theme
   toggle, reading-progress bar, TOC with scroll-spy, and back-to-top). This bundle
   adds the multi-page reading-site aids: a live filter over an index the consumer
   marks with `data-reading-filter`, and manifest-driven page-to-page navigation
   (prev/next + an all-pages drawer). Both enhance a site's landing/index page and
   every report page.

   Document-type-neutral: it hardcodes no chapter/section/book vocabulary and no
   consumer class name. The filter target is opted in per element; its wording
   defaults to a generic string (overridable via the attribute value); the neighbor
   labels come from the per-site manifest data (window.__HTMLDOCS_NAV), which the
   consumer authors. Vanilla JS, no dependencies,
   no network. Each block is independent and the page is fully readable if this file
   never loads; wire the class names here to reading-nav.css. */
(function () {
  "use strict";

  /* ---------- index: live filter over an opted-in index ----------
     The consumer decides WHICH element is filtered by marking it with a
     `data-reading-filter` attribute — the component assumes no class name of its
     own. The attribute's value, if any, is the placeholder; otherwise a
     document-type-neutral default is used. Each direct child of the marked element
     is one filterable item; a non-match gets the component's `.rn-hidden` class.
     No marked element → no-op, like the page nav below. */
  (function indexFilter() {
    var cards = document.querySelector("[data-reading-filter]");
    if (!cards) return;

    var label = (cards.getAttribute("data-reading-filter") || "").trim() || "絞り込む…";
    var items = Array.prototype.slice.call(cards.children);
    var input = document.createElement("input");
    input.type = "search";
    input.className = "filter";
    input.placeholder = label;
    input.setAttribute("aria-label", label.replace(/…+$/, "") || label);
    cards.parentNode.insertBefore(input, cards);

    var empty = document.createElement("p");
    empty.className = "filter-empty";
    empty.textContent = "一致する項目がありません。";
    empty.hidden = true;
    cards.parentNode.insertBefore(empty, cards.nextSibling);

    input.addEventListener("input", function () {
      var q = input.value.trim().toLowerCase();
      var shown = 0;
      items.forEach(function (item) {
        var hit = q === "" || item.textContent.toLowerCase().indexOf(q) !== -1;
        item.classList.toggle("rn-hidden", !hit);
        if (hit) shown++;
      });
      empty.hidden = shown !== 0;
    });
  })();

  /* ---------- page-to-page navigation (manifest-driven) ----------
     Single source of truth: window.__HTMLDOCS_NAV, assigned by the generated
     nav-manifest.js that every page loads. The list lives in ONE file, so adding
     or removing a page updates every page's nav at once — no per-page markup to
     keep in sync. This block renders the prev/next links at the foot of a report
     page; the current page is detected from the URL, so the manifest itself
     carries no per-page state and stays identical across the whole site.
     Missing manifest (e.g. the library index) → no-op, like the filter above. */
  (function pageNav() {
    var nav = window.__HTMLDOCS_NAV;
    if (!nav || !nav.pages || !nav.pages.length) return;
    var pages = nav.pages;

    // current page = manifest entry whose href matches this file's basename
    var here = (location.pathname.split("/").pop() || "index.html");
    if (here === "") here = "index.html";
    var idx = -1;
    for (var i = 0; i < pages.length; i++) {
      if (pages[i].href === here) { idx = i; break; }
    }

    // Everything here is for a report page that is itself in the manifest.
    // (The landing page is the whole-site view — it already lists every page as
    // cards — so it gets neither prev/next nor the drawer.)
    if (idx === -1) return;

    // --- prev/next at the article foot ---
    var article = document.querySelector("main article");
    if (article) {
      var prev = idx > 0 ? pages[idx - 1] : null;
      var next = idx < pages.length - 1 ? pages[idx + 1] : null;

      var chapnav = document.createElement("nav");
      chapnav.className = "chapnav";
      chapnav.setAttribute("aria-label", "前後のページ");

      var left = document.createElement(prev ? "a" : "span");
      if (prev) { left.href = prev.href; left.textContent = "← " + navLabel(prev); }
      var right = document.createElement(next ? "a" : "span");
      if (next) { right.href = next.href; right.textContent = navLabel(next) + " →"; }

      chapnav.appendChild(left);
      chapnav.appendChild(right);
      article.appendChild(chapnav);
    }

    // --- all-pages drawer: a list FAB opening a slide-up list of every page, the
    // current one highlighted. A DIFFERENT axis from base.js's ☰ TOC (which lists
    // this page's sections): pages vs sections. Unlike the TOC it stays a drawer
    // at every width (base.css promotes only .toc-panel to a wide sidebar, and
    // this panel uses its own class). base.js runs first (script order) and has
    // already created .fab, so we just prepend our button to it. ---
    var fab = document.querySelector(".fab");
    if (fab) {
      var backdrop = document.createElement("div");
      backdrop.className = "pagenav-backdrop";
      var panel = document.createElement("nav");
      panel.className = "pagenav-panel";
      panel.setAttribute("aria-label", "全ページ");
      var title = document.createElement("h2");
      title.textContent = "全ページ";
      panel.appendChild(title);
      var list = document.createElement("ol");
      pages.forEach(function (p, i) {
        var li = document.createElement("li");
        var a = document.createElement("a");
        a.href = p.href;
        if (i === idx) { a.className = "active"; a.setAttribute("aria-current", "page"); }
        if (p.kicker) {
          var k = document.createElement("span");
          k.className = "k";
          k.textContent = p.kicker;
          a.appendChild(k);
        }
        a.appendChild(document.createTextNode(p.title || p.href));
        li.appendChild(a);
        list.appendChild(li);
      });
      panel.appendChild(list);

      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "pages-btn show";
      // three horizontal lines (a list/menu mark) for the page list, colored via
      // currentColor (accent). An SVG, not an emoji, so it stays crisp and on-brand.
      btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
        'stroke-width="2" stroke-linecap="round" aria-hidden="true">' +
        '<path d="M4 7h16"/><path d="M4 12h16"/><path d="M4 17h16"/></svg>';
      btn.setAttribute("aria-label", "全ページ");
      function openPages() { backdrop.classList.add("open"); panel.classList.add("open"); }
      function closePages() { backdrop.classList.remove("open"); panel.classList.remove("open"); }
      btn.addEventListener("click", openPages);
      backdrop.addEventListener("click", closePages);
      document.addEventListener("keydown", function (e) { if (e.key === "Escape") closePages(); });

      fab.insertBefore(btn, fab.firstChild);   // list button sits above ☰ and ↑
      document.body.appendChild(backdrop);
      document.body.appendChild(panel);

      // Give base.js's ☰ TOC button a distinct outline icon (a heading + two
      // indented sub-items) so on narrow screens it doesn't read as a twin of
      // this flat-lines list button: sections (indented outline) vs pages (list).
      // Presentation only — the TOC behavior is untouched; skipped if absent.
      var tocBtn = fab.querySelector(".toc-btn");
      if (tocBtn) {
        tocBtn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
          'stroke-width="2" stroke-linecap="round" aria-hidden="true">' +
          '<path d="M4 6h16"/><path d="M8 12h12"/><path d="M8 18h12"/></svg>';
      }
    }

    function navLabel(p) {
      // kicker (the compact neighbor label the consumer supplies per page in the
      // manifest — e.g. a section number or a perspective name) is preferred; fall
      // back to the title when a page has no kicker.
      return p.kicker || p.title || p.href;
    }
  })();
})();
