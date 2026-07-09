/* diff component (Tier 2) — render script.
   Renders every <pre class="diff-source"> + immediately-following
   <div class="diff-render"> pair with diff2html, and wires the
   unified <-> side-by-side format toggle ([data-diff-format] buttons).

   Requires the diff2html UMD bundle to be loaded first (it provides the global
   Diff2HtmlUI); see include.md for the CDN tags. Resolves light/dark the same
   way base.css does — an explicit .theme-* class wins, otherwise follow the OS —
   so the rendered diff matches the document theme. Works with or without
   base.js present. */
document.addEventListener("DOMContentLoaded", () => {
  const dark = document.documentElement.classList.contains("theme-dark")
    || (!document.documentElement.classList.contains("theme-light")
        && window.matchMedia("(prefers-color-scheme: dark)").matches);
  const render = (format) => {
    document.querySelectorAll(".diff-render").forEach((el) => {
      const src = el.previousElementSibling;
      if (!src || !src.classList.contains("diff-source")) return;
      el.innerHTML = "";
      new Diff2HtmlUI(el, src.textContent, {
        drawFileList: false,
        matching: "lines",
        outputFormat: format,
        highlight: true,
        colorScheme: dark ? "dark" : "light",
      }).draw();
    });
  };
  render("line-by-line");
  document.querySelectorAll("[data-diff-format]").forEach((btn) =>
    btn.addEventListener("click", () => render(btn.dataset.diffFormat)));
});
