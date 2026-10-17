Web pivot table
===============

The web pivot table is the third way to work with XLTable cubes, next to
Excel and AI assistants: the same cubes as a pivot table in the browser, with
reports saved on the server and shared by link. Nothing is installed on the
user's machine, so it also serves macOS users and anyone without Excel at
hand. The page is built to look and
behave like the Excel pivot table, so Excel users need no training: the field
list on the right, the four areas (Filters, Columns, Rows, Values) with drag
and drop, the compact layout, subtotals, hierarchies with ⊞/⊟, report filters
with a member tree, "Σ Values" on rows or columns, "Defer Layout Update" and
"Update". The engine, roles, row-level security and SQL cache are shared with
Excel: the SQL behind a layout is exactly the SQL Excel sends for the same
layout, so both show the same numbers and share the cache.

------------------------------------------------------------

Opening the page
----------------

Open ``http://your_server:5000/reports`` (the port of the XLTable server, see
:doc:`install`). The page signs the user in through the server's own OAuth
page (the same account as in Excel: a local account or Active Directory);
behind an authenticating front (Kerberos, a trusted proxy) the identity is
taken from it and no sign-in page appears. The free edition opens the page
without a sign-in.

The start page lists the user's own saved reports (an administrator sees
everyone's); **New pivot** picks the database (on a multi-database server) and
the cube and opens the builder.

The browsers: Chrome, Edge and Yandex Browser 80+, Firefox ESR.

Building a pivot
----------------

Everything works as in Excel:

- tick a field in the list or drag it into an area; measures go to Values,
  dimension levels to Rows, Columns or Filters; a hierarchy (such as Dates:
  year, quarter, month, day) is one field and is added as a whole; drag a
  field out of the areas (onto the table or the field list) to remove it,
  or use **Remove field** in the field's ▾ menu;
- ⊞/⊟ next to a member expands and collapses it; a plain field gets ⊟ when
  another plain field follows it;
- **Row Labels ▾** and **Column Labels ▾** open the Excel menu: sort A to Z,
  sort by a measure, search, member check boxes;
- a report filter cell above the table opens a tree of members with
  "Select Multiple Items" semantics: check a year to take it whole, uncheck a
  quarter under it, search across all levels;
- with two or more measures the **Σ Values** field can be moved between
  Columns and Rows;
- **Subtotals** and **Grand Totals** switches, **Defer Layout Update** with
  **Update**, and **Update** above the table to re-query the warehouse past
  the cache (as Excel's Refresh).

The table does not aggregate anything in the browser: every change is one
query to the engine with totals included. A pivot larger than
:confval:`MAX_CELLS` is refused with a message, as Excel refuses an
oversized report — narrow a filter or collapse a level.

Saving and sharing
------------------

**Save** in the builder stores the report under the title you typed in the
header (an empty title is refused: the field turns red); the address of the saved report
(``/reports/<id>``) is the link to share. The report filters chosen by the
viewer travel in the link (``?f.Region=North``), so a link can point at a
specific slice. Any signed-in user may open a report by its link and see it
with their own data access; the owner or an administrator
(:confval:`ADMIN_GROUPS`) edits and deletes a report, anyone else may
**Save as** a copy under their own name. Reports are JSON documents in :confval:`REPORTS_FOLDER` and
are also available through :doc:`the API <api>` for scripts and AI agents.

The start page lists the reports; the **⋯** menu of a row opens the report,
opens it for editing (the owner or an administrator), copies its link, saves
a copy under a new name or deletes it. On a report page the **Reports ›**
crumb next to the title leads back to the list; **Edit**, **Download
xlsx** and **Copy link** are buttons, **Save as** and **Delete** sit in the
same **⋯** menu.

**Download xlsx** writes the table as shown — the header, indented row
labels, totals and number formats — into an Excel workbook; Excel for Mac
opens it as a regular sheet.

Licensing and settings
----------------------

The web pivot table is a feature of the server edition under its own license
flag (``web``, shown as *Web reports* on the License page of the admin
console); seats are shared with Excel per named user — a viewer opening a
report by link takes a seat as an Excel user does. Settings:
:confval:`REPORTS_FOLDER` (where reports are stored), :confval:`MAX_CELLS`
(the size limit). The admin console opens the page from its header
(**Reports**, in a new tab) and shows the reports folder and the number of
saved reports.
