# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'XLTable'
copyright = '2026, BR Systems'
author = 'BR Systems'
release = '2.0.11'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = []

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'alabaster'
html_static_path = ['_static']
html_logo = "_static/xllogo_icon.png"

html_theme_options = {
    'description': 'OLAP server connecting Excel Pivot Tables to modern analytical databases.',
    'github_user': '',
    'fixed_sidebar': True,
    'sidebar_collapse': False,
    'show_powered_by': False,
    'analytics_id': 'G-GCCZ18W88M',  
    'analytics_anonymize_ip': False,
}

html_sidebars = {
    '**': [
        'about.html',
        'navigation.html',
        'searchbox.html',
    ]
}
