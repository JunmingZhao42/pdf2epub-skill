# pdf2epub: a Claude Code skill for maths-heavy papers

Turn a PDF paper into an EPUB you can read comfortably in Apple Books on an iPhone,
iPad or Mac, with the maths intact.

Ordinary PDF-to-EPUB converters work from the PDF's text layer. For maths-heavy papers
that layer is often wrong: symbols like ⊑ come out as the letter "v", formulas lose
their structure, sub- and superscripts flatten into the line, and display equations
turn into word salad. OCR tools do little better with notation.

This skill takes a different route. Claude reads the PDF page by page, as a person
would, and **transcribes** it to Markdown with LaTeX maths. Then
[`build_epub.sh`](skills/pdf2epub/build_epub.sh) runs pandoc to build an EPUB 3 with:

- maths as **MathML**, which Apple Books renders natively;
- **no hyphenation**, so symbols and names don't get split across lines;
- a **table of contents**, footnotes, tables and equation numbers.

A growing [symbol glossary](skills/pdf2epub/symbols.md) records how to write each
symbol so that it converts, and the pitfalls seen so far.

## Requirements

- [Claude Code](https://claude.com/claude-code) (CLI, desktop app or IDE extension)
- [pandoc](https://pandoc.org) 3 or later
- poppler (`pdfinfo`, `pdftoppm`) for page counts and rendering figures
- `zsh` to run `build_epub.sh` (preinstalled on macOS)
- `sqlite3`, only for the optional Zotero lookup

On macOS with Homebrew:

```bash
brew install pandoc poppler
```

## Install

Copy or symlink the skill folder into your Claude Code skills folder:

```bash
git clone https://github.com/JunmingZhao42/pdf2epub-skill.git
mkdir -p ~/.claude/skills
ln -s "$PWD/pdf2epub-skill/skills/pdf2epub" ~/.claude/skills/pdf2epub
```

(Use `cp -R` instead of `ln -s` if you'd rather not track the repository.) Claude Code
picks the skill up in new sessions.

## Usage

Ask in plain words:

- "Make an EPUB of arXiv 2101.00001"
- "Convert the PDF I just AirDropped" (it looks at the newest PDFs in `~/Downloads`)
- "EPUB of *&lt;title&gt;* from Zotero" (optional: needs Zotero with its data in
  `~/Zotero`)
- "Make this paper readable on my phone: https://example.org/paper.pdf"

Claude finds the PDF, works in `~/Downloads/pdf2epub/<slug>/`, transcribes the paper in
chunks of up to 10 pages, builds the EPUB, checks that every formula converted, and
gives you the file. Open it on an iPhone or iPad via Share → Books, or in Books on a
Mac.

To see what a transcription looks like, build the example:

```bash
skills/pdf2epub/build_epub.sh examples/sample.md sample.epub
```

## Privacy

The paper's content goes to Claude and nowhere else. The skill uses no conversion
services, websites or APIs, and doesn't upload the PDF anywhere; pandoc and poppler run
locally. (Claude Code itself sends what Claude reads to Anthropic, as for any file you
share with it.) The Zotero database is only ever read, never written.

## Limits

- **Slower than a converter.** Transcription takes a while on long papers; Claude
  tells you roughly how long before starting anything over about 40 pages.
- **Figures are images.** Diagrams and plots are rendered from the PDF as PNGs, not
  redrawn.
- Claude transcribes faithfully but can misread an unclear symbol. It is told to
  zoom in rather than guess, and to report anything it couldn't read with certainty.
  Spot-check key formulas against the PDF.

## Contributing a symbol

When a paper uses a symbol the glossary doesn't cover, or one that needed a second
try, add a row to [`symbols.md`](skills/pdf2epub/symbols.md). The skill does this
itself as it goes; to contribute the row back:

1. Check that the LaTeX converts, and to the right glyph:

   ```bash
   printf '%s\n' '$<latex>$' | pandoc -f markdown -t html --math-method=mathml 2>&1 >/dev/null \
     | grep "Could not convert" || echo converts
   printf '%s\n' '$<latex>$' | pandoc -f markdown -t html --math-method=mathml \
     | grep -oE "<m[ion][^>]*>[^<]*</m[ion]>"
   ```

2. Add the row to the right section: the glyph, the LaTeX that converts, and one short
   note on the pitfall (what the text layer showed, or what failed). If something
   must be avoided, put it under "Avoid".
3. Run `tests/check_symbols.sh` and `tests/build_sample.sh`, then open a pull request.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the row format and the tests.

## Repository layout

```
skills/pdf2epub/   the skill: SKILL.md, build_epub.sh, symbols.md
examples/          a made-up sample paper in the transcription format
tests/             glossary and build checks (run in CI)
```

## Licence

[MIT](LICENSE)
