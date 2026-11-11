# Using pdf2epub

Install the skill using the [quick start](../README.md), then ask Claude Code or
Codex to convert a paper. Initial support is for local use on macOS with an
image-capable agent. Codex renders PDF pages with Poppler and views the images;
Claude Code can also use its native PDF reader.

## Marketplace installation (Codex)

With a Codex version that supports `codex plugin`:

```bash
codex plugin marketplace add JunmingZhao42/pdf2epub-skill --ref main
codex plugin add pdf2epub@pdf2epub
```

The first command registers this GitHub repository as a marketplace; the second
installs its plugin. You can also install **PDF to EPUB** from the **pdf2epub**
source in the desktop app's Plugins directory after adding the marketplace.
Start a new chat after installation. Install the local dependencies from the
README before converting a paper.

This is a repository marketplace, separate from the public OpenAI Plugin
Directory. It packages the same skill used by manual installations, without an
MCP server or account connection. The plugin requires local execution.

To refresh the GitHub catalog and its source checkout:

```bash
codex plugin marketplace upgrade pdf2epub
```

Then reinstall the plugin using the install command above to refresh its cached
copy, and start a new chat. If you previously installed the skill manually, use
one installation method to avoid duplicate skill entries.

## Manual installation

Clone the repository and run the installation commands from its root:

```bash
git clone https://github.com/JunmingZhao42/pdf2epub-skill.git
cd pdf2epub-skill
```

For Claude Code:

```bash
mkdir -p ~/.claude/skills
ln -s "$PWD/skills/pdf2epub" ~/.claude/skills/pdf2epub
```

For Codex:

```bash
mkdir -p ~/.agents/skills
ln -s "$PWD/skills/pdf2epub" ~/.agents/skills/pdf2epub
```

The links follow updates to the checkout. Use `cp -R` instead of `ln -s` for an
independent copy. Start a new session if the skill does not appear. Marketplace
installation in these instructions is for Codex; Claude Code uses the manual route.

## Finding a paper

Provide a local PDF path, a PDF link, a DOI, or an arXiv ID. For a DOI, the agent
looks for an open-access PDF. If none is available, provide a copy you can access.

For an AirDropped file, ask:

> Convert the PDF I just AirDropped to EPUB.

The agent checks the newest PDFs in `~/Downloads` and asks if the intended file
is unclear. AirDrop is an optional way to supply the source; conversion files
are written to the working directory described below.

For Zotero, ask:

> Make an EPUB of *<paper title>* from Zotero.

This optional lookup needs `sqlite3`, a local database at `~/Zotero/zotero.sqlite`,
and a downloaded PDF attachment. The database and attachment storage are read-only.
If several items match, the agent asks which one. If the attachment is not present,
it asks before opening Zotero to sync. A local PDF path works with other Zotero
data-directory layouts.

## Output folders and long papers

By default, each conversion uses `pdf2epub/<short-slug>/` in the current workspace.
Specify another working directory in your request if preferred. The folder holds
the Markdown, EPUB, rendered pages, figure crops, and any downloaded source PDF.
A supplied local PDF stays at its original path. If a source or destination is
outside the agent's permitted folders, use its normal permission prompt.

The agent appends completed page chunks to the Markdown as it works. Dense
mathematics needs smaller chunks. Papers over about 40 pages take longer; the
agent explains its approach before starting. The workflow has no automatic resume
tracking, but completed Markdown remains available after an interruption.

The transcription preserves sentences, footnotes, results, proofs, and references
in their original order. Running page furniture is omitted. Diagrams and plots
are preserved as SVG vectors, with captions kept as EPUB text. The agent checks
the extracted artwork against the source and reports unclear notation for review.

SVG keeps vector lines and lettering sharp when enlarged. A bitmap placed inside
an SVG remains a bitmap, so the agent also checks for embedded raster content.
Photographs and scans may be raster-only in the source; the agent reports these
cases and asks before retaining bitmap figures. See the
[figure workflow](../skills/pdf2epub/figures.md) for extraction details.

## Build the sample

From the repository root:

```bash
skills/pdf2epub/build_epub.sh --strict examples/sample.md sample.epub
```

This builds a made-up paper from Markdown; it does not exercise PDF transcription.
Open `sample.epub` in Books to inspect its formatting.

To rebuild your own transcription, replace the two paths:

```bash
skills/pdf2epub/build_epub.sh --strict /path/to/paper.md /path/to/paper.epub
```

Title and author come from the Markdown's YAML front matter. Images resolve
relative to the Markdown file. Quote paths containing spaces.

Strict mode fails when pandoc reports unconverted TeX or missing resources.
It prints diagnostics and leaves any existing output EPUB untouched. Fix the
Markdown or image paths and rebuild. Without `--strict`, the script keeps its
original behaviour: these issues produce warnings and an EPUB is still written.
Both modes require pandoc 3+ and report missing tools before building.

## Reading and checking the result

Open the EPUB in Books on a Mac, or use Share → Books on iPhone or iPad. The
Markdown source stays beside the EPUB for corrections and rebuilding.

Build checks establish that formulas converted and resources were found. They
cannot establish that every sentence or symbol matches the PDF. Compare important
results against the source, and review any uncertainty reported by the agent.
Reading-app behaviour is only validated when the resulting book is opened there.
