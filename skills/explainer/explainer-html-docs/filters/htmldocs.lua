-- htmldocs.lua — binds the semantic-Markdown vocabulary to the explainer-html-docs
-- markup contract. This is the injectable "meaning -> presentation" rule layer.
--
-- What it guarantees (that hand-authored HTML cannot):
--   * A callout variant outside the allowed set is a HARD ERROR at generation
--     time, not a silently-wrong green box. The "well-formed error" the design
--     system warns about (wrong variant for the meaning) still needs a human,
--     but the STRUCTURAL error class (typo'd / invented variant) becomes loud.
--   * Every <table> is wrapped in .tablewrap — the contract forbids a bare
--     <table>, and here that is structurally guaranteed, not review-caught.
--   * .lede / .kicker / .pullquote emit <p class>, not <div class>.
--   * `layout:` is a closed vocabulary too, checked wherever it came from.

local ALLOWED = { note = true, tip = true, warn = true, danger = true, key = true }
local PCLASS = { lede = true, kicker = true, pullquote = true }
local LAYOUTS = { narrow = true, standard = true, wide = true }

-- Layout variant, same closed-vocabulary contract as a callout variant. build.sh
-- validates its own --layout flag so a bad CLI argument fails before pandoc runs;
-- this catches the other route in — a typo in a page's own `layout:` frontmatter,
-- which would otherwise emit a layout-<typo> class that base.css has no rule for
-- and render as `standard`, hiding the mistake.
function Meta(m)
  for _, key in ipairs({ "layout", "layout-default" }) do
    local v = m[key]
    if v ~= nil then
      local name = pandoc.utils.stringify(v)
      if not LAYOUTS[name] then
        error("htmldocs: unknown " .. key .. " '" .. name
          .. "' — allowed: narrow, standard, wide")
      end
    end
  end
  return m
end

-- HTML-escape text that the filter injects into raw markup (swatch captions etc.)
local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- render a Div's inline content to an HTML string (for <p class> components)
local function inlines_html(el)
  for _, b in ipairs(el.content) do
    if b.t == "Para" or b.t == "Plain" then
      return pandoc.write(pandoc.Pandoc({ pandoc.Plain(b.content) }), "html")
    end
  end
  return ""
end

function Div(el)
  local c = el.classes

  if c:includes("callout") then
    local variant = el.attributes["variant"] or "note"
    if not ALLOWED[variant] then
      error("htmldocs: unknown callout variant '" .. variant
        .. "' — allowed: note, tip, warn, danger, key")
    end
    el.attributes["variant"] = nil
    local classes = pandoc.List({ "callout" })
    if variant ~= "note" then classes:insert(variant) end
    el.classes = classes
    -- a single-paragraph callout renders as bare inline text (no <p> margin),
    -- matching the reference; multi-block callouts keep their <p> wrappers.
    if #el.content == 1 and el.content[1].t == "Para" then
      el.content = { pandoc.Plain(el.content[1].content) }
    end
    return el
  end

  for cls in pairs(PCLASS) do
    if c:includes(cls) then
      return pandoc.RawBlock("html", '<p class="' .. cls .. '">' .. inlines_html(el) .. "</p>")
    end
  end

  -- ramp: a row of color bars. tokens="--n-0,--n-100,..." -> <i> per token.
  if c:includes("ramp") then
    local bars = {}
    for tok in (el.attributes["tokens"] or ""):gmatch("[^,]+") do
      bars[#bars + 1] = '<i style="background: var(' .. tok:gsub("%s", "") .. ')"></i>'
    end
    return pandoc.RawBlock("html", '<div class="ramp">' .. table.concat(bars) .. "</div>")
  end

  -- swatch: a palette chip. bg=<css> name=<label> namecolor=<token?> val=<caption>
  if c:includes("swatch") then
    local a = el.attributes
    local namestyle = a["namecolor"] and (' style="color: var(' .. a["namecolor"] .. ')"') or ""
    return pandoc.RawBlock("html", table.concat({
      '<div class="swatch">',
      '<div class="bar" style="background: ' .. (a["bg"] or "") .. '"></div>',
      '<span class="name"' .. namestyle .. ">" .. esc(a["name"] or "") .. "</span>",
      '<div class="val">' .. esc(a["val"] or "") .. "</div>",
      "</div>",
    }))
  end

  -- player: an in-page audio-guide widget. src=<audio path> [label=<caption>].
  -- Emits the .player markup (which carries a raw <audio>, so the author cannot
  -- write it directly under -f markdown-raw_html) as a structural guarantee.
  if c:includes("player") then
    local a = el.attributes
    local src = a["src"]
    if not src or src == "" then
      error("htmldocs: .player requires a src= attribute (the audio file path)")
    end
    local label = a["label"] or "🔊 音声ガイド"
    return pandoc.RawBlock("html", table.concat({
      '<div class="player"><span>', esc(label), "</span>",
      '<audio controls preload="none" src="', esc(src), '"></audio></div>',
    }))
  end

  -- card-grid with a filter= attribute is the reading-nav filter target: strip the
  -- author-facing `filter` key and emit `data-reading-filter` (its value is the
  -- filter placeholder; an empty value uses reading-nav.js's neutral default). This
  -- is the semantic-notation way to author a filterable card index — the reading-nav
  -- bundle injects the search box and hides non-matching `.card` children at runtime.
  -- No-op unless the reading-nav bundle is shipped on the page.
  if c:includes("card-grid") and el.attributes["filter"] ~= nil then
    local placeholder = el.attributes["filter"]
    el.attributes["filter"] = nil
    el.attributes["data-reading-filter"] = placeholder
    return el
  end

  -- keypoints, card, card-grid, aside: pass the class through unchanged.
  return el
end

-- Source-media paths are relative to reports/. PDF crops are copied to figures/;
-- EPUB-native images and SVGs are copied to media/.
-- Rewrite the prefix so a page never points outside the site root — this makes
-- the caller's "grep '../'" review check unnecessary (the guarantee is at
-- generation time, not review time).
function Image(el)
  el.src = el.src:gsub("^%.%./ocr/figures/", "figures/")
  el.src = el.src:gsub("^%.%./epub/media/", "media/")
  return el
end

-- <mark> is a foundation element; base.css styles the element, not a class.
function Span(el)
  if el.classes:includes("mark") then
    return pandoc.RawInline("html", "<mark>" .. pandoc.utils.stringify(el) .. "</mark>")
  end
  return el
end

-- Contract: a <table> may never appear outside .tablewrap. Enforce it.
--
-- Also drop pandoc's inferred column widths. Past a certain source-line length
-- pandoc emits `<table style="width:100%">` plus a `<col style="width:N%">` per
-- column, which pins the table to its container and makes every cell wrap: a
-- table too wide for the measure then renders as a squeezed block instead of
-- scrolling inside .tablewrap the way the design system intends. Width is the
-- stylesheet's call, so clear the colspec widths (keeping alignment) and let the
-- table size to its content.
function Table(el)
  local specs = {}
  for i, spec in ipairs(el.colspecs) do
    specs[i] = { spec[1] } -- alignment only; absent width == ColWidthDefault
  end
  el.colspecs = specs
  return pandoc.Div({ el }, pandoc.Attr("", { "tablewrap" }))
end
