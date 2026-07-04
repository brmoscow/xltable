AI assistants
=============

Asking ChatGPT, Claude or another AI assistant about XLTable? Don't paste
links to individual documentation pages — most assistants only read the one
page you give them and miss the rest. Instead, give the assistant the
**entire documentation as a single plain-text file**:

.. code-block:: text

   https://xltable-olap.readthedocs.io/en/stable/llms-full.txt

This file contains every page of this documentation (installation, cube
reference, Jinja templating, Excel connectivity, samples, FAQ) in one
LLM-friendly document. It is small enough to fit into the context window of
any modern AI model and is regenerated automatically on every release, so it
is always up to date.

Example prompt
--------------

.. code-block:: text

   Read the XLTable documentation:
   https://xltable-olap.readthedocs.io/en/stable/llms-full.txt

   Then help me build a cube with row-level security for our
   ClickHouse sales table.

Machine-readable index
----------------------

Following the `llms.txt convention <https://llmstxt.org>`_, a short index
with a project summary and links to every page is also available:

.. code-block:: text

   https://xltable-olap.readthedocs.io/en/stable/llms.txt

Use it when the assistant supports following links and you want it to fetch
only the relevant pages instead of the full document.

.. tip::

   Both files exist for every published version of the documentation —
   replace ``stable`` in the URL with a version number (for example
   ``2.0.15``) or ``latest`` to match the XLTable release you are running.
