-- tier2.lua — the reference-site's own CONSUMER filter, chained AFTER
-- htmldocs.lua (`--lua-filter htmldocs.lua --lua-filter tier2.lua`). It exists
-- for one page — tier2.html, the Tier 2 component showcase — which is the one
-- reference page whose markup the base dialect cannot express: the Tier 2
-- component contracts are raw <pre>/<code>/<div> shapes, and under
-- -f markdown-raw_html the author cannot write raw HTML. So a plain fenced code
-- block names the component and this filter emits the contract markup, exactly
-- the way understanding-explain-diff's filter emits its diff/diagram blocks.
--
--   * ```mermaid          -> <pre class="mermaid">…</pre>            (diagram)
--   * ```{.diff-source}    -> format toggle + <pre class="diff-source" hidden>
--                            + <div class="diff-render">             (diff)
--   * ```lang / ```{.nohighlight}
--                         -> <pre><code class="language-lang"> / .nohighlight
--                            (highlight — pandoc's own code output does not match
--                             the `pre > code.language-*` contract, so re-emit it)
--
-- The <html class="comments-gutter"> attribute and the component <head> tags are
-- template territory (a Lua filter cannot touch <html>/<head>): see
-- assets/template-tier2.html.

-- HTML-escape text injected into raw markup.
local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function has(classes, name)
  for _, c in ipairs(classes) do
    if c == name then return true end
  end
  return false
end

function CodeBlock(el)
  -- diagram: one <pre class="mermaid"> holding raw mermaid source.
  if has(el.classes, "mermaid") then
    return pandoc.RawBlock("html", '<pre class="mermaid">\n' .. esc(el.text) .. "\n</pre>")
  end

  -- diff: the layout toggle, the hidden unified-diff source, and the empty
  -- render target diff2html fills in (pre.diff-source must be the render div's
  -- immediate previous sibling).
  if has(el.classes, "diff-source") then
    return pandoc.RawBlock("html", table.concat({
      '<p class="diff-format-toggle" role="group">',
      '<button type="button" data-diff-format="line-by-line">Unified</button>',
      '<button type="button" data-diff-format="side-by-side">Side by side</button>',
      "</p>",
      '<pre class="diff-source" hidden>' .. esc(el.text) .. "</pre>",
      '<div class="diff-render"></div>',
    }, "\n"))
  end

  -- highlight: <pre><code class="language-X">, or .nohighlight to opt a block
  -- out. Every remaining code block on this page is a highlight demo.
  local codeclass
  if has(el.classes, "nohighlight") then
    codeclass = "nohighlight"
  else
    local lang = el.classes[1]
    codeclass = lang and ("language-" .. lang) or nil
  end
  local attr = codeclass and (' class="' .. codeclass .. '"') or ""
  return pandoc.RawBlock("html", "<pre><code" .. attr .. ">" .. esc(el.text) .. "</code></pre>")
end
