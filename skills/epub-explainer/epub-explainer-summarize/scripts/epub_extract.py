#!/usr/bin/env python3
"""Extract a reflowable EPUB into source-faithful, locator-addressable artifacts."""

from __future__ import annotations

import argparse
import json
import posixpath
import re
import shutil
import sys
import tempfile
import zipfile
from dataclasses import asdict, dataclass
from pathlib import Path, PurePosixPath
from typing import Any
from urllib.parse import unquote, urlsplit
from xml.etree import ElementTree as ET

CONTAINER_PATH = "META-INF/container.xml"
CONTAINER_NS = "urn:oasis:names:tc:opendocument:xmlns:container"
OPF_NS = "http://www.idpf.org/2007/opf"
DC_NS = "http://purl.org/dc/elements/1.1/"
EPUB_NS = "http://www.idpf.org/2007/ops"
XHTML_NS = "http://www.w3.org/1999/xhtml"
NCX_NS = "http://www.daisy.org/z3986/2005/ncx/"
FONT_OBFUSCATION_ALGORITHMS = {
    "http://www.idpf.org/2008/embedding",
    "http://ns.adobe.com/pdf/enc#RC",
}
MAX_ARCHIVE_BYTES = 512 * 1024 * 1024
MAX_MEMBER_BYTES = 100 * 1024 * 1024
MAX_COMPRESSION_RATIO = 200
EMITTED_BLOCK_TAGS = {
    "aside",
    "blockquote",
    "dl",
    "figure",
    "img",
    "ol",
    "p",
    "pre",
    "table",
    "ul",
    "svg",
}


class EpubError(RuntimeError):
    """Raised when an EPUB is malformed or unsafe to extract."""


@dataclass(frozen=True)
class ManifestItem:
    id: str
    href: str
    media_type: str
    properties: tuple[str, ...]


@dataclass
class Locator:
    canonical: str
    display: str
    spine_index: int
    resource: str
    fragment: str
    generated: bool
    dom_index: int
    heading_level: int | None
    heading: str | None
    linear: bool
    heading_canonical: str | None


def local_name(tag: str) -> str:
    """Return an XML tag without its namespace."""
    return tag.rsplit("}", 1)[-1]


def clean_text(value: str) -> str:
    """Collapse XML whitespace without changing textual order."""
    return re.sub(r"\s+", " ", value).strip()


def element_text(element: ET.Element) -> str:
    """Return normalized descendant text."""
    return clean_text("".join(element.itertext()))


def epub_type(element: ET.Element) -> str:
    """Read the namespaced EPUB semantic type."""
    return element.attrib.get(f"{{{EPUB_NS}}}type", element.attrib.get("epub:type", ""))


def safe_member_path(name: str) -> PurePosixPath:
    """Validate and normalize a ZIP member path."""
    path = PurePosixPath(name)
    if path.is_absolute() or ".." in path.parts or "\x00" in name or "\\" in name:
        raise EpubError(f"unsafe archive member path: {name}")
    return path


def read_member(archive: zipfile.ZipFile, name: str) -> bytes:
    """Read a validated EPUB member."""
    safe_member_path(name)
    try:
        return archive.read(name)
    except KeyError as error:
        raise EpubError(f"missing EPUB member: {name}") from error


def parse_xml(data: bytes, source: str) -> ET.Element:
    """Parse XML while rejecting DTD-bearing input."""
    lowered = data.lower()
    if b"<!doctype" in lowered or b"<!entity" in lowered:
        raise EpubError(f"DTD/entity declarations are not supported in {source}")
    try:
        return ET.fromstring(data)
    except ET.ParseError as error:
        raise EpubError(f"invalid XML in {source}: {error}") from error


def validate_archive(archive: zipfile.ZipFile) -> None:
    """Reject malformed containers and basic ZIP-bomb shapes."""
    names = archive.namelist()
    if not names or names[0] != "mimetype":
        raise EpubError("EPUB mimetype must be the first archive member")
    if read_member(archive, "mimetype").strip() != b"application/epub+zip":
        raise EpubError("archive mimetype is not application/epub+zip")

    total = 0
    for info in archive.infolist():
        safe_member_path(info.filename)
        total += info.file_size
        if info.file_size > MAX_MEMBER_BYTES:
            raise EpubError(f"archive member is too large: {info.filename}")
        if (
            info.compress_size
            and info.file_size / info.compress_size > MAX_COMPRESSION_RATIO
        ):
            raise EpubError(
                f"archive member compression ratio is unsafe: {info.filename}"
            )
    if total > MAX_ARCHIVE_BYTES:
        raise EpubError("EPUB expands beyond the supported 512 MiB limit")


