-- reading-site.lua — binds source/editorial structure provenance for reading sites.
--
-- Report authors classify each body heading as either `.source-structure` or
-- `.editorial-structure`. Source headings stay visually quiet. Editorial headings
-- receive a subdued real-text marker (not CSS-only decoration), so both the in-page
-- heading and the generated TOC/sidebar retain the attribution. The first editorial
-- heading also receives an explanatory note.

local function meta_text(meta, key)
  local value = meta[key]
  if value == nil then return "" end
  return pandoc.utils.stringify(value)
end

function Span(el)
  if not el.classes:includes("source-locator") then return el end
  if el.attributes["data-locator"] == nil or el.attributes["data-locator"] == "" then
    error("reading-site: source-locator spans require a canonical data-locator")
  end
  return el
end

function Pandoc(doc)
  local label = meta_text(doc.meta, "editorial-structure-label")
  local note = meta_text(doc.meta, "editorial-structure-note")
  local note_emitted = false

  return doc:walk({
    Header = function(el)
      local source = el.classes:includes("source-structure")
      local editorial = el.classes:includes("editorial-structure")

      if source and editorial then
        error("reading-site: a heading cannot be both source-structure and editorial-structure")
      end
      if (source or editorial) and el.level ~= 2 and el.level ~= 3 then
        error("reading-site: structure provenance is allowed only on H2/H3 headings")
      end

      if not editorial then return el end
      if label == "" or note == "" then
        error("reading-site: editorial headings require editorial-structure-label and editorial-structure-note frontmatter")
      end

      el.content:insert(pandoc.Space())
      el.content:insert(pandoc.Span(
        { pandoc.Str(label) },
        pandoc.Attr("", { "structure-origin" })
      ))

      if note_emitted then return el end
      note_emitted = true
      return {
        pandoc.Div(
          { pandoc.Para({ pandoc.Str(note) }) },
          pandoc.Attr("", { "structure-note" })
        ),
        el,
      }
    end,
  })
end
