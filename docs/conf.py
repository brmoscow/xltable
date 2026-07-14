# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

import os

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'XLTable'
copyright = '2026, BR Systems, Astana, Kazakhstan'
author = 'BR Systems'
release = '2.0.16'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx_design',
    'sphinx_copybutton',
    'sphinx_llms_txt',
]

exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'furo'
html_title = f'XLTable {release}'
html_static_path = ['_static']
html_css_files = ['custom.css']
html_favicon = '_static/xllogo_icon.png'

# Google Analytics (gtag.js)
html_js_files = [
    ('https://www.googletagmanager.com/gtag/js?id=G-0F2P9FSN3D', {'async': 'async'}),
    'ga.js',
]

# Brand color #0060b7 sampled from the XLTable logo
html_theme_options = {
    'light_logo': 'xllogo_light.png',
    'dark_logo': 'xllogo_white.png',
    'sidebar_hide_name': True,
    'light_css_variables': {
        'color-brand-primary': '#0060b7',
        'color-brand-content': '#0060b7',
    },
    'dark_css_variables': {
        'color-brand-primary': '#6cb0f0',
        'color-brand-content': '#6cb0f0',
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
    'Snowflake, Trino, Greenplum, StarRocks, Databricks) over XMLA. '
    'It provides a semantic and security layer: cubes with measures, '
    'dimensions, hierarchies and roles are defined in plain SQL with '
    'optional Jinja templating.'
)