def resolve_href(base_path: str, href: str) -> str:
    """Resolve a package-relative href without allowing archive traversal."""
    parsed = urlsplit(href)
    if parsed.scheme or parsed.netloc:
        return href
    href_path = unquote(parsed.path)
    resolved = posixpath.normpath(
        posixpath.join(posixpath.dirname(base_path), href_path)
    )
    return str(safe_member_path(resolved))


def href_fragment(href: str) -> str:
    """Return a decoded fragment identifier from an EPUB IRI reference."""
    return unquote(urlsplit(href).fragment)


def package_path(archive: zipfile.ZipFile) -> str:
    """Resolve the default package document from container.xml."""
    root = parse_xml(read_member(archive, CONTAINER_PATH), CONTAINER_PATH)
    entry = root.find(f".//{{{CONTAINER_NS}}}rootfile")
    if entry is None or not entry.attrib.get("full-path"):
        raise EpubError("container.xml has no rootfile full-path")
    path = entry.attrib["full-path"]
    safe_member_path(path)
    return path


def package_metadata(
    root: ET.Element, package: str
) -> tuple[
    dict[str, str],
    dict[str, ManifestItem],
    list[str],
    set[str],
    str | None,
    bool,
]:
    """Read metadata, manifest, spine order, and NCX id from the OPF."""
    metadata_node = root.find(f"{{{OPF_NS}}}metadata")
    manifest_node = root.find(f"{{{OPF_NS}}}manifest")
    spine_node = root.find(f"{{{OPF_NS}}}spine")
    if manifest_node is None or spine_node is None:
        raise EpubError("package document must contain manifest and spine")

    metadata: dict[str, str] = {}
    if metadata_node is not None:
        for key in ("title", "creator", "language", "identifier"):
            node = metadata_node.find(f"{{{DC_NS}}}{key}")
            if node is not None and element_text(node):
                metadata[key] = element_text(node)
        for node in metadata_node.findall(f"{{{OPF_NS}}}meta"):
            prop = node.attrib.get("property")
            if prop:
                metadata[prop] = element_text(node)

    manifest: dict[str, ManifestItem] = {}
    for node in manifest_node.findall(f"{{{OPF_NS}}}item"):
        item_id = node.attrib.get("id", "")
        href = node.attrib.get("href", "")
        if not item_id or not href:
            continue
        manifest[item_id] = ManifestItem(
            id=item_id,
            href=resolve_href(package, href),
            media_type=node.attrib.get("media-type", "application/octet-stream"),
            properties=tuple(node.attrib.get("properties", "").split()),
        )

    spine: list[str] = []
    linear_spine: set[str] = set()
    fixed_spine_item = False
    for node in spine_node.findall(f"{{{OPF_NS}}}itemref"):
        item_id = node.attrib.get("idref")
        if item_id and item_id in manifest:
            spine.append(item_id)
            if node.attrib.get("linear", "yes").lower() != "no":
                linear_spine.add(item_id)
            fixed_spine_item = fixed_spine_item or (
                "rendition:layout-pre-paginated"
                in node.attrib.get("properties", "").split()
            )
    if not spine:
        raise EpubError("package spine has no readable items")
    if not linear_spine:
        raise EpubError("package spine has no linear reading-order items")
    return (
        metadata,
        manifest,
        spine,
        linear_spine,
        spine_node.attrib.get("toc"),
        fixed_spine_item,
    )


