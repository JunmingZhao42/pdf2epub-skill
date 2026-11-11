#!/usr/bin/env bash
# Resolve the catalog and exercise the distributable payload outside the checkout.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/check_marketplace.XXXXXX")"
trap 'rm -rf "$work"' EXIT

python3 - "$here/.." "$work/plugin" <<'PY'
import json
import shutil
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
target = Path(sys.argv[2])
catalog = json.loads((root / '.agents/plugins/marketplace.json').read_text())
assert catalog['plugins'], 'marketplace has no plugins'
for entry in catalog['plugins']:
    source = entry['source']
    assert source['source'] == 'local', 'expected a repository-local payload'
    assert source['path'].startswith('./'), 'source must be relative to marketplace root'
    payload = (root / source['path']).resolve()
    payload.relative_to(root)
    manifest = json.loads((payload / 'plugin.json').read_text())
    assert manifest['name'] == entry['name'], 'plugin identity does not match catalog'
    assert manifest['version'], 'plugin version is missing'
    assert manifest['extensions']['com.openai']['requires_local_executor'] is True
    target.mkdir()
    shutil.copy2(payload / 'plugin.json', target / 'plugin.json')
    shutil.copytree(payload / 'skills', target / 'skills')
    skills = list((target / 'skills').glob('*/SKILL.md'))
    assert skills, 'package contains no skills'
    # These resources are needed after the plugin has been copied into a host cache.
    for skill in skills:
        for resource in ['build_epub.sh', 'symbols.md', 'figures.md']:
            assert (skill.parent / resource).is_file(), f'missing packaged resource: {resource}'
print('PASS  catalog resolves a self-contained plugin payload')
PY

(cd "$work" && "$work/plugin/skills/pdf2epub/build_epub.sh" --strict \
  "$here/../examples/sample.md" "$work/sample.epub") > "$work/output" 2> "$work/warnings"
[[ ! -s "$work/warnings" ]] || { cat "$work/warnings" >&2; exit 1; }
unzip -t "$work/sample.epub" > /dev/null
echo "PASS  packaged builder runs outside the checkout"
