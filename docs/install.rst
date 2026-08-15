
Installation
============

This section describes how to install XLTable, obtain a license and
configure system access. Connections to analytical databases are
described on the :doc:`databases` page.

XLTable can be deployed on Linux, Windows 10 / 11 or Windows Server
and supports integration with Active Directory and multiple databases.

------------------------------------------------------------

.. _install_ubuntu:

Linux
-----

XLTable can be installed on modern Linux distributions.
Ubuntu 22.04+ is recommended for production environments.

Prerequisites
^^^^^^^^^^^^^

- Ubuntu 22.04+ server with ``sudo`` access
- Network access to analytical databases
- Open ports 80 or 443 for Excel clients
- XLTable distribution zip placed in ``/usr/olap/`` (e.g. ``xltable-2.0.20-ubuntu.zip``)

Prepare system
^^^^^^^^^^^^^^

Create working directory:

.. code-block:: bash

   sudo mkdir /usr/olap
   sudo chmod a+rwx /usr/olap

Install XLTable
^^^^^^^^^^^^^^^

Copy the XLTable distribution zip and the installer to the server:

.. code-block:: bash

   scp xltable-*-ubuntu.zip install_ubuntu.zip user@server:/usr/olap/

Unpack the installer scripts and run the install script:

.. code-block:: bash

   cd /usr/olap
   unzip -o install_ubuntu.zip
   bash install_xltable.sh

The script will:

- Install ``supervisor``, ``nginx``, ``unzip``
- Extract xltable to ``/usr/olap/xltable/``
- Create ``/usr/olap/xltable/setting/settings.json`` from the example (if missing)
- Configure supervisor to autostart several xltable worker processes
  (one per CPU core, up to 4 by default)
- Configure nginx on port 80 as a load balancer across the worker
  processes (ports 5000, 5001, ...)

.. note::

   Several worker processes are what lets heavy reports from many concurrent
   users be built in parallel: Python limits one process to one CPU core for
   result building, so the instance count is effectively the number of large
   reports the server can render at the same time. All instances share the
   same cache and ``settings.json``. To change the count, re-run the installer
   with the desired number — the existing configuration and settings are kept:

   .. code-block:: bash

      XLTABLE_INSTANCES=6 bash install_xltable.sh

Set up connections with database (configuration examples in the folder ``/usr/olap/xltable/setting``):

.. code-block:: bash

   nano /usr/olap/xltable/setting/settings.json

Example of a minimal settings.json:

.. code-block:: json

  {
    "SERVER_DB": "ClickHouse",
    "CREDENTIAL_DB": {
        "user": "..",
        "password": "..",
        "host": "..",
        "port": "8443",
        "secure": true,
        "verify": true,
        "query_timeout": 60
    },
    "WRITE_LOG": false,
    "MAX_CELLS": 100000,
    "OVERLOAD_GUARD": {
        "MAX_MEMORY_PERCENT": 90,
        "MAX_CPU_PERCENT": 95,
        "MIN_FREE_DISK_MB": 512
    },
    "CONVERT_FIELDS_TO_STRING": true,
    "USERS": {"user1": "pass1", "user2": "pass2"},
    "USER_GROUPS": {"user1": ["olap_users", "olap_admins"], "user2": ["olap_users"]},
    "ADMIN_GROUPS": ["olap_admins"]
  }

.. note::

   Changes to ``settings.json`` are picked up automatically within a few
   seconds of saving — no service restart is required (see
   :ref:`settings_schema`).


Upgrading version
^^^^^^^^^^^^^^^^^

Copy the new distribution zip to the server (remove or replace any previous zip first):

.. code-block:: bash

   scp xltable-*-ubuntu.zip user@server:/usr/olap/

Run the update script:

.. code-block:: bash

   cd /usr/olap
   bash update_xltable.sh

The script will:

- Verify the zip integrity
- Back up ``settings.json``, the ``.lic`` license file and the local cubes
  folder (:confval:`CUBES_FOLDER`, default ``cubes/``) to
  ``/usr/olap/backup_<timestamp>/``