def encryption_status(archive: zipfile.ZipFile) -> tuple[bool, list[str]]:
    """Distinguish font obfuscation from unsupported content encryption."""
    if "META-INF/encryption.xml" not in archive.namelist():
        return False, []
    root = parse_xml(
        read_member(archive, "META-INF/encryption.xml"), "META-INF/encryption.xml"
    )
    algorithms: list[str] = []
    for encrypted in root.iter():
        if local_name(encrypted.tag) != "EncryptedData":
            continue
        method = next(
            (
                node
                for node in encrypted.iter()
                if local_name(node.tag) == "EncryptionMethod"
            ),
            None,
        )
        algorithms.append(
            method.attrib.get("Algorithm", "unknown")
            if method is not None
            else "unknown"
        )
    unsupported = [
        value for value in algorithms if value not in FONT_OBFUSCATION_ALGORITHMS
    ]
    return bool(unsupported), algorithms


def nav_entries(
    root: ET.Element, nav_path: str, navigation_type: str = "toc"
) -> list[dict[str, Any]]:
    """Extract one source-authored EPUB 3 navigation hierarchy."""
    toc_nav: ET.Element | None = None
    for node in root.iter():
        if local_name(node.tag) == "nav" and navigation_type in epub_type(node).split():
            toc_nav = node
            break
    if toc_nav is None:
        return []

    def walk_list(node: ET.Element, level: int) -> list[dict[str, Any]]:
        result: list[dict[str, Any]] = []
        for child in node:
            if local_name(child.tag) != "li":
                continue
            link = next(
                (item for item in child if local_name(item.tag) in {"a", "span"}),
                None,
            )
            nested = next(
                (item for item in child if local_name(item.tag) == "ol"), None
            )
            if link is not None:
                href = link.attrib.get("href", "")
                resource = resolve_href(nav_path, href) if href else ""
                fragment = href_fragment(href)
                result.append(
                    {
                        "level": level,
                        "title": element_text(link),
                        "resource": resource,
                        "fragment": fragment,
                    }
                )
            if nested is not None:
                result.extend(walk_list(nested, level + 1))
        return result

    ordered = next(
        (node for node in toc_nav.iter() if local_name(node.tag) == "ol"), None
    )
    return walk_list(ordered, 1) if ordered is not None else []


def ncx_entries(root: ET.Element, ncx_path: str) -> list[dict[str, Any]]:
    """Extract a legacy NCX hierarchy."""
    result: list[dict[str, Any]] = []

    def walk(node: ET.Element, level: int) -> None:
        for point in node.findall(f"{{{NCX_NS}}}navPoint"):
            label = point.find(f"{{{NCX_NS}}}navLabel/{{{NCX_NS}}}text")
            content = point.find(f"{{{NCX_NS}}}content")
            href = content.attrib.get("src", "") if content is not None else ""
            result.append(
                {
                    "level": level,
                    "title": element_text(label) if label is not None else "",
                    "resource": resolve_href(ncx_path, href) if href else "",
                    "fragment": href_fragment(href),
                }
            )
            walk(point, level + 1)

    nav_map = root.find(f"{{{NCX_NS}}}navMap")
    if nav_map is not None:
        walk(nav_map, 1)
    return result


def ncx_page_entries(root: ET.Element, ncx_path: str) -> list[dict[str, Any]]:
    """Extract optional EPUB 2 print-page targets."""
    result: list[dict[str, Any]] = []
    for target in root.findall(f".//{{{NCX_NS}}}pageTarget"):
        label = target.find(f"{{{NCX_NS}}}navLabel/{{{NCX_NS}}}text")
        content = target.find(f"{{{NCX_NS}}}content")
        href = content.attrib.get("src", "") if content is not None else ""
        result.append(
            {
                "label": element_text(label) if label is not None else "",
                "resource": resolve_href(ncx_path, href) if href else "",
                "fragment": href_fragment(href),
            }
        )
    return result


def serialize_fragment(element: ET.Element) -> str:
    """Serialize source XHTML as an audit-preserving fragment."""
    return ET.tostring(element, encoding="unicode", method="html")


def markdown_block(element: ET.Element) -> str:
    """Render a useful Markdown view while the source fragment remains in JSON."""
    tag = local_name(element.tag)
    text = element_text(element)
    if not text and tag not in {"img", "svg"}:
        return ""
    if tag == "p":
        return text
    if tag == "blockquote":
        return "\n".join(f"> {line}" for line in text.splitlines())
    if tag in {"ul", "ol"}:
        items = [element_text(node) for node in element if local_name(node.tag) == "li"]
        if tag == "ol":
            return "\n".join(f"{index}. {item}" for index, item in enumerate(items, 1))
        return "\n".join(f"- {item}" for item in items)
    if tag == "pre":
        return f"```{{.nohighlight}}\n{text}\n```"
    if tag == "table":
        return serialize_fragment(element)
    if tag in {"aside", "section", "div", "figure", "figcaption", "dl"}:
        return text
    return text


