# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

import os

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'XLTable'
copyright = '2026, BR Systems LLP, Astana, Kazakhstan'
author = 'BR Systems LLP'
release = '2.1.6'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx_design',
    'sphinx_copybutton',
    'sphinx_llms_txt',
]

exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']


def setup(app):
    # Linkable entries for the two reference lists: every settings.json
    # parameter and every cube SQL tag gets a stable anchor
    # (settings.html#confval-MAX_CELLS, reference.html#tag-olap_measures)
    # and a cross-reference role usable anywhere in the docs
    # (:confval:`MAX_CELLS`, :tag:`olap_measures`).
    app.add_object_type('confval', 'confval',
                        objname='settings.json parameter',
                        indextemplate='pair: %s; settings.json parameter')
    app.add_object_type('tag', 'tag',
                        objname='SQL tag',
                        indextemplate='pair: %s; SQL tag')



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

# Offline build (XLTABLE_OFFLINE=1, see build_offline.py): a copy of the
# docs for a customer without internet access, opened from disk. Nothing
# is loaded from the network: no Google Fonts, no Google Analytics.
OFFLINE = os.environ.get('XLTABLE_OFFLINE') == '1'

html_theme = 'furo'
html_title = f'XLTable {release}'
html_static_path = ['_static']
html_css_files = [
    # IBM Plex Sans / Mono; with the fonts unreachable (a closed network)
    # the page falls back to the system fonts of the stack below.
    'https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500'
    '&family=IBM+Plex+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400'
    '&display=swap',
    'custom.css',
]
html_favicon = '_static/xllogo_icon.png'

# Google Analytics (gtag.js)
html_js_files = [
    ('https://www.googletagmanager.com/gtag/js?id=G-0F2P9FSN3D', {'async': 'async'}),
    'ga.js',
]

if OFFLINE:
    html_css_files = ['custom.css']
    html_js_files = []

# Brand color #0060b7 sampled from the XLTable logo. The table header band
# #dce6f1 is the header fill of an Excel pivot table: tables in the docs
# look like the product. The menu is set in the text colour, only the open
# page is coloured.
_font_sans = ('"IBM Plex Sans", -apple-system, BlinkMacSystemFont, '
              '"Segoe UI", Helvetica, Arial, sans-serif')
_font_mono = ('"IBM Plex Mono", "SFMono-Regular", Menlo, Consolas, '
              'Monaco, "Liberation Mono", monospace')

html_theme_options = {
    'light_logo': 'xllogo_light.png',
    'dark_logo': 'xllogo_white.png',
    'sidebar_hide_name': True,
    'light_css_variables': {
        'color-brand-primary': '#0060b7',
        'color-brand-content': '#0060b7',
        'font-stack': _font_sans,
        'font-stack--monospace': _font_mono,
        'color-table-header-background': '#dce6f1',
        'color-sidebar-caption-text': 'var(--color-foreground-primary)',
        'color-sidebar-link-text--top-level':
            'var(--color-foreground-secondary)',
        'color-sidebar-item-background--current': '#e3edf8',
    },
    'dark_css_variables': {
        'color-brand-primary': '#6cb0f0',
        'color-brand-content': '#6cb0f0',
        'color-table-header-background': '#1c2a3d',
        'color-sidebar-item-background--current': '#16263a',
    },
}

# sphinx-copybutton: strip shell/REPL prompts when copying code
copybutton_prompt_text = r'\$ |>>> |\.\.\. '
copybutton_prompt_is_regexp = True

# -- sphinx-llms-txt: llms.txt / llms-full.txt for AI assistants -------------
# https://sphinx-llms-txt.readthedocs.io — see docs/ai.rst for the user-facing page

# Read the Docs sets READTHEDOCS_CANONICAL_URL per version; fall back to
# stable for local builds so generated links are always absolute.
html_baseurl = os.environ.get(
    'READTHEDOCS_CANONICAL_URL',
    'https://xltable-olap.readthedocs.io/en/stable/',
)

llms_txt_title = 'XLTable'
llms_txt_summary = (
    'XLTable is an OLAP server that connects native Excel Pivot Tables '
    'directly to modern analytical databases (ClickHouse, BigQuery, '
    'Snowflake, Trino, Greenplum, StarRocks, Databricks, DuckDB) over '
    'XMLA. The same cubes are served to a pivot table in the browser, to '
    'AI assistants through a built-in MCP server and a REST API, and to BI '
    'tools through a PostgreSQL-compatible SQL endpoint. It provides a '
    'semantic and security layer: cubes with measures, dimensions, '
    'hierarchies and roles are defined in plain SQL with optional Jinja '
    'templating.'
)