- Stop the service and replace the xltable installation
- Restore the backed-up config, license files and local cubes
- Set file ownership to the service user from the supervisor config
- Restart the service and show its status

The backup folder is kept after the update — remove it once you have
confirmed the new version works.

.. _service_management:

Service Management
^^^^^^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 20 50

   * - Action
     - Command
   * - Start
     - ``sudo supervisorctl start 'olap:*'``
   * - Stop
     - ``sudo supervisorctl stop 'olap:*'``
   * - Restart
     - ``sudo supervisorctl restart 'olap:*'``
   * - Status
     - ``sudo supervisorctl status 'olap:*'``
   * - Logs
     - ``sudo tail -f /var/log/supervisor/olap*.log``

``olap:*`` addresses every worker process of the service; it also works on
installations that still run the old single-process configuration.

------------------------------------------------------------

.. _install_windows_desktop:

Windows 10 / 11
---------------

On Windows 10 / 11 XLTable runs as a standalone executable — no additional
components are required. This is the fastest way to get started
(see also :doc:`quickstart`); for production deployments on Windows Server
with IIS, see :ref:`install_windows`.

Installation
^^^^^^^^^^^^

1. Download the distribution archive and extract it to a folder of your
   choice, e.g. ``C:\xltable\``

   .. note::

      Pick a folder you can write to — ``settings.json``, the cache and the
      logs live next to ``XLTable.exe``. If the folder is read-only (for
      example, ``C:\Program Files\`` without administrator rights), the
      server reports the problem at startup and suggests moving to a folder
      in your user profile instead of failing silently.

2. Start the server by double-clicking ``XLTable.exe`` (or from the command line):

   .. code-block:: text

      C:\xltable\XLTable.exe

3. The distribution runs as the **free desktop edition** out of the box: on
   an interactive first start the browser opens the **Quick start**
   checklist of the admin console (``http://127.0.0.1:5000/admin``, see
   :ref:`start_page`), and the warehouse connection is configured right
   there on the **Warehouse connection** page — ``settings.json`` does not
   have to be edited by hand (see :ref:`database_connections` and
   :ref:`settings_schema` for the file reference)

4. In Excel, connect to the server at ``http://127.0.0.1:5000``
   (prefer ``127.0.0.1`` over ``localhost`` — see the note in
   :doc:`excel`)

To run the **server edition** standalone instead, set
``"EDITION": "server"`` in ``settings.json`` (see :confval:`EDITION`),
configure the users, restart, then open the admin panel and activate the
license (see :ref:`obtaining_license`).

.. note::

   The desktop installation is meant for one person on one machine: the
   free edition listens on ``127.0.0.1`` only and rejects network requests
   by design. For a multi-user server that Excel users reach over the
   network, use a production installation — :ref:`install_ubuntu` or
   :ref:`install_windows` (Windows Server with IIS).

Autostart
^^^^^^^^^

To start the server automatically at logon, put a shortcut to ``XLTable.exe``
into the Startup folder: press :kbd:`Win+R`, type ``shell:startup``, and copy
the shortcut there. For unattended servers, use Task Scheduler
(trigger **At startup**, action — run ``C:\xltable\XLTable.exe``).

Update
^^^^^^

1. Stop ``XLTable.exe`` (close the window or end the process in Task Manager)
2. Back up ``settings.json`` and the license file ``.lic``
3. Extract the new distribution archive into ``C:\xltable\``, overwriting existing files
4. Restore the backed-up ``settings.json`` and ``.lic``
5. Start ``XLTable.exe``

.. note::

   Upgrading from a release before 2.0.20: the executable was renamed from
   ``main.exe`` to ``XLTable.exe``. Delete the old ``main.exe`` left after
   step 3, and re-point anything that referenced it — a Startup shortcut,
   a Task Scheduler action, a batch file, or the Claude Desktop extension
   (**Settings → Extensions → XLTable OLAP → Configure**).

------------------------------------------------------------

.. _install_windows:

Windows Server (IIS)
--------------------

