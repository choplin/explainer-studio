/* highlight component (Tier 2) — apply highlight.js to code blocks.
   Requires the highlight.js bundle loaded first (global `hljs`); see include.md
   for the CDN tag. Highlights every <pre><code> on load, auto-detecting the
   language or honoring a class="language-xxx"; blocks tagged .nohighlight /
   .no-highlight / language-plaintext are skipped (highlightAll's own rule). Token
   colors come from highlight.css (light-dark pairs), so there is nothing to
   theme-switch here. Works with or without base.js present. */
document.addEventListener("DOMContentLoaded", function () {
  if (window.hljs) window.hljs.highlightAll();
});
