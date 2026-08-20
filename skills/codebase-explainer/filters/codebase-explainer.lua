-- Bind codebase-explainer's code and diagram blocks to the Tier 2 component
-- contracts. The base filter runs first and owns all other semantic Markdown.

local function escape_text(value)
  return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function escape_attr(value)
  return (escape_text(value):gsub('"', "&quot;"))
end

local function has_class(classes, expected)
  for _, class in ipairs(classes) do
    if class == expected then return true end
  end
  return false
end

function CodeBlock(block)
  if has_class(block.classes, "mermaid") then
    return pandoc.RawBlock(
      "html",
      '<pre class="mermaid">\n' .. escape_text(block.text) .. "\n</pre>"
    )
  end

  local code_class
  if has_class(block.classes, "nohighlight") then
    code_class = "nohighlight"
  elseif block.classes[1] then
    code_class = "language-" .. block.classes[1]
  end

  local attr = code_class and (' class="' .. escape_attr(code_class) .. '"') or ""
  return pandoc.RawBlock(
    "html",
    "<pre><code" .. attr .. ">" .. escape_text(block.text) .. "</code></pre>"
  )
end
