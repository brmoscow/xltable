.. _connection_setup:

Connection setup in the admin console
=====================================

The **Connection** page of the web admin console shows the warehouse
connection of the server (:confval:`SERVER_DB` and :confval:`CREDENTIAL_DB`
from ``settings.json``) and can test it against the live warehouse.

In the **free desktop edition** the tab is a full editor: pick the connector
type, fill in the form, press *Test connection* and save — the connection is
applied without a restart and ``settings.json`` never has to be edited by
hand. In the **server edition** the tab is read-only diagnostics: support can
see at a glance what the server is connected to and whether the warehouse
responds, but changing the connection stays with IT and the configuration
file (see `Server edition`_ below).

Opening the tab
---------------

Open the admin console in a browser and switch to **Connection**:

.. code-block:: text

   http://127.0.0.1:5000/admin

(replace ``5000`` with your ``SERVER_PORT``). In the free edition the admin
console has no password — it is reachable from this machine only. In the
server edition the page sits behind the usual admin authentication, see
:ref:`admin_panel`.

On the very first start of the free edition, while the connection is not
configured yet, the server console prints the direct hint::

   Warehouse connection is not configured yet — set it up at
   http://127.0.0.1:5000/admin (Connection tab)

The server and the admin console work fine before the warehouse is
configured — cube queries simply return a clear connection error until the
form is filled in.

The form
--------

The editable form (free edition) consists of:

- **Connector type** — a drop-down with the supported warehouse types
  (ClickHouse, BigQuery, Snowflake, Trino, Greenplum, StarRocks, DuckDB).
  Switching the type switches the set of fields below.
- **Connection fields** — the fields mirror the ``CREDENTIAL_DB`` keys of the
  selected connector (see :doc:`databases` for the reference of every type):
  host, port, user, password and TLS options for classic warehouses; the path
  to the service-account JSON file for BigQuery; the database file path for
  DuckDB. Sensible defaults (ports, TLS flags, query timeout) are pre-filled.
- **Test connection** — checks the values *currently entered in the form*,
  before anything is saved.
- **Save connection** — writes the connection to ``settings.json``.

Below the form the tab also shows the keys that are fixed at process startup
— the server port (``SERVER_PORT``) and the edition (``EDITION``). They are
shown for reference only: changing them requires editing ``settings.json``
and restarting the server, and the form never pretends otherwise.

Passwords are write-only
------------------------

Saved secrets (passwords, key passphrases) are **never sent to the browser**
— neither in the page HTML nor in any status response. The password field is
always empty with the placeholder *"saved — leave empty to keep it"*: an
empty field on save keeps the previously saved value, a non-empty one
replaces it. The same applies when testing: an empty password means "test
with the saved one".

Testing the connection
----------------------

*Test connection* opens a real connection to the warehouse and lists what it
sees. The result is a short, human answer instead of a stack trace:

- ``OK — found 12 table(s) in 3 database(s)`` — connected; where counting
  tables is not cheap the message falls back to the number of visible
  databases;
- ``Authentication failed — check the user and password``;
- ``Host is unreachable — check the host and port``;
- ``Database not found — check the database name / file path``.

The original error text is kept in parentheses for support. The check runs
with a short timeout — an unreachable host answers within seconds, not
minutes.

Saving (free edition)
---------------------

Saving touches **only** the ``SERVER_DB`` and ``CREDENTIAL_DB`` keys: the
rest of ``settings.json`` (users, limits, cache settings, custom keys) is
left exactly as it was. The file is written atomically, so the automatic
configuration reload never sees a half-written file.

The saved connection is applied within a few seconds without a restart. The
settings fingerprint changes, so the cache is cleared — metadata of the
previous warehouse does not survive the switch; the page says so after
saving. A running console command like ``main.exe autogen`` started after the
save sees the new warehouse immediately.

Server edition
--------------

In the server edition the tab shows the connection **read-only** (secrets are
masked) and offers *Test connection* against the saved configuration — a
quick way for support to tell a warehouse problem from a cube problem during
an incident.

Editing is intentionally not available:

- the connection is set up by IT at installation time and is not supposed to
  change from a browser — a web edit would bypass the change management of
  the warehouse credentials;
- in a cluster (several XLTable servers sharing a Redis cache behind a load
  balancer) ``settings.json`` must be identical on every node — a web form
  would edit one node and desynchronize the cluster.

To change the connection on the server edition, edit ``settings.json`` on the
server (every node), and the running service picks it up automatically — see
:ref:`applying_config` if unsure.
