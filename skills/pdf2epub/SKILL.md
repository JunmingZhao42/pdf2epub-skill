---
name: pdf2epub
description: Turn a PDF paper (from a link/DOI/arXiv ID, a Zotero item, or a PDF AirDropped to ~/Downloads) into an EPUB for reading in Apple Books on an iPhone, iPad or Mac. Claude reads the PDF and transcribes it to Markdown with LaTeX maths, then pandoc builds the EPUB (MathML, no hyphenation). Use whenever the user asks to convert a PDF or paper to EPUB, or to make a paper readable on their phone.
metadata:
  version: "2.0"
---

# PDF → EPUB by transcription

There is no OCR engine here. You read the PDF yourself with the Read tool, write a
faithful Markdown transcription with LaTeX maths, and `build_epub.sh` (next to this
file) turns it into an EPUB with pandoc.

## Rules

- **Transcribe, never summarise.** Every sentence, footnote, theorem, proof and
  reference goes in, in the original order and wording. Don't fix the authors' typos.
- The PDF goes only to you (Claude). Never upload it to another service: no
  conversion APIs or websites, and no iCloud hand-off.
- Never write into `~/Zotero/` (database or `storage/`). Read the database read-only.
- If your Bash sandbox blocks `~/Zotero` or `~/Downloads`, those commands need the
  sandbox disabled (or those folders allowed).

## 1. Find the PDF

**A link, DOI or arXiv ID.** Download into a new empty folder and check the file type:

```bash
D="$HOME/Downloads/pdf2epub/inbox-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$D"
curl -fL --max-time 120 -o "$D/paper.pdf" "<pdf url>"   # arXiv: https://arxiv.org/pdf/<id>
file "$D/paper.pdf"                                     # must say "PDF document"
```

For a DOI, find an open-access PDF from the landing page. If there isn't one, say so.

**A title or author of a paper in Zotero** (optional: only if the user has Zotero
with its data folder at `~/Zotero`; needs `sqlite3`). If there is no
`~/Zotero/zotero.sqlite`, ask for a link or the PDF instead.

```bash
sqlite3 -readonly "file:$HOME/Zotero/zotero.sqlite?immutable=1" "
SELECT p.itemID, v.value, ai.key, a.path
FROM items p
JOIN itemData d ON d.itemID = p.itemID
JOIN fields f ON f.fieldID = d.fieldID AND f.fieldName = 'title'
JOIN itemDataValues v ON v.valueID = d.valueID
JOIN itemAttachments a ON a.parentItemID = p.itemID AND a.contentType = 'application/pdf'
JOIN items ai ON ai.itemID = a.itemID
WHERE v.value LIKE '%<words from the title>%';"
```

The file is `~/Zotero/storage/<attachment key>/<path without "storage:">`. If several
items match, ask which one. If the file is missing, it hasn't synced to this Mac: ask
before starting Zotero (`open -a Zotero`) and wait for the file to appear.

**Otherwise** (for example "the PDF I just AirDropped"), run `ls -t ~/Downloads/*.pdf | head -3`.
Confirm with the user if the right file is unclear.

## 2. Plan

```bash
pdfinfo "<pdf>" | grep -E "Pages|Title"
```

- Work in `~/Downloads/pdf2epub/<short-slug>/`, and write `<short-slug>.md` there.
- Read in chunks of **at most 10 pages** (`Read` with `pages: "1-10"`, then `"11-20"`,
  and so on). Dense maths deserves smaller chunks.
- Over about 40 pages, tell the user roughly how long it will take before you start.

## 3. Transcribe

First read `symbols.md` (next to this file). It lists how to write each known symbol
so that it converts, and the pitfalls to avoid. Follow it.

Start the file with front matter, then append each chunk as soon as it's done, so a
long paper is never lost midway:

```markdown
---
title: "<paper title>"
author: ["<Author One>", "<Author Two>"]
date: "<year>"
---
```

Formatting rules:

- **Headings.** Use `#` for numbered sections and `##` for subsections. Keep the
  numbers ("# 3 Exchange Laws"). Put the abstract under `# Abstract`.
- **Inline maths.** `$…$`, including single symbols in prose: write "$p \ast q$", not
  "p ∗ q". Write symbols as `symbols.md` says.
- **Display maths.** Put `$$ … $$` on its own lines. Keep the equation numbers with
  `\tag{n}`; the build script turns them into "(n)". Multi-line displays use
  `\begin{aligned} … \end{aligned}` or `\begin{array}`.
- **Avoid** text-mode macros inside maths (`\textasteriskcentered`, `{\it …}`, `\bf`)
  and package-specific macros. If the paper defines its own macros, expand them.
- **Theorems, lemmas, definitions.** Start the paragraph with
  `**Lemma 3.7.**`. Proofs start with `*Proof.*` and end with ∎.
- **Footnotes** use `[^n]` with `[^n]: …` at the end of that section.
- **Tables** use pipe tables. Fall back to HTML for merged cells.
- **Figures and diagrams.** Render that page region instead of describing it:
  `pdftoppm -png -r 150 -f <p> -l <p> "<pdf>" <workdir>/fig-p<p>`, then crop with
  `-x/-y/-W/-H` if needed. Reference it as `![Figure 2: <caption>](fig-p5-05.png)`.
- **Skip** running headers and footers, page numbers, line numbers and publisher
  boilerplate, and rejoin words hyphenated across lines.
- **References** go in a final `# References` section, one entry per paragraph,
  keeping the labels ("[8]").

When a symbol is unclear, zoom in: render the page with
`pdftoppm -png -r 200 -f <p> -l <p>` and Read the image. Don't guess.

## 4. Build and check

```bash
~/.claude/skills/pdf2epub/build_epub.sh <workdir>/<slug>.md <workdir>/<slug>.epub
```

(Use the folder this SKILL.md is in if the skill is installed elsewhere.)

- For any formula listed as "left as raw TeX", fix the LaTeX and rebuild until the
  list is empty.
- Spot-check the key results: compare two or three main formulas against the PDF
  page images.

## Adding a symbol

When a paper uses a symbol that `symbols.md` doesn't cover, or one that needed a
second try (it didn't convert, or the PDF text layer misled you), add a row to the
right section of `symbols.md`:

1. Check the LaTeX converts, and to the right glyph. The first command prints
   "converts" or pandoc's complaint. The second shows the glyphs it produced:
   ```bash
   printf '%s\n' '$<latex>$' | pandoc -f markdown -t html --math-method=mathml 2>&1 >/dev/null \
     | grep "Could not convert" || echo converts
   printf '%s\n' '$<latex>$' | pandoc -f markdown -t html --math-method=mathml \
     | grep -oE "<m[ion][^>]*>[^<]*</m[ion]>"
   ```
2. Add the row: the glyph, the LaTeX that converts, and one short note on the pitfall
   (what the text layer showed, or what failed). If something must be avoided, put it
   under "Avoid".
3. In your final report, tell the user which rows you added.

Keep the notes general. A paper-specific macro goes in only if its expansion is a
pattern other papers will reuse.

## 5. Deliver

If the `SendUserFile` tool is available (Claude desktop app), send the EPUB with it
(`display: "attach"`); otherwise give the user the EPUB's full path. On an iPhone or
iPad the user opens it via Share → Books; on a Mac, it opens in Books directly.
Report anything you couldn't read with certainty. If the user wants the EPUB to stay
local, leave it in the work folder and say where it is.
