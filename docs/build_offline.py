"""Build an offline copy of the docs and pack it into a zip.

For a customer without internet access: unpack the archive anywhere and
open index.html in a browser. Navigation and search work from disk;
nothing is loaded from the network (see OFFLINE in conf.py).

    python build_offline.py

Result: _build/xltable-docs-<release>.zip
"""

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

DOCS = Path(__file__).resolve().parent
BUILD = DOCS / '_build'

release = re.search(r"^release\s*=\s*'([^']+)'",
                    (DOCS / 'conf.py').read_text(encoding='utf-8'),
                    re.MULTILINE).group(1)
name = f'xltable-docs-{release}'
out = BUILD / 'offline' / name

shutil.rmtree(BUILD / 'offline', ignore_errors=True)
subprocess.run(
    [sys.executable, '-m', 'sphinx', '-b', 'html', '-E',
     '-d', str(BUILD / 'offline-doctrees'), str(DOCS), str(out)],
    env={**os.environ, 'XLTABLE_OFFLINE': '1'},
    check=True,
)

# Build artefacts a reader does not need.
(out / '.buildinfo').unlink(missing_ok=True)
(out / 'objects.inv').unlink(missing_ok=True)

(out.parent / 'README.txt').write_text(
    f'XLTable {release} documentation\r\n\r\n'
    f'Open {name}\\index.html in a browser.\r\n'
    'No internet connection is required.\r\n',
    encoding='utf-8',
)

archive = shutil.make_archive(str(BUILD / name), 'zip', out.parent)
print(f'\nOffline docs: {archive}')
