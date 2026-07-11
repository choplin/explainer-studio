/* diff component (Tier 2) — render script.
   Renders every <pre class="diff-source"> + immediately-following
   <div class="diff-render"> pair with diff2html, and wires the
   unified <-> side-by-side format toggle ([data-diff-format] buttons).

   Requires the diff2html UMD bundle to be loaded first (it provides the global
   Diff2HtmlUI); see include.md for the CDN tags. Resolves light/dark the same
   way base.css does — an explicit .theme-* class wins, otherwise follow the OS —
   so the rendered diff matches the document theme, and re-renders when the theme
   changes at runtime (toggle or OS) since diff2html bakes the palette in at draw
   time. Works with or without base.js present. */
document.addEventListener("DOMContentLoaded", () => {
  function isDark() {
    return document.documentElement.classList.contains("theme-dark")
      || (!document.documentElement.classList.contains("theme-light")
          && window.matchMedia("(prefers-color-scheme: dark)").matches);
  }
  let currentFormat = "line-by-line";     // preserved across theme re-renders
  const render = (format) => {
    currentFormat = format;
    const dark = isDark();
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

  // Follow later theme changes: re-draw with the new colorScheme only when the
  // resolved dark/light flips. An explicit .theme-* toggle mutates the root
  // class; an OS scheme change fires matchMedia while in auto mode.
  let wasDark = isDark();
  const onFlip = () => {
    const now = isDark();
    if (now !== wasDark) { wasDark = now; render(currentFormat); }
  };
  new MutationObserver(onFlip).observe(document.documentElement, {
    attributes: true, attributeFilter: ["class"],
  });
  if (window.matchMedia) {
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    if (mq.addEventListener) mq.addEventListener("change", onFlip);
    else if (mq.addListener) mq.addListener(onFlip);
  }
});
