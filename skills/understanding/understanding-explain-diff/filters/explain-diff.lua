-- explain-diff.lua — the explain-diff CONSUMER vocabulary, chained AFTER
-- htmldocs.lua (`--lua-filter htmldocs.lua --lua-filter explain-diff.lua`).
-- htmldocs.lua binds the base design system; this filter binds explain-diff's
-- own semantic axes (risk / verify / walkthrough chunks / attention budget) to
-- the markup contract that understanding-explain-diff/assets/explain-diff.css
-- styles. It only handles vocabulary the author cannot express natively:
--
--   * .chunk         — a walkthrough card whose <header> (risk badge, files,
--                      verify-status) is BUILT from attributes.
--   * .review-plan   — inject the live progress-line (raw data-* spans the
--                      author cannot write under -f markdown-raw_html).
--   * .budget /      — <ul class="budget"> / <li data-risk> attention budget.
--     .budget-item
--   * mermaid /      — code blocks that must emit raw <pre class="mermaid"> and
--     diff-source      the diff2html source/render pair (raw HTML, author-forbidden).
--
-- Everything else is NATIVE pandoc: `::: {.ba-pair}` / `.ba-before` / `.ba-after`
-- / `.inferred-note` / `.review-point` render as `<div class>`, and
-- `[text]{.verified}` renders as `<span class="verified">` — no rule needed.

-- HTML-escape text injected into raw markup.
local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Render a list of blocks to an HTML string (RawBlocks pass through verbatim).
local function blocks_html(blocks)
  return pandoc.write(pandoc.Pandoc(blocks), "html")
end

-- Render a Div's first paragraph inlines to an HTML string (for one-line divs).
local function inlines_html(el)
  for _, b in ipairs(el.content) do
    if b.t == "Para" or b.t == "Plain" then
      return pandoc.write(pandoc.Pandoc({ pandoc.Plain(b.content) }), "html")
    end
  end
  return ""
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Page-level defaults, read from frontmatter in Pandoc() before the walk.
local reviewed_label = "チャンク確認済み"
local risk_labels = {}

local function handle_div(el)
  local c = el.classes

  -- attention budget --------------------------------------------------------
  if c:includes("budget-item") then
    local risk = el.attributes["risk"] or ""
    return pandoc.RawBlock("html",
      '<li data-risk="' .. esc(risk) .. '">' .. inlines_html(el) .. "</li>")
  end

  if c:includes("budget") then
    return pandoc.RawBlock("html",
      '<ul class="budget">' .. blocks_html(el.content) .. "</ul>")
  end

  -- review plan: keep the div (native <div class="review-plan">, styled by the
  -- context CSS incl. `.review-plan > h2`). Emit the heading as a direct-child
  -- <h2> from the `heading` attribute, and append the live progress line.
  if c:includes("review-plan") then
    local heading = el.attributes["heading"]
    if heading and heading ~= "" then
      el.attributes["heading"] = nil -- don't leak it as data-heading
      el.content:insert(1, pandoc.RawBlock("html", "<h2>" .. esc(heading) .. "</h2>"))
    end
    el.content:insert(pandoc.RawBlock("html", table.concat({
      '<p class="progress-line"><span data-progress-count>0</span> / ',
      '<span data-progress-total>0</span> ', esc(reviewed_label), "</p>",
    })))
    return el
  end

  -- walkthrough chunk: build the <header> from attributes, keep the body. -----
  if c:includes("chunk") then
    local a = el.attributes
    local risk = a["risk"]
    if not risk or risk == "" then
      error("explain-diff: .chunk requires a risk= attribute (high|medium|low)")
    end
    local tested = a["tested"]
    if tested ~= "yes" and tested ~= "no" then
      error("explain-diff: .chunk requires tested=yes|no (got '" .. tostring(tested) .. "')")
    end
    local risk_label = risk_labels[risk] or risk

    local h = pandoc.List({ "<header>" })
    h:insert('<label class="chunk-check"><input type="checkbox" data-review-check> '
      .. esc(reviewed_label) .. "</label>")
    h:insert('<span class="risk-badge" data-risk="' .. esc(risk) .. '">'
      .. esc(risk_label) .. "</span>")
    if a["pattern"] and a["pattern"] ~= "" then
      h:insert('<span class="pattern-tag">' .. esc(a["pattern"]) .. "</span>")
    end
    h:insert("<strong>" .. esc(a["title"] or "") .. "</strong>")
    if a["files"] and a["files"] ~= "" then
      local codes = {}
      for f in a["files"]:gmatch("[^,]+") do
        codes[#codes + 1] = "<code>" .. esc(trim(f)) .. "</code>"
      end
      h:insert('<div class="chunk-files">' .. table.concat(codes, ", ") .. "</div>")
    end
    h:insert('<p class="verify-status" data-tested="' .. tested .. '">'
      .. esc(a["verify"] or "") .. "</p>")
    h:insert("</header>")

    local out = pandoc.List()
    -- pandoc treats `id=slug` (and `#slug`) as the element IDENTIFIER, not an
    -- attribute — read el.identifier, falling back to an explicit id= attribute.
    local id = el.identifier
    if id == "" then id = a["id"] or "" end
    out:insert(pandoc.RawBlock("html",
      '<article class="chunk" data-risk="' .. esc(risk) .. '" data-chunk-id="'
      .. esc(id) .. '">' .. table.concat(h)))
    out:extend(el.content)
    out:insert(pandoc.RawBlock("html", "</article>"))
    return out
  end

  return nil -- leave every other div to native rendering / htmldocs.lua
end

local function handle_codeblock(el)
  local c = el.classes

  -- mermaid diagram: raw <pre class="mermaid"> the diagram component renders.
  if c:includes("mermaid") then
    return pandoc.RawBlock("html",
      '<pre class="mermaid">' .. esc(el.text) .. "</pre>")
  end

  -- diff excerpt: the diff2html source/render pair, collapsed under <details>.
  if c:includes("diff-source") then
    return pandoc.RawBlock("html", table.concat({
      "<details><summary>diff</summary>",
      '<pre class="diff-source" hidden>', esc(el.text), "</pre>",
      '<div class="diff-render"></div></details>',
    }))
  end

  return nil
end

-- Read frontmatter defaults, then walk (children first, so inner .budget-item /
-- .diff-source are transformed before their .budget / .chunk parents wrap them).
function Pandoc(doc)
  local m = doc.meta
  if m["reviewed-label"] then
    reviewed_label = pandoc.utils.stringify(m["reviewed-label"])
  end
  if m["risk-labels"] then
    for k, v in pairs(m["risk-labels"]) do
      risk_labels[k] = pandoc.utils.stringify(v)
    end
  end
  return doc:walk({ Div = handle_div, CodeBlock = handle_codeblock })
end
