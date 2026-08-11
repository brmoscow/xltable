.. _excel_export:

Working with large results: preview and file export
====================================================

A Pivot Table is designed for aggregated views, so XLTable caps the size of a
single pivot result (the :confval:`MAX_CELLS` setting, 100,000 cells by default —
the same way SSAS limits oversized results). When a layout is too detailed to
fit — for example, sales by store × product × day for three years — the server
does not return a truncated table silently. Instead Excel shows a message
suggesting two ways to work with the full result, both provided by the
service **Data Output** field (in the ``_Service`` folder of the field list).

------------------------------------------------------------

Preview mode
------------

Add **Data Output** to the **Filters** area and select
``Preview: first 1000 rows``. The pivot comes back to life immediately and
shows the first rows of the detailed result — the layout, filters and
expansions all stay editable, so you can shape the future export while looking
at real data. The preview shows plain data rows without totals: it is a
faithful sample of the file that will be exported. Selecting ``All rows``
returns the pivot to the normal aggregated mode.

------------------------------------------------------------

Full export to a CSV file
-------------------------

Right-click any cell of the Pivot Table and
choose **Additional Actions** → **Export full table to CSV**. The default
browser opens a status page; when the file is ready, the download starts
automatically. The export contains exactly what the pivot is configured to
show — same fields, same filters, same expansions (WYSIWYG) — but complete,
without the pivot size cap, and without subtotal rows, so the file can be
safely aggregated further. Column headers are the field captions from the
cube definition.

Details worth knowing:

- The export runs in the background on the server; the browser page refreshes
  itself and shows progress. The Excel session is not blocked — you can keep
  working while the file is being built.
- Results larger than an Excel sheet (1,048,576 rows) are delivered as a ZIP
  archive with the CSV inside — Excel would silently truncate a larger CSV
  opened directly; such files are meant for Power Query, a database, or
  analysis tools.
- Clicking the same export twice does not run the query twice: while the
  layout and its data are unchanged, the link leads to the already-built file
  (files are kept for 24 hours by default). Pressing **Refresh** in Excel and
  exporting again rebuilds the file with fresh data.
- The exported file is built with the access filters of the user who exports,
  same as the pivot itself.

------------------------------------------------------------

Enabling the feature
--------------------

The feature is enabled by the administrator (the ``EXPORT`` section in
``settings.json`` — see :ref:`export_settings`); without it the **Data
Output** field and the export menu item are not shown.

File export is currently supported for **ClickHouse** only — the data is
streamed into the file by the database connector, bypassing the server's
memory. On other databases leave the ``EXPORT`` section off: the menu
would appear, but the export itself would fail.
