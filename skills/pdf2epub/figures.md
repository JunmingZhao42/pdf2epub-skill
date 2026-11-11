# Vector figures

Preserve a diagram or plot as vector artwork in the EPUB. Use original vector
assets when available; otherwise extract the figure region from its PDF page as
SVG. Keep the caption outside the graphic so it remains EPUB text.

## Extract from the PDF

Use `pdftocairo` from Poppler. It can crop a region and write SVG directly:

```bash
pdftocairo -svg -f "$page" -l "$page" \
  -x "$x" -y "$y" -W "$width" -H "$height" \
  -paperw "$width" -paperh "$height" -nocenter \
  "$pdf" "$workdir/figure-2.svg"
```

Set `page` to the PDF's one-based page index. For SVG output, `x`, `y`, `width`,
and `height` are integer PDF points (72 per inch), measured from the top left
of the displayed page. The paper-size options make the SVG canvas match the crop;
`-nocenter` keeps the region at the canvas origin. Exclude the caption from the crop.

If choosing the rectangle from a page image rendered at `dpi`, convert its pixel
coordinates to points by multiplying by `72 / dpi`. Round the outer edges outward
to avoid clipping strokes or labels. Check rotated pages and non-default page
boxes visually; do not assume that coordinates from another rendering align.

For example, a crop at pixel `(310, 750)` with size `660 × 150` on a 150-dpi page
roughly corresponds to point `(148, 360)` with size `318 × 72`. Adjust the bounds
after inspecting the result.

## Check the artwork

Render the SVG to a temporary preview with an available SVG renderer and view it
beside the original page. Check every label, arrow, line, symbol, and crop boundary.
This preview may be PNG; embed the SVG itself in the EPUB.

Inspect the SVG source as well. Vector lettering may be represented by paths and
`use` elements, which remain scalable but may not be selectable as text. An
`image` element can embed a bitmap inside an SVG: wrapping a PNG in SVG does not
turn it into vector artwork. Mixed figures may contain both paths and bitmaps.

If extraction rasterises a vector figure, try to recover the original vector
asset or a faithful vector reconstruction, checking it against the source. If
vector output cannot be verified, report that limitation before delivery. For
photographs or scans that are raster in the source, explain that extraction cannot
recover vector detail and ask whether retaining the original bitmap is acceptable.
Do not trace pixels automatically and claim the result preserves the original
vector artwork.

## Include in the EPUB

Save the SVG beside the Markdown and reference it with a relative path:

```markdown
![Figure 2: The original caption.](figure-2.svg)
```

Build with `--strict`. Check that the EPUB contains the SVG resource and that its
artwork was preserved. Formula transcription still uses LaTeX converted to MathML;
SVG figures preserve their visual layout rather than reflowing as prose.
