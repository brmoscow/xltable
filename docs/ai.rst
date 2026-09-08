AI-friendly documentation
=========================

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

.. _cube_skill:

Skill for coding agents
-----------------------

If a coding agent (Claude Code, Cursor, Codex CLI, GitHub Copilot and the
like) writes your cube definitions from table DDL and requirements, give it
the **XLTable cube definition skill** — a compact guide in the open
`Agent Skills <https://agentskills.io>`_ format. Unlike the full
documentation it is written for the agent's working loop: the fixed block
order, the rules the parser enforces silently (backticks, ``FROM`` inside
expressions, alias matching between sources, ``one-table`` aliases), the
modeling patterns (calendar, mixed grains, flat tables, roles, AI semantics)
and a delivery checklist.

The skill is three files; download them into a folder named
``xltable-cube-definition``:

- :download:`SKILL.md <_static/skills/xltable-cube-definition/SKILL.md>` —
  workflow, skeleton, rules, checklist;
- :download:`reference.md <_static/skills/xltable-cube-definition/reference.md>`
  — every tag, naming, storage per warehouse, date functions per dialect;
- :download:`example.sql <_static/skills/xltable-cube-definition/example.sql>`
  — the :ref:`unified example <unified_example>` as a ready file.

Put the folder where your agent looks for skills — ``.claude/skills/`` in
the project (or ``~/.claude/skills/``) for Claude Code; Cursor, Codex CLI and
Copilot read the same ``SKILL.md`` layout from their own skills folders
(``.agents/skills/`` is understood by most of them) — and ask:

.. code-block:: text

   Here is the DDL of our sales tables and the requirements for the report.
   Write the XLTable cube definition and the INSERT for olap_definition.

Every definition the skill produces carries :tag:`definition_check_on`, so
the server validates it before serving data; with the :doc:`MCP server <mcp>`
connected the agent can also load the cube and check it with
``describe_cube`` / ``query_cube``. The skill is versioned with this
documentation — replace ``stable`` in the download URL with your XLTable
version to match the server you run.

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
   ``2.1.0``) or ``latest`` to match the XLTable release you are running.