XLTable can be installed on Windows Server 2019+ behind IIS.
For a quick setup without IIS, the standalone installation described in
:ref:`install_windows_desktop` also works on Windows Server.

Prerequisites
^^^^^^^^^^^^^

**IIS Roles and Features** (Server Manager → Add Roles and Features):

- Role: **Web Server (IIS)**
- Under **Web Server → Application Development**: enable **CGI** (also enables FastCGI)
- Under **Web Server → Security**: enable **Windows Authentication** and **Basic Authentication**

- Network access to analytical databases
- Open ports 80 or 443 for Excel clients

Installation
^^^^^^^^^^^^

**1. Install Python 3.12.6**

Download and install Python 3.12.6 for Windows (64-bit). During installation, check **"Add Python to PATH"**.

**2. Create the application folder**

.. code-block:: bash

   mkdir C:\olap

**3. Extract the distribution archive**

Copy the distribution archive into ``C:\olap``, then extract it:

.. code-block:: bash

   cd C:\olap
   tar -xf xltable-<version>-windows_server.zip

The application folder will be at ``C:\olap\xltable\``.

**4. Create a virtual environment**

.. code-block:: bash

   cd C:\olap\xltable
   python -m venv .venv

**5. Install dependencies**

.. code-block:: bash

   C:\olap\xltable\.venv\Scripts\pip install -r requirements.txt

**6. Configure settings**

Edit the configuration file ``C:\olap\xltable\setting\settings.json`` and fill in all required fields (database connections, users, etc.). The license file is not referenced from the configuration — upload it via the admin panel and it is stored as ``xltable.lic`` next to the server code.

**7. Configure IIS with web.config**

Use the file ``C:\olap\xltable\web.config``. It configures FastCGI to run the application via the virtual environment Python interpreter.

Authentication is set to **Windows Authentication** and **Basic Authentication** (anonymous access disabled).

**8. Register the FastCGI application in IIS**

Open **IIS Manager → server node → FastCGI Settings → Add Application**:

- **Full Path:** ``C:\olap\xltable\.venv\Scripts\python.exe``
- **Arguments:** ``C:\olap\xltable\.venv\Lib\site-packages\wfastcgi.py``

**9. Point the IIS site to the application**

In **IIS Manager → Sites**, select **Default Web Site** (or create a dedicated site):

- **Basic Settings → Physical Path:** ``C:\olap\xltable``
- **Authentication:** disable **Anonymous Authentication**, enable **Windows Authentication** and **Basic Authentication** (matches the ``web.config`` from step 7)
- Restart the site

**10. Verify**

Open the admin panel in a browser at ``http://127.0.0.1/admin``.

In Excel, connect to the server at ``http://<server-name>/``.

Update
^^^^^^

1. Stop the IIS application pool (IIS Manager → Application Pools → Stop)
2. Back up ``settings.json`` and the license file ``.lic``
3. Extract the new distribution archive into ``C:\olap\xltable\``, overwriting existing files
4. Restore the backed-up ``settings.json`` and ``.lic``
5. Update dependencies (skip if ``requirements.txt`` did not change):

   .. code-block:: bash

      C:\olap\xltable\.venv\Scripts\pip install -r C:\olap\xltable\requirements.txt

6. Start the application pool

------------------------------------------------------------

.. _obtaining_license:

Obtaining a license
-------------------

XLTable requires a license file (``.lic``) to serve requests. A trial
license is issued free of charge:

1. Install and start XLTable, then open the admin panel at
   ``http://<server>/admin`` (see :ref:`admin_panel`) and go to the
   **License** tab.
2. Copy the **server id** shown there.
3. Send it to help@xltable.com or Telegram https://t.me/XLTable — we will
   issue you a trial license.
4. Upload the received ``.lic`` file using the form on the **License** tab.

The **License** tab also shows the current license details and, for licenses
limited by named users, the occupied seats. Licensing is per **named user** —
see :doc:`faq` for how seats are counted and released.

When upgrading XLTable, keep the ``.lic`` file together with
``settings.json`` — both are backed up and restored by the update procedure.

