/* understanding-html-docs base — progressive enhancement.
   Vanilla JS, no dependencies, no build step, no network. Every feature is
   optional: the page is fully readable if this file never loads. Behaviors are
   wired from semantic HTML (header.site, main article, h2/h3) authored against
   base.css — keep the class names here in sync with that stylesheet.

   Provides: theme toggle (auto/light/dark), reading-progress bar, table of
   contents with scroll-spy, and back-to-top. The matching no-flash boot snippet
   goes inline in <head> (see understanding-html-docs SKILL.md) and must use the same
   THEME_KEY. Consuming skills copy this file verbatim and add their own
   context-specific scripts separately. */
(function () {
  "use strict";
  var root = document.documentElement;
  var body = document.body;

  /* ---------- theme toggle: auto -> light -> dark ---------- */
  var THEME_KEY = "html-docs-theme";
  var THEMES = ["auto", "light", "dark"];
  var THEME_ICON = { auto: "🌗", light: "☀️", dark: "🌙" };
  var THEME_LABEL = { auto: "自動", light: "ライト", dark: "ダーク" };

  function readTheme() {
    try { return localStorage.getItem(THEME_KEY) || "auto"; } catch (e) { return "auto"; }
  }
  function applyTheme(t) {
    root.classList.remove("theme-light", "theme-dark");
    if (t === "light") root.classList.add("theme-light");
    else if (t === "dark") root.classList.add("theme-dark");
  }
  function mountThemeButton() {
    var header = document.querySelector("header.site");
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = header ? "theme-btn" : "theme-btn floating";
    function render() {
      var t = readTheme();
      btn.textContent = THEME_ICON[t] + " " + THEME_LABEL[t];
      btn.setAttribute("aria-label", "テーマ: " + THEME_LABEL[t]);
    }
    btn.addEventListener("click", function () {
      var next = THEMES[(THEMES.indexOf(readTheme()) + 1) % THEMES.length];
      try { localStorage.setItem(THEME_KEY, next); } catch (e) {}
      applyTheme(next);
      render();
    });
    render();
    (header || body).appendChild(btn);
  }
  applyTheme(readTheme());
  mountThemeButton();

  /* ---------- reading-progress bar (article pages) ---------- */
  var article = document.querySelector("main article");
  if (article) {
    var bar = document.createElement("div");
    bar.className = "progress";
    var fill = document.createElement("i");
    bar.appendChild(fill);
    body.appendChild(bar);
    var ticking = false;
    function updateProgress() {
      ticking = false;
      var top = article.offsetTop;
      var span = article.offsetHeight - window.innerHeight;
      var p = span > 0 ? (window.scrollY - top) / span : 0;
      fill.style.width = Math.max(0, Math.min(1, p)) * 100 + "%";
    }
    function onScrollProgress() {
      if (!ticking) { ticking = true; requestAnimationFrame(updateProgress); }
    }
    window.addEventListener("scroll", onScrollProgress, { passive: true });
    window.addEventListener("resize", updateProgress);
    updateProgress();
  }

  /* ---------- floating actions: TOC + back-to-top ---------- */
  var headings = article ? Array.prototype.slice.call(article.querySelectorAll("h2, h3")) : [];
  var fab = document.createElement("div");
  fab.className = "fab";
  body.appendChild(fab);

  // back-to-top (shown after scrolling down)
  var topBtn = document.createElement("button");
  topBtn.type = "button";
  topBtn.className = "top-btn";
  topBtn.textContent = "↑";
  topBtn.setAttribute("aria-label", "先頭へ戻る");
  topBtn.addEventListener("click", function () {
    window.scrollTo({ top: 0, behavior: "smooth" });
  });
  fab.appendChild(topBtn);
  window.addEventListener("scroll", function () {
    topBtn.classList.toggle("show", window.scrollY > 500);
  }, { passive: true });

  // TOC (only when the article has at least two h2 sections)
  var h2count = headings.filter(function (h) { return h.tagName === "H2"; }).length;
  if (h2count >= 2) {
    var backdrop = document.createElement("div");
    backdrop.className = "toc-backdrop";
    var panel = document.createElement("nav");
    panel.className = "toc-panel";
    panel.setAttribute("aria-label", "目次");
    var title = document.createElement("h2");
    title.textContent = "目次";
    panel.appendChild(title);
    var list = document.createElement("ol");
    panel.appendChild(list);

    var links = [];
    headings.forEach(function (h, i) {
      if (!h.id) h.id = "sec-" + i;
      var li = document.createElement("li");
      if (h.tagName === "H3") li.className = "sub";
      var a = document.createElement("a");
      a.href = "#" + h.id;
      a.textContent = h.textContent;
      a.addEventListener("click", function (e) {
        e.preventDefault();
        closeToc();
        h.scrollIntoView({ behavior: "smooth", block: "start" });
        history.replaceState(null, "", "#" + h.id);
      });
      li.appendChild(a);
      list.appendChild(li);
      links.push({ a: a, h: h });
    });

    var tocBtn = document.createElement("button");
    tocBtn.type = "button";
    tocBtn.className = "toc-btn show";
    tocBtn.textContent = "☰";
    tocBtn.setAttribute("aria-label", "目次を開く");
    fab.insertBefore(tocBtn, topBtn);

    function openToc() { backdrop.classList.add("open"); panel.classList.add("open"); }
    function closeToc() { backdrop.classList.remove("open"); panel.classList.remove("open"); }
    tocBtn.addEventListener("click", openToc);
    backdrop.addEventListener("click", closeToc);
    document.addEventListener("keydown", function (e) { if (e.key === "Escape") closeToc(); });

    body.appendChild(backdrop);
    body.appendChild(panel);

    // scroll-spy: highlight the section currently at the top
    var spyTicking = false;
    function spy() {
      spyTicking = false;
      var pos = window.scrollY + 100;
      var current = links[0];
      for (var i = 0; i < links.length; i++) {
        if (links[i].h.offsetTop <= pos) current = links[i];
      }
      links.forEach(function (l) { l.a.classList.toggle("active", l === current); });
    }
    window.addEventListener("scroll", function () {
      if (!spyTicking) { spyTicking = true; requestAnimationFrame(spy); }
    }, { passive: true });
    spy();
  }
})();
