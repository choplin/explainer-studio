-- htmldocs.lua — binds the semantic IR vocabulary to the understanding-html-docs
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

local ALLOWED = { note = true, tip = true, warn = true, danger = true, key = true }
local PCLASS = { lede = true, kicker = true, pullquote = true }

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

  -- keypoints, card, card-grid, aside: pass the class through unchanged.
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
function Table(el)
  return pandoc.Div({ el }, pandoc.Attr("", { "tablewrap" }))
end
