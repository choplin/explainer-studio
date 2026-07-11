/* diagram component (Tier 2) — mermaid init.
   Module script: imports mermaid from the CDN (see include.md for the pin) and
   initializes it. Resolves the theme the same way base.css does — an explicit
   .theme-* class wins, otherwise follow the OS — so diagrams follow the document
   theme. Renders every <pre class="mermaid"> on load, and re-renders when the
   theme changes at runtime (toggle or OS) so diagrams never keep a stale palette
   — e.g. dark-theme node fills left over on a light page. Works with or without
   base.js present.

   Palette hook: the base owns a recommended classDef stroke set that speaks the
   design system's semantic hues (see include.md); the consuming skill assigns
   which change-role (added/removed/changed) uses which. */
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";

function isDark() {
  var root = document.documentElement;
  return root.classList.contains("theme-dark")
    || (!root.classList.contains("theme-light")
        && window.matchMedia("(prefers-color-scheme: dark)").matches);
}

// mermaid replaces each <pre class="mermaid"> with rendered SVG and marks it
// data-processed on run, discarding the graph source. Keep that source so a
// later theme change can restore it and re-render under the new palette.
var sources = new WeakMap();

// Drive mermaid explicitly rather than via startOnLoad: with an ESM `import`
// the auto-run can miss the load event (this is mermaid's own recommended ESM
// pattern).
function render() {
  document.querySelectorAll("pre.mermaid").forEach(function (el) {
    if (!sources.has(el)) sources.set(el, el.textContent);
  });
  mermaid.initialize({ startOnLoad: false, theme: isDark() ? "dark" : "neutral" });
  mermaid.run();
}

function rerender() {
  document.querySelectorAll("pre.mermaid").forEach(function (el) {
    var src = sources.get(el);
    if (src == null) return;
    el.removeAttribute("data-processed");
    el.textContent = src;
  });
  render();
}

function start() {
  render();
  // Follow later theme changes and re-render only when the resolved dark/light
  // actually flips: an explicit .theme-* toggle mutates the root class; an OS
  // scheme change fires matchMedia while in auto mode.
  var wasDark = isDark();
  var onFlip = function () {
    var now = isDark();
    if (now !== wasDark) { wasDark = now; rerender(); }
  };
  new MutationObserver(onFlip).observe(document.documentElement, {
    attributes: true, attributeFilter: ["class"],
  });
  if (window.matchMedia) {
    var mq = window.matchMedia("(prefers-color-scheme: dark)");
    if (mq.addEventListener) mq.addEventListener("change", onFlip);
    else if (mq.addListener) mq.addListener(onFlip);
  }
}

// The deferred module runs after parsing, so run once the DOM is ready and every
// <pre class="mermaid"> exists.
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", start);
} else {
  start();
}
