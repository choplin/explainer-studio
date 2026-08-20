from __future__ import annotations

import importlib.util
import json
import sys
import zipfile
from pathlib import Path
from types import ModuleType

import pytest

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests" / "fixtures" / "reflowable-epub"
SCRIPT = (
    ROOT
    / "skills"
    / "epub-explainer"
    / "epub-explainer-summarize"
    / "scripts"
    / "epub_extract.py"
)
LOCATOR_VALIDATOR = (
    ROOT
    / "skills"
    / "book-explainer"
    / "book-explainer-generate-site"
    / "scripts"
    / "validate_locators.py"
)


def load_module() -> ModuleType:
    spec = importlib.util.spec_from_file_location("epub_extract", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def load_locator_validator() -> ModuleType:
    spec = importlib.util.spec_from_file_location(
        "validate_locators", LOCATOR_VALIDATOR
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def build_epub(
    destination: Path, replacements: dict[str, str | bytes] | None = None
) -> None:
    replacements = replacements or {}
    written: set[str] = set()
    with zipfile.ZipFile(destination, "w") as archive:
        mimetype = FIXTURE / "mimetype"
        archive.write(mimetype, "mimetype", compress_type=zipfile.ZIP_STORED)
        for source in sorted(FIXTURE.rglob("*")):
            if not source.is_file() or source == mimetype:
                continue
            name = source.relative_to(FIXTURE).as_posix()
            written.add(name)
            if name in replacements:
                archive.writestr(name, replacements[name])
            else:
                archive.write(source, name, compress_type=zipfile.ZIP_DEFLATED)
        for name, contents in replacements.items():
            if name not in written:
                archive.writestr(name, contents)


def test_extracts_reflowable_epub_with_stable_locators_and_media(
    tmp_path: Path,
) -> None:
    module = load_module()
    source = tmp_path / "book.epub"
    work_dir = tmp_path / "book"
    build_epub(source)

    result = module.extract(source, work_dir, False)

    assert result["kind"] == "reflowable"
    assert result["supported"] is True
    locators = json.loads((work_dir / "epub" / "locators.json").read_text())
    canonical = {item["canonical"] for item in locators["locators"]}
    assert "OEBPS/Text/chapter.xhtml#chapter-one" in canonical
    assert "OEBPS/Text/chapter.xhtml#locator-example" in canonical
    assert "OEBPS/Text/chapter.xhtml#chapter-container" in canonical
    assert "OEBPS/Text/chapter.xhtml#nested-heading-target" in canonical
    assert "OEBPS/Text/chapter.xhtml#details" in locators["valid_locators"]
    validator = load_locator_validator()
    site_source = ROOT / "tests" / "fixtures" / "epub-reading-site-source.md"
    assert validator.validate_source(site_source, set(locators["valid_locators"])) == []
    generated = [item for item in locators["locators"] if item["generated"]]
    assert generated[0]["fragment"].startswith("generated-s0001-n")
    assert locators["page_list"] == [
        {
            "label": "17",
            "resource": "OEBPS/Text/chapter.xhtml",
            "fragment": "details",
        }
    ]
    assert (work_dir / "epub" / "media" / "OEBPS" / "Images" / "figure.svg").is_file()
    spine_path = work_dir / "epub" / "spine" / "item-0001.json"
    spine = json.loads(spine_path.read_text())
    assert any("<html:ruby" in block["source_xhtml"] for block in spine["blocks"])
    assert any(block["epub_type"] == "footnote" for block in spine["blocks"])
    figure = next(block for block in spine["blocks"] if block["type"] == "figure")
    assert figure["media"][0]["resource"] == "OEBPS/Images/figure.svg"
    toc = (work_dir / "structured" / "toc.md").read_text()
    assert "[loc:OEBPS/Text/chapter.xhtml#details] L2 | Details" in toc
    assert "Generated fragment heading" in toc
    assert toc.count("| Chapter One |") == 1
    source_index = json.loads((work_dir / "epub" / "source.json").read_text())
    auxiliary = next(item for item in source_index["spine"] if not item["linear"])
    notes = json.loads((work_dir / auxiliary["path"]).read_text())
    assert notes["resource"] == "OEBPS/Text/notes.xhtml"
    assert any(block["epub_type"] == "endnote" for block in notes["blocks"])


def test_rejects_fixed_layout_with_preflight_artifact(tmp_path: Path) -> None:
    module = load_module()
    source = tmp_path / "fixed.epub"
    work_dir = tmp_path / "fixed"
    opf = (FIXTURE / "OEBPS" / "content.opf").read_text()
    build_epub(
        source,
        {
            "OEBPS/content.opf": opf.replace(
                '<itemref idref="chapter"/>',
                '<itemref idref="chapter" properties="rendition:layout-pre-paginated"/>',
            )
        },
    )

    result = module.extract(source, work_dir, False)

    assert result["kind"] == "fixed-layout"
    assert result["supported"] is False
    persisted = json.loads((work_dir / "epub" / "preflight.json").read_text())
    assert persisted == result


def test_decodes_percent_encoded_epub_iris() -> None:
    module = load_module()

    assert (
        module.resolve_href("OEBPS/content.opf", "Text/chapter%20one.xhtml#section%202")
        == "OEBPS/Text/chapter one.xhtml"
    )
    assert module.href_fragment("Text/chapter.xhtml#section%202") == "section 2"


def test_requires_force_before_replacing_adapter_output(tmp_path: Path) -> None:
    module = load_module()
    source = tmp_path / "book.epub"
    work_dir = tmp_path / "book"
    build_epub(source)
    module.extract(source, work_dir, False)

    with pytest.raises(module.EpubError, match="pass --force"):
        module.extract(source, work_dir, False)


def test_force_keeps_previous_adapter_output_when_new_input_is_invalid(
    tmp_path: Path,
) -> None:
    module = load_module()
    source = tmp_path / "book.epub"
    invalid = tmp_path / "invalid.epub"
    work_dir = tmp_path / "book"
    build_epub(source)
    module.extract(source, work_dir, False)
    previous = (work_dir / "epub" / "preflight.json").read_text()
    invalid.write_bytes(b"not a zip")

    with pytest.raises(zipfile.BadZipFile):
        module.extract(invalid, work_dir, True)

    assert (work_dir / "epub" / "preflight.json").read_text() == previous
    assert (work_dir / "epub" / "media" / "OEBPS" / "Images" / "figure.svg").is_file()


def test_detects_image_only_epub(tmp_path: Path) -> None:
    module = load_module()
    source = tmp_path / "images.epub"
    work_dir = tmp_path / "images"
    image_only = """<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Page</title></head>
<body><img src="../Images/figure.svg" alt="page image"/></body></html>"""
    build_epub(source, {"OEBPS/Text/chapter.xhtml": image_only})

    result = module.extract(source, work_dir, False)

    assert result["kind"] == "image-only"
    assert result["supported"] is False


def test_detects_content_encryption_as_drm(tmp_path: Path) -> None:
    module = load_module()
    source = tmp_path / "encrypted.epub"
    work_dir = tmp_path / "encrypted"
    encryption = """<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
 xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData><enc:EncryptionMethod Algorithm="urn:example:drm"/></enc:EncryptedData>
</encryption>"""
    build_epub(source, {"META-INF/encryption.xml": encryption})

    result = module.extract(source, work_dir, False)

    assert result["kind"] == "drm-protected"
    assert result["supported"] is False


def test_classifies_drm_before_reading_encrypted_xhtml(tmp_path: Path) -> None:
    module = load_module()
    source = tmp_path / "encrypted-content.epub"
    work_dir = tmp_path / "encrypted-content"
    encryption = """<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
 xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData><enc:EncryptionMethod Algorithm="urn:example:drm"/></enc:EncryptedData>
</encryption>"""
    build_epub(
        source,
        {
            "META-INF/encryption.xml": encryption,
            "OEBPS/Text/chapter.xhtml": b"\x00\x01encrypted content",
        },
    )

    result = module.extract(source, work_dir, False)

    assert result["kind"] == "drm-protected"
    assert (work_dir / "epub" / "preflight.json").is_file()


def test_mixed_font_obfuscation_and_unknown_encryption_is_drm(tmp_path: Path) -> None:
    module = load_module()
    source = tmp_path / "mixed-encryption.epub"
    work_dir = tmp_path / "mixed-encryption"
    encryption = """<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
 xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData><enc:EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/></enc:EncryptedData>
  <enc:EncryptedData/>
</encryption>"""
    build_epub(source, {"META-INF/encryption.xml": encryption})

    result = module.extract(source, work_dir, False)

    assert result["kind"] == "drm-protected"
    assert "unknown" in result["encryption_algorithms"]


def test_accepts_short_text_led_reflowable_epub(tmp_path: Path) -> None:
    module = load_module()
    source = tmp_path / "short.epub"
    work_dir = tmp_path / "short"
    short_text = "x" * 151
    chapter = f"""<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Short</title></head>
<body><h1 id="chapter-one">Short</h1><p>{short_text}</p>
<img src="../Images/figure.svg" alt="illustration"/></body></html>"""
    build_epub(source, {"OEBPS/Text/chapter.xhtml": chapter})

    result = module.extract(source, work_dir, False)

    assert result["kind"] == "reflowable"
    assert result["supported"] is True


def test_detects_direct_svg_spine_as_image_only(tmp_path: Path) -> None:
    module = load_module()
    source = tmp_path / "svg-spine.epub"
    work_dir = tmp_path / "svg-spine"
    opf = (FIXTURE / "OEBPS" / "content.opf").read_text()
    opf = opf.replace('<itemref idref="chapter"/>', '<itemref idref="figure"/>')
    build_epub(source, {"OEBPS/content.opf": opf})

    result = module.extract(source, work_dir, False)

    assert result["kind"] == "image-only"
    assert result["supported"] is False


def test_rejects_dtd_declaration_beyond_initial_prefix() -> None:
    module = load_module()
    xml = (
        b" " * 4100
        + b'<!DOCTYPE root [<!ENTITY expanded "EXPANDED">]><root>&expanded;</root>'
    )

    with pytest.raises(module.EpubError, match="DTD/entity"):
        module.parse_xml(xml, "delayed-doctype.xml")


def test_site_validator_accepts_only_mapped_epub_locators(tmp_path: Path) -> None:
    validator = load_locator_validator()
    source = tmp_path / "page.md"
    source.write_text(
        'Known [section]{.source-locator data-locator="Text/ch.xhtml#known"}.\n'
        "Literal `example {.p}` stays code.\n"
    )

    assert validator.validate_source(source, {"Text/ch.xhtml#known"}) == []

    source.write_text(
        'Unknown [section]{.source-locator data-locator="Text/ch.xhtml#missing"}.\n'
        "Wrong [p12]{.p}.\n"
    )
    errors = validator.validate_source(source, {"Text/ch.xhtml#known"})
    assert any("unknown EPUB locator" in error for error in errors)
    assert any("PDF .p locator" in error for error in errors)