------------------------------------------------------------

Authentication
--------------

XLTable supports two authorization modes: local authentication
defined in ``settings.json`` and integration with Active Directory(LDAP).

Local authorization
^^^^^^^^^^^^^^^^^^^

At the basic level, authorization is configured directly
in the ``settings.json`` file.

Administrators can define:

- Users and passwords
- User groups
- Mapping of users to groups

This mode is suitable for:
- test environments
- small installations
- isolated deployments without domain infrastructure

Example structure:

.. code-block:: json

   "USERS": {"user1": "pass1", "user2": "pass2"},
   "USER_GROUPS": {"user1": ["olap_users", "olap_admins"], "user2": ["olap_users"]},
   "ADMIN_GROUPS": ["olap_admins"],

Active Directory integration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

XLTable supports authentication and authorization
using Microsoft Active Directory.

Active Directory integration allows you to:
- Authenticate users automatically
- Map AD users and groups to XLTable roles
- Centralize access management

To enable Active Directory authentication, configure the corresponding
section in the ``settings.json`` file.

This section defines connection parameters to the domain controller, account for looking up user information, group mapping rules and other LDAP parameters.

Example structure:

.. code-block:: json

    "CREDENTIAL_ACTIVE_DIRECTORY": {
        "server_address": "dc.company.org",
        "domain_full": "company.org",
        "username": "service_olap",
        "password": "...",
        "access_groups": ["olap_users_all", "olap_users_sales", "olap_users_accounting"]
    }

------------------------------------------------------------

.. _admin_panel:

Admin panel
-----------

XLTable includes a built-in admin panel for monitoring and managing the server.

URL
^^^

The admin panel is available at:

.. code-block:: text

   http://<server>/admin

Access is granted to users who belong to a group listed in ``ADMIN_GROUPS``.

Configure admin access
^^^^^^^^^^^^^^^^^^^^^^

Add the ``ADMIN_GROUPS`` section to ``settings.json``:

.. code-block:: json

   "ADMIN_GROUPS": ["olap_admins"]

To access the admin panel, log in as a user whose group is listed in ``ADMIN_GROUPS``.
For local users, the group is assigned via ``USER_GROUPS``; for AD users — via Active Directory group membership.

Features
^^^^^^^^

The admin panel is organized as a left-side menu of sections, each section
holding one or more pages. The menu skeleton is the same in both editions:

- **Quick start** — a standalone menu item above the sections, *free
  desktop edition only*: the onboarding checklist, see :ref:`start_page`;
- **Connection**: Warehouse connection (see :doc:`connection`; read-only
  with a **Test connection** button on the server edition, editable in the
  free desktop edition);
- **Cubes**: Cubes, Create cube — *free desktop edition only*, the section
  is absent on the server edition;
- **Administration**: Server status, License, Seats (*server edition
  only*), Cache;
- **Help**: Resources, plus Get the server edition (*free desktop edition
  only* — what the server edition adds and how to get it; the cube files
  created in the free edition work on the server unchanged).

Every page header carries a **Docs ↗** link that opens the section of this
documentation describing that page.

