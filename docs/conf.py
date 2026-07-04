# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'XLTable'
copyright = '2026, BR Systems, Astana, Kazakhstan'
author = 'BR Systems'
release = '2.0.15'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx_design',
    'sphinx_copybutton',
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
    'light_logo': 'xllogo_blue.png',
    'dark_logo': 'xllogo_blue.png',
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
