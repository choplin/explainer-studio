# inline.awk — fold local asset references into a single self-contained page.
#
# Usage: awk -v assetdir="<out>/assets" -f inline.awk page.html > page.inlined.html
#
# Replaces `<link rel="stylesheet" href="assets/NAME.css">` with an inlined
# `<style>…</style>`, and `<script … src="assets/NAME.js">…</script>` with an
# inlined `<script>…</script>` (preserving `type="module"`), reading the file
# from assetdir. Remote refs (https://… CDN engines) and refs whose file is not
# in assetdir are left untouched — so the diff2html / mermaid CDN tags survive.
#
# This is the opt-in inline path (build.sh --inline). Copy-mode is the default
# and never runs this. Assumption: inlined scripts sit at <body> end (like
# explain-diff) — a `defer` script in <head> (e.g. base.js) is NOT safely
# inlinable there; those pages stay copy-mode. Gotcha: a raw "</script>" inside
# an inlined .js would split the tag (rare; the bundled components are clean).

function slurp(path,   line, out) {
  out = ""
  while ((getline line < path) > 0) out = out line "\n"
  close(path)
  return out
}

function assetname(line, key,   i, rest, q) {
  i = index(line, key)
  if (i == 0) return ""
  rest = substr(line, i + length(key))
  q = index(rest, "\"")
  if (q == 0) return ""
  return substr(rest, 1, q - 1)
}

{
  # CSS: <link ... href="assets/NAME.css" ...>
  if ($0 ~ /href="assets\/[^"]+\.css"/) {
    name = assetname($0, "href=\"assets/")
    full = assetdir "/" name
    if (name != "" && (getline probe < full) >= 0) {
      close(full)
      printf "<style>\n%s</style>\n", slurp(full)
      next
    }
    if (name != "") close(full)
  }
  # JS: <script ... src="assets/NAME.js" ...></script>
  if ($0 ~ /src="assets\/[^"]+\.js"/) {
    name = assetname($0, "src=\"assets/")
    full = assetdir "/" name
    if (name != "" && (getline probe < full) >= 0) {
      close(full)
      typ = ($0 ~ /type="module"/) ? " type=\"module\"" : ""
      printf "<script%s>\n%s</script>\n", typ, slurp(full)
      next
    }
    if (name != "") close(full)
  }
  print
}
