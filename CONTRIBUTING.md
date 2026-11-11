# Contributing

Contributions are welcome, especially new rows for the symbol glossary
(`skills/pdf2epub/symbols.md`). Please don't add real papers, PDFs or EPUBs to the
repository; use made-up examples like `examples/sample.md`.

## Adding a symbol

1. Check that your LaTeX converts, and to the right glyph. The first command prints
   "converts" or pandoc's complaint. The second shows the glyphs it produced:

   ```bash
   printf '%s\n' '$<latex>$' | pandoc -f markdown -t html --math-method=mathml 2>&1 >/dev/null \
     | grep "Could not convert" || echo converts
   printf '%s\n' '$<latex>$' | pandoc -f markdown -t html --math-method=mathml \
     | grep -oE "<m[ion][^>]*>[^<]*</m[ion]>"
   ```

2. Add a row to the right section of `symbols.md`.
3. Run the tests (below) and open a pull request.

### Row format

Recommended entries (every section except "Avoid") have three columns:

```markdown
| Glyph | LaTeX | Notes |
|---|---|---|
| ⊑ | `\sqsubseteq` | Some text layers store it as the letter "v"; read it from the page image. |
```

- **Glyph:** the symbol as it appears in a paper (or a short description).
- **LaTeX:** the LaTeX that converts, in backticks. Several alternatives go in
  separate backtick spans, e.g. `` `\sqcup` / `\bigsqcup` ``. Use `…` for a
  placeholder; the test replaces it with `x`.
- **Notes:** one short, general note on the pitfall: what the PDF's text layer
  showed, or what failed. Keep it general, not tied to one paper.

Entries that must not be used go in the "Avoid" table, with two columns:

```markdown
| Don't write | Write instead |
|---|---|
| `{\it …}`, `{\bf …}` | `\mathit{…}`, `\mathbf{…}` |
```

The test pairs the spans by position: the first "Don't write" span with the first
"Write instead" span, and so on. Each "Don't write" entry must either fail to
convert, or render differently from its partner. An entry without a backticked
partner must fail to convert.

Only the LaTeX column of recommended rows is tested, so backticks in the Notes column
are free text. A literal `|` inside a cell must be written `\|`, and GitHub then
displays it as `|`, so prefer a LaTeX form without a bar (e.g. `\parallel`, not `\|`).

## The sample paper

`examples/sample.md` is meant to read well both as pandoc input and in GitHub's
preview. GitHub strips Markdown backslash escapes inside maths before rendering it,
so the sample avoids `\,` `\{` `\}` `\#` `\|` (it uses `\ `, `\lbrace`, `\rbrace`,
`\parallel`) and macros GitHub's MathJax lacks, such as `\bigsqcap`. These rules are
for the sample only: transcriptions follow `symbols.md`.

## Running the tests

You need pandoc 3 or later, `zsh` (for `build_epub.sh`), `perl` and `unzip`.

```bash
tests/check_symbols.sh   # every glossary entry converts; every "Avoid" entry fails or differs
tests/build_sample.sh    # builds examples/sample.md and checks the EPUB
```

CI runs both on ubuntu-latest with a pinned pandoc version (see
`.github/workflows/test.yml`). Whether some "Avoid" entries convert depends on the
pandoc version, so if a test passes locally but fails in CI, compare
`pandoc --version`.

## Changing the skill

`SKILL.md` and `build_epub.sh` define the workflow. Keep changes general, keep paths
generic (`~/Downloads`, `~/Zotero`), and make sure `tests/build_sample.sh` still
passes.
