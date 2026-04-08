Frequently Asked Questions
==========================

Quick navigation
----------------

- `How is an XLTable pilot usually organized? <#pilot-flow>`_
- `What are common infrastructure requirements and ports? <#infrastructure-and-ports>`_

.. _pilot-flow:

How is an XLTable pilot usually organized?
-------------------------------------------

A practical pilot flow is: the customer provides the target cube structure and source data, the customer deploys XLTable on their server, the XLTable team or integrator prepares and tunes ``olap_definition``, and business users validate results and performance in Excel.

.. _infrastructure-and-ports:

What are common infrastructure requirements and ports?
------------------------------------------------------

Typical pilot environments use Ubuntu 22.04 or 24.04 with 2-8 vCPU, 16-32 GB RAM, and 50-100 GB disk. Network paths usually include XLTable to ClickHouse (often port 8443), and Excel clients to XLTable over 80 or 443, often through VPN and HTTPS.