def extract_spine_document(
    archive: zipfile.ZipFile,
    item: ManifestItem,
    spine_index: int,
    linear: bool,
) -> tuple[list[dict[str, Any]], list[Locator], int, int]:
    """Extract semantic blocks and stable heading locators from one spine item."""
    root = parse_xml(read_member(archive, item.href), item.href)
    elements = list(root.iter())
    parent_map = {child: parent for parent in elements for child in parent}
    heading_info: dict[ET.Element, tuple[int, str, bool, str]] = {}
    for index, element in enumerate(elements, 1):
        tag = local_name(element.tag).lower()
        if not re.fullmatch(r"h[1-6]", tag):
            continue
        fragment = element.attrib.get("id", "")
        generated = not fragment
        if generated:
            fragment = f"generated-s{spine_index:04d}-n{index:06d}"
        heading_info[element] = (
            int(tag[1]),
            fragment,
            generated,
            element_text(element),
        )
    blocks: list[dict[str, Any]] = []
    locators: list[Locator] = []
    seen_locators: set[str] = set()
    text_count = 0
    image_count = 0

    for dom_index, element in enumerate(elements, 1):
        tag = local_name(element.tag).lower()
        if tag in {"script", "style", "head", "title"}:
            continue
        text = element_text(element)
        is_heading = element in heading_info
        heading_level = heading_info[element][0] if is_heading else None
        fragment = element.attrib.get("id", "")
        generated = heading_info[element][2] if is_heading else False
        if is_heading:
            fragment = heading_info[element][1]
        canonical = f"{item.href}#{fragment}" if fragment else item.href
        owner = element if is_heading else None
        ancestor = parent_map.get(element)
        while owner is None and ancestor is not None:
            if ancestor in heading_info:
                owner = ancestor
                break
            ancestor = parent_map.get(ancestor)
        if owner is None and tag in {"section", "article", "div"}:
            owner = next(
                (node for node in element.iter() if node in heading_info), None
            )
        heading_canonical = None
        if owner is not None:
            heading_canonical = f"{item.href}#{heading_info[owner][1]}"
        if fragment and canonical not in seen_locators:
            seen_locators.add(canonical)
            locators.append(
                Locator(
                    canonical=canonical,
                    display=text if heading_level is not None else canonical,
                    spine_index=spine_index,
                    resource=item.href,
                    fragment=fragment,
                    generated=generated,
                    dom_index=dom_index,
                    heading_level=heading_level,
                    heading=text if heading_level is not None else None,
                    linear=linear,
                    heading_canonical=heading_canonical,
                )
            )
        if tag == "img" or tag == "svg":
            image_count += 1
        if tag not in EMITTED_BLOCK_TAGS and not is_heading:
            continue
        parent = parent_map.get(element)
        if parent is not None and local_name(parent.tag).lower() in EMITTED_BLOCK_TAGS:
            # Atomic blocks retain their complete XHTML fragment; do not emit their
            # descendants a second time.
            continue
        text_count += len(text)
        blocks.append(
            {
                "type": "heading" if heading_level is not None else tag,
                "level": heading_level,
                "locator": canonical,
                "epub_type": epub_type(element),
                "language": element.attrib.get(
                    "{http://www.w3.org/XML/1998/namespace}lang"
                ),
                "text": text,
                "markdown": markdown_block(element),
                "source_xhtml": serialize_fragment(element),
                "media": [
                    {
                        "resource": resolve_href(item.href, node.attrib["src"]),
                        "alt": node.attrib.get("alt", ""),
                    }
                    for node in element.iter()
                    if local_name(node.tag).lower() == "img" and node.attrib.get("src")
                ],
            }
        )
    return blocks, locators, text_count, image_count


