# Symbol glossary

Read this before transcribing. Each row says how to write a symbol so pandoc turns it
into MathML, and what goes wrong otherwise. Add a row whenever a paper uses a symbol
that is missing here or was hard to get right (see "Adding a symbol" in SKILL.md).

## Order and lattice

| Glyph | LaTeX | Notes |
|---|---|---|
| ⊑ | `\sqsubseteq` | Refinement or order. Some PDFs' text layers store it as the letter "v", so read it from the page image, not the text. |
| ⊒ | `\sqsupseteq` | Reverse order, e.g. in Plotkin triples. Text layers may store it as "w". |
| ⊔ ⨆ | `\sqcup` / `\bigsqcup` | Binary and big join (lub). |
| ⊓ ⨅ | `\sqcap` / `\bigsqcap` | Binary and big meet. |
| ⊤ ⊥ | `\top` / `\bot` | |
| μ | `\mu X.\, e(X)` | Least fixed point; thin space after the dot. |

## Operators and composition

| Glyph | LaTeX | Notes |
|---|---|---|
| ∗ | `\ast` | Separating or concurrent composition. Use `\ast`, not a plain `*`, so it never clashes with Markdown emphasis. |
| ; | `;` | Sequential composition. Write `p; q`. In displays, `p \,; q` mirrors papers that space it. |
| ∥ | `\parallel` | Parallel composition of commands, e.g. `C_1 \parallel C_2`. `\|` gives the same glyph, but in a Markdown table it displays as a single bar on GitHub. |
| • | `\bullet` | Partial monoid operation on states. |
| # | `\#` | Compatibility or disjointness, e.g. `\sigma_0 \# \sigma_1`. |
| (−) | `(-)` | Placeholder argument, e.g. `(-) \ast \mathsf{skip}`. |

## Sets and relations

| Glyph | LaTeX | Notes |
|---|---|---|
| ⊆ ⊇ | `\subseteq` / `\supseteq` | |
| ⊈ | `\nsubseteq` | Don't write `\not\subseteq`; `\nsubseteq` converts reliably. |
| ⋃ | `\bigcup` | Big union over a set comprehension. |
| ∅ | `\emptyset` | |
| ℕ | `\mathbb{N}` | |
| ↦ | `\mapsto` | Heap cells, function update `h[n \mapsto l]`. |
| ⇀ | `\rightharpoonup_f` | Finite partial functions, e.g. `N \rightharpoonup_f N`. |

## Logic and triples

| Glyph | LaTeX | Notes |
|---|---|---|
| {p} c {q} | `\{p\}\, c\, \{q\}` | Hoare triple; thin spaces keep the braces apart. |
| →_c | `p \to_c q` | Plotkin triple. |
| ⟪X⟫ | `\langle\langle X \rangle\rangle` | Dijkstra triple brackets. `\llangle` renders the wrong glyph (⦉ ⦊). |
| ⇔ ⇒ ⟹ | `\Leftrightarrow` / `\Rightarrow` / `\Longrightarrow` | |
| ⊢ | `\vdash` | |
| inference rule | `\frac{premises}{conclusion}` | Separate several premises with `\qquad`. |

## Names and fonts

| Seen in the paper | LaTeX | Notes |
|---|---|---|
| sans-serif names (skip, nothing) | `\mathsf{skip}` | Keep the paper's font choice. |
| typewriter names | `\mathtt{skip}` | When the paper switches to typewriter. |
| italic multi-letter names (emp, dom, Traces, bpt) | `\mathit{emp}` | Plain `emp` would render as e·m·p. |
| text inside maths | `\text{if } … \text{ then } …` | |
| labelled formulas in an array | `\text{(label)}` | |

## Layout

| Need | LaTeX | Notes |
|---|---|---|
| equation number | `\tag{1}` | `build_epub.sh` turns it into "(1)". |
| aligned equations | `\begin{aligned} … &= … \\ \end{aligned}` | |
| table of formulas with labels | `\begin{array}{rc} … & … \\ \end{array}` | |

## Avoid (fails to convert or renders wrong)

| Don't write | Write instead |
|---|---|
| `\textasteriskcentered` | `\ast` |
| `{\it …}`, `{\bf …}`, `{\rm …}` | `\mathit{…}`, `\mathbf{…}`, `\mathrm{…}` |
| `\llangle`, `\rrangle` (converts, but to ⦉ ⦊) | `\langle\langle`, `\rangle\rangle` |
| `\operatorname { s k i p }` (spaced letters) | `\mathsf{skip}` |
| package macros (`\coloneqq`, custom `\newcommand`s) | expand them: `:=`, the macro's body |
