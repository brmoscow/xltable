Cubes page
==========

A cube is a SQL text with ``--olap_*`` tags (see :doc:`cubes`). The analyst
writes it in their own SQL editor, saves it, opens Excel — and gets an error
or wrong numbers with no hint about the line at fault. The **Cubes** page of
the web application (``/cubes``) is the place where a cube's state is
visible: what the server understood from the definition, where in the text
the problems are, and what numbers and SQL a layout produces — without
opening Excel.

There is no editor on the page: the definition is still edited in the SQL
editor of your choice; the page shows the result. Save the file (or the row
of ``olap_definition``), press **Reload cubes** on the page.

------------------------------------------------------------

Who sees the page
-----------------

The page is for analysts who build cubes, not for every user of the data: it
shows the SQL of the sources, the roles and the access filters of a cube.
It opens for

- members of the groups listed in :confval:`ANALYST_GROUPS` (local groups
  from :confval:`USER_GROUPS` or Active Directory groups);
- administrators (:confval:`ADMIN_GROUPS`);
- the single local user of the free desktop edition, without any setting.

Everyone else gets a message that the page is available to analysts and
administrators only. An analyst does not get the admin console
(``/admin``: license, connection, sessions) — the Cubes page lives in the
web application next to :doc:`reports`; the admin console opens it from its
header (**Cubes**, in a new tab). The sign-in is the one of the web
application (the server's OAuth page or the identity from an authenticating
front).

The cube list
-------------

The list on the left shows the cubes of the catalog (on a multi-database
server pass the database in the address, ``/cubes?database=dwh``) with a
status dot: green — the definition parses and the server builds the field
list (Excel will open the cube); red — a problem (the card explains it);
grey — not checked yet. The search box filters by name and description.

By default the list shows the cubes the user is allowed to open: a cube
whose role blocks (``--olap_user_groups``) do not include the user's groups
is hidden and counted in *N hidden by roles*. An administrator (and the free
edition's local user) can tick **Show all cubes** to see them with their
status.

With cube files in a folder (``CUBE_SOURCE=folder``) the status is computed
for every cube when the list loads — reading the folder is cheap, so the
list is always current. With cubes in the ``olap_definition`` table
(``CUBE_SOURCE=database``) every status needs a read from the warehouse, so
the list comes without statuses: a cube is checked when its card opens, and
**Check all** checks the whole list one cube after another.

**Reload cubes** re-reads the list and the open card after you saved a
definition. **Create cube** (the free edition) opens the cube wizard of the
admin console.

The cube card
-------------

The card on the right shows the cube's status with the number of errors and
warnings, and four tabs.

**Problems** — the findings of the definition checker (the same checks the
server runs when it loads the cube, see :tag:`definition_check_on`): errors
first, then warnings, each with the line number, the section and the
message. A parse error of the server itself (the text is not a cube, a role
block closes the cube to this user) is shown above the list with a hint of
what to do. Click a finding to jump to its line in **Definition**.

**Structure** — the cube as the server understood it for the current user:
the sources, the dimensions with their levels (SQL expression, column alias,
table), the measures (plus the number format), the calculated fields and
the role blocks with their groups, visibility settings and access
filters. The first column of every table is the line of the definition —
click it to jump to that line in **Definition**. What a user's roles hide is
not listed — the structure is per user, as in Excel.

**Preview** — a pivot table on this cube: the same field list, areas,
hierarchies and menus as in :doc:`reports`, so the analyst checks the
numbers the way the users will see them. The query runs as the analyst —
the cube's roles and access filters apply as usual. Under the table, **SQL
sent to the warehouse** shows the exact SQL of the last query, the time it
took and whether the result came from the SQL cache or from the warehouse
(**Update** above the table re-queries past the cache). The layout is not
saved — to keep it, build it on the Reports page.

**Definition** — the text of the cube, read-only, with line numbers; lines
with findings are highlighted (red for errors, yellow for warnings) and show
the message on hover. With cube files in a folder the file path and
modification time are shown above the text.

Settings
--------

:confval:`ANALYST_GROUPS` — who sees the page besides administrators. The
page is part of the web application and needs the ``web`` (or ``api``)
license feature in the server edition; the preview runs under the ``web``
flag like the pivot table itself. The endpoints behind the page are
described in :ref:`api_cubes_page`.