The open page is addressable: the URL hash selects a page (for example,
``/admin#cache`` opens the Cache page), and the page you were on is restored
after a browser reload.

The pages:

- **Server status** — confirms the server is running, shows the active
  database backend, the active cache backend (``sqlite`` — cache local to
  this machine, or ``redis`` with the server address — cache shared by the
  whole cluster; the actual mode after a possible fallback, see
  :doc:`cache`) and the settings file in use with the time it was last
  loaded (``settings.json`` is re-read automatically when it changes, see
  :ref:`settings_schema`).
- **License** — current license details, the server ID to send to the vendor
  when requesting a license, and the license file upload form. In the free
  desktop edition the page simply notes that no license file is required.
- **Seats** (*server edition only*) — the registry of **named user seats**
  when the license limits the number of named users: which users occupy the
  licensed seats, when each was first and last seen, and a **Release**
  button per seat. Licensing is per *named* user — a seat is taken on the
  first request of a user (whichever interface it comes through — Excel/XMLA
  or MCP) and is not freed by signing out or clearing the cache; it is
  released automatically after a period of inactivity defined by the license
  (30 days by default) or manually with the **Release** button (which also
  signs that user out). When all seats are taken, a new user gets a clear
  "Named user limit reached" message in Excel.
- **Cache** — cache overview and management (how the cache is organized is
  described in :doc:`cache`):

  - a per-user table showing active sessions, the number of cached entries
    and the time of the last activity, with a **Sign out** button that drops
    the sessions of a single user without affecting the others;
  - statistics of the shared SQL result cache (entries, size, hit rate).
    Hit/miss counters accumulate since the last reset — they survive restarts
    and cache clearing; the **Reset stats** button starts counting from zero,
    without touching the cached entries;
  - **Clear Metadata Cache** — removes cached cube definitions, schema lists
    and query results while keeping users signed in. Use it after editing a
    cube so the new definition is picked up immediately (it is also picked up
    automatically within :confval:`METADATA_CACHE_TTL`);
  - **Clear All Cache** — removes all cached session data. Users will need to
    re-authenticate after the cache is cleared.
  - when file export is enabled (:confval:`EXPORT`), an **Exports** block
    with the current jobs, files and their total size, and a **Clear Export
    Jobs and Files** button (see :ref:`export_settings`).
- **Resources** — direct links to the XLTable documentation and support.

In the **free desktop edition** the admin console is the analyst's main
workspace, and the menu additionally shows the **Cubes** section with two
pages: **Cubes** (the live list of cube files in the cubes folder, with the
parse status of each) and **Create cube** (a web wizard that generates a
cube from one warehouse table) — see :ref:`cube_autogen`. The menu starts
with the standalone **Quick start** item — the onboarding checklist
described in :ref:`start_page` — and the Help section additionally offers
**Get the server edition**. Everything else, including the License and
Cache pages, is the same as described above.

------------------------------------------------------------

.. _start_page:

Quick start page and first launch (free desktop edition)
--------------------------------------------------------

The free desktop edition guides the first launch end to end: run
``XLTable.exe`` → the browser opens on the **Quick start** page of the admin
console → four steps later a PivotTable and an AI agent are looking at
your data.

**Automatic browser launch.** ``XLTable.exe`` always starts the server. When
the cubes folder is empty (a fresh install) *and* the console is
interactive (the exe was started by a person, not by a scheduler or a
service), the browser opens on the Quick start page automatically after the
server is up. A non-interactive start never opens anything — the link to
the Quick start page is printed to the console/log in every case, together
with the admin console address and the Excel connection breadcrumb.
The cubes folder itself is created automatically at startup when it does
not exist yet.

**Repeated launch.** Starting ``XLTable.exe`` while the server is already
running does not fail with a "port is busy" error: the second window
detects the running server, opens the admin console in the browser
(interactive start only) and quietly exits — instantly, before any heavy
startup work. If the port is occupied by another program — 5000 is a
popular development port — the console prints a clear message with the
port number and the path to ``settings.json`` where to change
``SERVER_PORT``. An older XLTable (``main.exe`` from a release before
2.0.20) still running on the port is reported as another program — close
its window instead of changing the port.

**The Quick start page** is the default landing page of the admin console
until the onboarding is complete; after all four steps are done the console
opens on the **Cubes** page and Quick start stays in the menu as a
reference. While the onboarding is in progress, the pages involved in the
steps (Warehouse connection, the Create cube wizard) show a link back to
Quick start, so it is easy to return to the plan after finishing a step.
It is a checklist of four steps, and the status of every step is derived
from real system facts — there is nothing to tick manually:

1. **Connect your warehouse** — green once the credentials are set and a
   connection to the warehouse has actually succeeded (a successful *Test
   connection* on the Warehouse connection page, or any successful warehouse
   query); otherwise the page offers a button to the **Warehouse
   connection** page.
2. **Create your first cube** — green once the cubes folder contains at
   least one valid ``.sql`` cube (parsed by the same parser that serves
   Excel); otherwise a button leads to the **Create cube** wizard.
3. **Connect Excel** — green after the first request from Excel reaches the
   server. Until then the page shows the exact breadcrumb: **Data → Get
   Data → From Database → From Analysis Services**, server name
   ``http://127.0.0.1:<port>``, no login needed. Excel talks to the server
   through the MSOLAP provider, which normally ships with Office; if Excel
   cannot find Analysis Services, see :doc:`excel`.
4. **Connect an AI agent** — green after the first agent request reaches
   the built-in MCP endpoint, whichever client it comes from. The page
   offers a choice of clients with ready-to-copy configs: **Claude
   Desktop** (the recommended one-click ``xltable.mcpb`` extension shipped
   next to ``XLTable.exe``), **Copilot in VS Code**, **Claude Code**, a
   **local model** in LM Studio (zero egress — nothing leaves the machine),
   or any other MCP client with a universal JSON config (see
   :ref:`mcp_clients`).

The statuses update live while the page is open. The completed checkmarks
of steps 3–4 are stored in the server cache and survive restarts and
``settings.json`` changes (saving the connection is itself an onboarding
step and does not reset the checklist); the only operation that resets
them is **Clear All Cache** on the Cache page (steps 1–2 are then
recomputed from the configuration and the cubes folder).

------------------------------------------------------------

Database connections
--------------------

XLTable connects directly to analytical databases and executes SQL queries
on their side. All connections are defined centrally in the ``settings.json``
file and reused across OLAP cubes — configuration examples for every
supported database are collected on the :doc:`databases` page.

------------------------------------------------------------

.. _install_multi_server:

Scaling to multiple servers (Redis cache)
-----------------------------------------

A single XLTable machine already runs several worker processes behind nginx
(see :ref:`install_ubuntu`). When one machine is not enough, run XLTable on
several servers and let them share one cache through Redis: set
``CACHE_BACKEND`` to ``redis`` in ``settings.json`` on every server.

.. code-block:: json

    "CACHE_BACKEND": "redis",
    "REDIS_URL": "redis://:yourpassword@redis-host:6379/0"  

With a shared cache every server can handle every request, so a load
balancer in front of the servers needs no sticky sessions — plain
round-robin works:

.. code-block:: nginx

   upstream xltable {
       least_conn;
       server 10.0.0.11:80;
       server 10.0.0.12:80;
   }

   server {
       listen 80;
       client_max_body_size 16m;
       location / {
           proxy_pass http://xltable;
           proxy_read_timeout 600s;   # heavy reports may run for minutes
           proxy_set_header Authorization $http_authorization;
       }
   }

What the shared cache gives you:

- a session opened through one server is valid on all of them — Excel
  refreshes keep working no matter where the balancer sends them;
- **Cancel** works across servers: a query started on one server can be
  cancelled by a request that lands on another (except Databricks and
  embedded DuckDB, where the query is interrupted in-process and the Cancel
  request must reach the server process running the query);
- the licensed named-user seats are counted across all servers, not per
  server — the seat registry is shared by the whole cluster;
- **Clear All Cache** / **Clear Metadata Cache** in the admin panel of any
  server take effect for the whole cluster.

.. warning::

   - ``settings.json`` must be **identical on all servers**. Every server
     checks a fingerprint of its configuration against the shared cache and
     clears the cache on mismatch — servers with different configurations
     would keep wiping the cache for each other. Deploy configuration
     changes to all servers together.
   - The Redis instance must **not be reachable by anyone but the XLTable
     servers**: protect it with a password (``requirepass`` /  ACL), keep it
     on a private network. Cached entries carry session authorization state,
     and anyone able to write to this Redis can effectively execute code on
     the XLTable servers.

When ``CACHE_BACKEND`` is not set (or set to ``sqlite``), XLTable keeps the
default single-machine cache shared by the worker processes of that machine.
If the ``redis`` backend is misconfigured (missing ``REDIS_URL``), the
server logs an error and falls back to the SQLite cache instead of failing
to start.

