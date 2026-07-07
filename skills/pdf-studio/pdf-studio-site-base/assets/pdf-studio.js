/* pdf-studio site — context-specific progressive enhancement (owned by
   pdf-studio-site-base). Loads alongside understanding-html-docs base.js (which
   provides the theme toggle, reading-progress bar, TOC with scroll-spy, and
   back-to-top). This file adds ONLY the live filter over chapter/book cards, so
   it enhances both the generate-site landing page and the library index. Vanilla
   JS, no dependencies, no network. The page is fully readable if it never loads;
   wire the class names here to pdf-studio.css. */
(function () {
  "use strict";

  /* ---------- index: live filter over chapter cards ---------- */
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