def navigation(
    archive: zipfile.ZipFile,
    manifest: dict[str, ManifestItem],
    ncx_id: str | None,
) -> tuple[list[dict[str, Any]], str, list[dict[str, Any]]]:
    """Read EPUB 3 nav, then EPUB 2 NCX, in that order."""
    nav_item = next(
        (item for item in manifest.values() if "nav" in item.properties), None
    )
    if nav_item is not None:
        nav_root = parse_xml(read_member(archive, nav_item.href), nav_item.href)
        entries = nav_entries(nav_root, nav_item.href)
        if entries:
            page_list = [
                {
                    "label": entry["title"],
                    "resource": entry["resource"],
                    "fragment": entry["fragment"],
                }
                for entry in nav_entries(nav_root, nav_item.href, "page-list")
            ]
            return entries, "nav.xhtml", page_list
    if ncx_id and ncx_id in manifest:
        ncx = manifest[ncx_id]
        entries = ncx_entries(parse_xml(read_member(archive, ncx.href), ncx.href))
        if entries:
            ncx_root = parse_xml(read_member(archive, ncx.href), ncx.href)
            return entries, "NCX", ncx_page_entries(ncx_root, ncx.href)
    return [], "headings", []


def classify(
    metadata: dict[str, str],
    manifest: dict[str, ManifestItem],
    spine: list[str],
    text_count: int,
    image_count: int,
    fixed_spine_item: bool,
    linear_spine: set[str],
) -> tuple[str, bool, str]:
    """Classify the EPUB into an explicitly supported or unsupported route."""
    fixed = (
        metadata.get("rendition:layout") == "pre-paginated"
        or fixed_spine_item
        or any(
            "rendition:layout-pre-paginated" in manifest[item_id].properties
            for item_id in spine
        )
    )
    if fixed:
        return (
            "fixed-layout",
            False,
            "fixed-layout EPUB requires a visual-reading route",
        )
    primary_items = [manifest[item_id] for item_id in spine if item_id in linear_spine]
    direct_image_spine = any(
        item.media_type.startswith("image/") or item.media_type == "image/svg+xml"
        for item in primary_items
    )
    xhtml_items = sum(
        item.media_type in {"application/xhtml+xml", "text/html"}
        for item in primary_items
    )
    if direct_image_spine or xhtml_items == 0:
        return "image-only", False, "image-only EPUB requires a visual-reading route"
    if image_count >= xhtml_items and text_count < 40:
        return "image-only", False, "image-only EPUB requires a visual-reading route"
    return "reflowable", True, "native XHTML extraction is supported"


