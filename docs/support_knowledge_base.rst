Frequently Asked Questions
==========================

Quick navigation
----------------

- `What are the minimum system requirements and required ports? <#minimum-requirements-and-ports>`_
- `Installation on Ubuntu 22.04 fails with a GLIBC 2.38 dependency error. What should I do? <#glibc-238-on-ubuntu-2204>`_

.. _minimum-requirements-and-ports:

What are the minimum system requirements and required ports?
------------------------------------------------------------

Typical baseline requirements are Ubuntu 22.04 or 24.04, 2-8 vCPU, 16-32 GB RAM, and 50-100 GB disk. Network access usually includes XLTable -> ClickHouse (often port 8443) and Excel clients -> XLTable (ports 80/443). In restricted environments, access may be available only through VPN and HTTPS.

.. _glibc-238-on-ubuntu-2204:

Installation on Ubuntu 22.04 fails with a GLIBC 2.38 dependency error. What should I do?
-------------------------------------------------------------------------------------------

The standard build may have been compiled against a newer GNU C library. Recommended options are either upgrading to Ubuntu 24.04 or requesting a vendor build specifically prepared for Ubuntu 22.04 (including the corresponding installation or upgrade package).
