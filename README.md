# pdf2epub for Claude Code and Codex

Convert a PDF paper into an EPUB for reading on your phone, tablet or computer.

The agent reads the paper and transcribes it to Markdown with LaTeX maths.
Pandoc builds an EPUB with MathML, navigation, and disabled hyphenation.
This helps with maths-heavy papers whose PDF text layers lose symbols or layout.

## Get started

You need Claude Code or local Codex, pandoc 3+, Poppler, zsh, and perl.
On macOS, zsh and perl are included; install pandoc and Poppler with Homebrew:

```bash
brew install pandoc poppler
```

Clone the repository:

```bash
git clone https://github.com/JunmingZhao42/pdf2epub-skill.git
cd pdf2epub-skill
```

Then install the skill for your agent. Run the relevant commands from this folder.

**Claude Code**

```bash
mkdir -p ~/.claude/skills
ln -s "$PWD/skills/pdf2epub" ~/.claude/skills/pdf2epub
```

**Codex**

```bash
mkdir -p ~/.agents/skills
ln -s "$PWD/skills/pdf2epub" ~/.agents/skills/pdf2epub
```

These links follow updates to the checkout. Use `cp -R` instead of `ln -s` for
an independent copy. Start a new agent session if the skill does not appear.

## Use it

Ask your agent:

- "Convert this PDF to EPUB: /path/to/paper.pdf"
- "Make this paper readable on my phone: https://example.org/paper.pdf"

Files go in `pdf2epub/<slug>/` inside the current workspace, or a folder you specify.
The agent returns the EPUB and keeps the Markdown source beside it.
Open the EPUB in your preferred reader. Maths rendering depends on its MathML
support.

See the [usage guide](docs/usage.md) for Zotero, AirDrop, long papers,
output folders, and building the sample yourself.

## Privacy and accuracy

The selected agent's model provider processes the transcription inputs.
Poppler and pandoc run locally; the skill uses no third-party conversion service.
Optional Zotero lookup reads the database without changing it.

Transcription takes time and can misread unclear notation. Diagrams and plots are
kept as vector SVG figures where the source allows it; raster-only figures are
reported. Check important formulas against the original: a successful build
confirms conversion, not transcription accuracy.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for tests and symbol contributions.
The [symbol glossary](skills/pdf2epub/symbols.md) records notation and known pitfalls.

[MIT licence](LICENSE)