def write_json(path: Path, value: Any) -> None:
    """Write stable, readable JSON."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def copy_media(
    archive: zipfile.ZipFile,
    manifest: dict[str, ManifestItem],
    destination: Path,
) -> list[dict[str, str]]:
    """Copy original image and SVG resources without rasterization."""
    copied: list[dict[str, str]] = []
    for item in manifest.values():
        if not (
            item.media_type.startswith("image/") or item.media_type == "image/svg+xml"
        ):
            continue
        target = destination / PurePosixPath(item.href)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(read_member(archive, item.href))
        copied.append(
            {
                "source": item.href,
                "path": f"epub/media/{item.href}",
                "media_type": item.media_type,
            }
        )
    return copied


def display_labels(
    entries: list[dict[str, Any]], locators: list[Locator]
) -> dict[str, str]:
    """Map canonical locators to source-authored navigation labels."""
    result: dict[str, str] = {}
    stack: list[str] = []
    for entry in entries:
        level = int(entry["level"])
        stack = stack[: level - 1]
        stack.append(entry["title"])
        canonical = entry["resource"]
        if entry["fragment"]:
            canonical += f"#{entry['fragment']}"
        result[canonical] = " › ".join(stack)
    current_heading: dict[int, str] = {}
    for locator in locators:
        if locator.canonical in result:
            locator.display = result[locator.canonical]
        if locator.heading_level is not None:
            current_heading[locator.spine_index] = locator.display
        elif locator.spine_index in current_heading:
            locator.display = current_heading[locator.spine_index]
    return result


def write_toc(
    path: Path,
    entries: list[dict[str, Any]],
    locators: list[Locator],
    nav_source: str,
) -> None:
    """Write one spine reconciled from authored navigation and XHTML headings."""
    locator_by_target = {locator.canonical: locator for locator in locators}
    resource_order: dict[str, int] = {}
    for locator in locators:
        resource_order.setdefault(locator.resource, locator.spine_index)
    rows: list[str] = [
        "# Source structure",
        "",
        f"Navigation source: {nav_source}",
        "",
        "## Headings",
        "",
    ]
    reconciled: list[tuple[tuple[int, int, int], str, int, str, bool, bool]] = []
    seen: set[str] = set()
    covered_headings: set[str] = set()
    for nav_index, entry in enumerate(entries):
        canonical = entry["resource"]
        if entry["fragment"]:
            canonical += f"#{entry['fragment']}"
        locator = locator_by_target.get(canonical)
        position = (
            locator.spine_index
            if locator
            else resource_order.get(entry["resource"], 10**9),
            locator.dom_index if locator else -1,
            nav_index,
        )
        reconciled.append(
            (
                position,
                canonical,
                int(entry["level"]),
                entry["title"],
                False,
                locator.linear if locator else True,
            )
        )
        seen.add(canonical)
        if locator and locator.heading_canonical:
            covered_headings.add(locator.heading_canonical)
    for locator in locators:
        if (
            locator.heading_level is None
            or locator.canonical in seen
            or locator.canonical in covered_headings
        ):
            continue
        reconciled.append(
            (
                (locator.spine_index, locator.dom_index, len(entries)),
                locator.canonical,
                locator.heading_level,
                locator.heading or "",
                locator.generated,
                locator.linear,
            )
        )
    for _, canonical, level, title, generated, linear in sorted(reconciled):
        suffix = " generated" if generated else ""
        if not linear:
            suffix += " auxiliary"
        rows.append(f"- [loc:{canonical}] L{level} | {title} |{suffix}".rstrip())
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(rows) + "\n", encoding="utf-8")


def write_outline(path: Path, documents: list[dict[str, Any]]) -> None:
    """Write a readable faithful outline from extracted semantic blocks."""
    rows = [
        "# Extracted outline",
        "",
        "Source references use canonical EPUB locators.",
        "",
    ]
    for document in documents:
        role = "linear" if document["linear"] else "auxiliary"
        rows.extend([f"<!-- spine-item: {document['resource']} role={role} -->", ""])
        for block in document["blocks"]:
            if block["type"] == "heading":
                level = min(int(block["level"]) + 1, 6)
                rows.extend(
                    [
                        f"{'#' * level} {block['text']}",
                        f"<!-- source-locator: {block['locator']} -->",
                        "",
                    ]
                )
            elif block["markdown"]:
                rows.extend([block["markdown"], ""])
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(rows).rstrip() + "\n", encoding="utf-8")


def publish_directory(staging: Path, destination: Path) -> None:
    """Replace one adapter-owned directory only after staging has succeeded."""
    if destination.exists():
        shutil.rmtree(destination)
    staging.replace(destination)


def extract(source: Path, work_dir: Path, force: bool) -> dict[str, Any]:
    """Run the EPUB adapter and return its preflight result."""
    final_epub_dir = work_dir / "epub"
    if final_epub_dir.exists() and not force:
        raise EpubError(
            f"output already exists: {final_epub_dir}; confirm replacement and pass --force"
        )
    work_dir.mkdir(parents=True, exist_ok=True)

    with (
        tempfile.TemporaryDirectory(
            prefix=".epub-extract-", dir=work_dir
        ) as staging_root,
        zipfile.ZipFile(source) as archive,
    ):
        staging = Path(staging_root)
        epub_dir = staging / "epub"
        epub_dir.mkdir(parents=True)
        validate_archive(archive)
        package = package_path(archive)
        package_root = parse_xml(read_member(archive, package), package)
        (
            metadata,
            manifest,
            spine,
            linear_spine,
            ncx_id,
            fixed_spine_item,
        ) = package_metadata(package_root, package)
        drm_protected, algorithms = encryption_status(archive)
        if drm_protected:
            preflight = {
                "source": str(source.resolve()),
                "format": "epub",
                "kind": "drm-protected",
                "supported": False,
                "reason": "encrypted content resources are outside this pipeline",
                "package_document": package,
                "navigation_source": "unread (encrypted content)",
                "print_page_targets": 0,
                "spine_items": len(spine),
                "linear_spine_items": len(linear_spine),
                "text_characters": 0,
                "images": 0,
                "encryption_algorithms": algorithms,
            }
            write_json(epub_dir / "preflight.json", preflight)
            publish_directory(epub_dir, final_epub_dir)
            return preflight
        entries, nav_source, page_list = navigation(archive, manifest, ncx_id)

        documents: list[dict[str, Any]] = []
        locators: list[Locator] = []
        text_count = 0
        image_count = 0
        primary_text_count = 0
        primary_image_count = 0
        for index, item_id in enumerate(spine, 1):
            item = manifest[item_id]
            if item.media_type not in {"application/xhtml+xml", "text/html"}:
                continue
            blocks, item_locators, item_text, item_images = extract_spine_document(
                archive, item, index, item_id in linear_spine
            )
            documents.append(
                {
                    "spine_index": index,
                    "manifest_id": item_id,
                    "resource": item.href,
                    "linear": item_id in linear_spine,
                    "blocks": blocks,
                }
            )
            locators.extend(item_locators)
            text_count += item_text
            image_count += item_images
            if item_id in linear_spine:
                primary_text_count += item_text
                primary_image_count += item_images

        kind, supported, reason = classify(
            metadata,
            manifest,
            spine,
            primary_text_count,
            primary_image_count,
            fixed_spine_item,
            linear_spine,
        )
        preflight = {
            "source": str(source.resolve()),
            "format": "epub",
            "kind": kind,
            "supported": supported,
            "reason": reason,
            "package_document": package,
            "navigation_source": nav_source,
            "print_page_targets": len(page_list),
            "spine_items": len(spine),
            "linear_spine_items": len(linear_spine),
            "text_characters": text_count,
            "images": image_count,
            "encryption_algorithms": algorithms,
        }
        write_json(epub_dir / "preflight.json", preflight)
        if not supported:
            publish_directory(epub_dir, final_epub_dir)
            return preflight

        labels = display_labels(entries, locators)
        valid_locators = {locator.canonical for locator in locators} | {
            document["resource"] for document in documents
        }
        media = copy_media(archive, manifest, epub_dir / "media")
        write_json(epub_dir / "metadata.json", metadata)
        spine_index: list[dict[str, Any]] = []
        for document in documents:
            item_path = Path("spine") / f"item-{document['spine_index']:04d}.json"
            write_json(epub_dir / item_path, document)
            spine_index.append(
                {
                    "spine_index": document["spine_index"],
                    "manifest_id": document["manifest_id"],
                    "resource": document["resource"],
                    "linear": document["linear"],
                    "path": f"epub/{item_path.as_posix()}",
                }
            )
        write_json(
            epub_dir / "source.json",
            {
                "metadata": metadata,
                "package_document": package,
                "spine": spine_index,
                "media": media,
            },
        )
        write_json(
            epub_dir / "locators.json",
            {
                "version": 1,
                "canonical_format": "<spine-resource>#<fragment>",
                "valid_locators": sorted(valid_locators),
                "navigation_labels": labels,
                "page_list": page_list,
                "locators": [asdict(locator) for locator in locators],
            },
        )
        staged_toc = staging / "toc.md"
        staged_outline = staging / "outline.md"
        write_toc(staged_toc, entries, locators, nav_source)
        write_outline(staged_outline, documents)
        structured = work_dir / "structured"
        structured.mkdir(parents=True, exist_ok=True)
        staged_toc.replace(structured / "toc.md")
        staged_outline.replace(structured / "outline.md")
        publish_directory(epub_dir, final_epub_dir)
        return preflight


def parser() -> argparse.ArgumentParser:
    """Build the command-line parser."""
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("source", type=Path, help="DRM-free EPUB file")
    result.add_argument("work_dir", type=Path, help="pipeline work directory")
    result.add_argument(
        "--force",
        action="store_true",
        help="replace only the adapter-owned epub/ output directory",
    )
    return result


def main() -> int:
    """CLI entry point."""
    args = parser().parse_args()
    if not args.source.is_file():
        print(f"error: source EPUB does not exist: {args.source}", file=sys.stderr)
        return 1
    try:
        result = extract(args.source, args.work_dir, args.force)
    except (EpubError, OSError, zipfile.BadZipFile) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result["supported"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
