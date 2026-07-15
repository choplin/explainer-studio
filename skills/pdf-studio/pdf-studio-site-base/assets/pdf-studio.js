/* pdf-studio site — context-specific progressive enhancement (owned by
   pdf-studio-site-base). Loads alongside understanding-html-docs base.js (which
   provides the theme toggle, reading-progress bar, TOC with scroll-spy, and
   back-to-top). This file adds the pdf-studio-specific enhancements: the live
   filter over chapter/book cards, and the manifest-driven page-to-page
   navigation. Both enhance the generate-site landing page and every report page.
   Vanilla JS, no dependencies, no network. Each block is independent and the page
   is fully readable if this file never loads; wire the class names here to
   pdf-studio.css. */
(function () {
  "use strict";

  /* ---------- index: live filter over chapter cards ---------- */
  (function indexFilter() {
    var cards = document.querySelector("ol.cards");
    if (!cards) return;

    var items = Array.prototype.slice.call(cards.querySelectorAll("li"));
    var input = document.createElement("input");
    input.type = "search";
    input.className = "filter";
    input.placeholder = "章を絞り込む…";
    input.setAttribute("aria-label", "章を絞り込む");
    cards.parentNode.insertBefore(input, cards);

    var empty = document.createElement("p");
    empty.className = "filter-empty";
    empty.textContent = "一致する章がありません。";
    empty.hidden = true;
    cards.parentNode.insertBefore(empty, cards.nextSibling);

    input.addEventListener("input", function () {
      var q = input.value.trim().toLowerCase();
      var shown = 0;
      items.forEach(function (li) {
        var hit = q === "" || li.textContent.toLowerCase().indexOf(q) !== -1;
        li.classList.toggle("hidden", !hit);
        if (hit) shown++;
      });
      empty.hidden = shown !== 0;
    });
  })();

  /* ---------- page-to-page navigation (manifest-driven) ----------
     Single source of truth: window.__PDF_STUDIO_NAV, assigned by the generated
     nav-manifest.js that every page loads. The list lives in ONE file, so adding
     or removing a page updates every page's nav at once — no per-page markup to
     keep in sync. This block renders the prev/next links at the foot of a report
     page; the current page is detected from the URL, so the manifest itself
     carries no per-page state and stays identical across the whole site.
     Missing manifest (e.g. the library index) → no-op, like the filter above. */
  (function pageNav() {
    var nav = window.__PDF_STUDIO_NAV;
    if (!nav || !nav.pages || !nav.pages.length) return;
    var pages = nav.pages;

    // current page = manifest entry whose href matches this file's basename
    var here = (location.pathname.split("/").pop() || "index.html");
    if (here === "") here = "index.html";
    var idx = -1;
    for (var i = 0; i < pages.length; i++) {
      if (pages[i].href === here) { idx = i; break; }
    }

    // prev/next belongs on a report page that is itself in the manifest.
    // (The landing page is the whole-book view; it gets no prev/next.)
    var article = document.querySelector("main article");
    if (idx !== -1 && article) {
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

    // NOTE: the all-pages list nav (full jump list + current highlight) mounts
    // here. Its UI form is deferred; this block already computes `idx` for the
    // current-page highlight it will need.

    function navLabel(p) {
      // kicker (第N章 / 全体レポート) is the compact neighbor label; fall back to
      // the title when a page has no kicker.
      return p.kicker || p.title || p.href;
    }
  })();
})();
