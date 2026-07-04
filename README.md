# XLTable Documentation

Documentation source for [XLTable](https://xltable.com) — an OLAP server that
connects Excel Pivot Tables directly to modern analytical databases
(ClickHouse, BigQuery, Snowflake, Trino, StarRocks, Databricks, Greenplum).

Published at: https://xltable-olap.readthedocs.io

For AI assistants the whole documentation is available as a single file
([llms.txt convention](https://llmstxt.org)):
https://xltable-olap.readthedocs.io/en/stable/llms-full.txt

## Building locally

Requires Python 3.12+.

```bash
pip install -r docs/requirements.txt
sphinx-build -b html docs docs/_build/html
```

Open `docs/_build/html/index.html` in a browser to preview.

## Releasing

Documentation versions are built by Read the Docs from git tags.
See [RELEASING.md](RELEASING.md) for the release procedure (in Russian).

## Contacts

- Website: https://xltable.com
- Telegram: https://t.me/XLTable
- Email: help@xltable.com
