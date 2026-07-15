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

    // Everything here is for a report page that is itself in the manifest.
    // (The landing page is the whole-book view — it already lists every page as
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

    // --- all-pages drawer: a 📖 FAB opening a slide-up list of every page, the
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
      btn.textContent = "📖";
      btn.setAttribute("aria-label", "全ページ");
      function openPages() { backdrop.classList.add("open"); panel.classList.add("open"); }
      function closePages() { backdrop.classList.remove("open"); panel.classList.remove("open"); }
      btn.addEventListener("click", openPages);
      backdrop.addEventListener("click", closePages);
      document.addEventListener("keydown", function (e) { if (e.key === "Escape") closePages(); });

      fab.insertBefore(btn, fab.firstChild);   // 📖 sits above ☰ and ↑
      document.body.appendChild(backdrop);
      document.body.appendChild(panel);
    }

    function navLabel(p) {
      // kicker (第N章 / 全体レポート) is the compact neighbor label; fall back to
      // the title when a page has no kicker.
      return p.kicker || p.title || p.href;
    }
  })();
})();
