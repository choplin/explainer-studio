/* diagram component (Tier 2) — mermaid init.
   Module script: imports mermaid from the CDN (see include.md for the pin) and
   initializes it. Resolves the theme the same way base.css does — an explicit
   .theme-* class wins, otherwise follow the OS — so diagrams follow the document
   theme. Renders every <pre class="mermaid"> on load. Works with or without
   base.js present.

   Palette hook: the base owns a recommended classDef stroke set that speaks the
   design system's semantic hues (see include.md); the consuming skill assigns
   which change-role (added/removed/changed) uses which. */
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
const dark = document.documentElement.classList.contains("theme-dark")
  || (!document.documentElement.classList.contains("theme-light")
      && window.matchMedia("(prefers-color-scheme: dark)").matches);
mermaid.initialize({ startOnLoad: true, theme: dark ? "dark" : "neutral" });
