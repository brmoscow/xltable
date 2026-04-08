Support Knowledge Base
======================

Question: How is an XLTable pilot usually organized?
Answer: A practical pilot flow is: the customer provides the target cube structure and source data, the customer deploys XLTable on their server, the XLTable team or integrator prepares and tunes ``olap_definition``, and business users validate results and performance in Excel.

Question: What are common infrastructure requirements and ports?
Answer: Typical pilot environments use Ubuntu 22.04 or 24.04 with 2-8 vCPU, 16-32 GB RAM, and 50-100 GB disk. Network paths usually include XLTable to ClickHouse (often port 8443), and Excel clients to XLTable over 80 or 443, often through VPN and HTTPS.

Question: What should I do if installation package download or install fails?
Answer: If a corporate network blocks the storage link, deliver the archive through an alternative channel. If you see GLIBC compatibility issues, use a build matching your OS version. Prefer the documented standard deployment path.

Question: Why does XLTable ask for a license after deployment?
Answer: Obtain the ``server_id`` from the admin panel, send it to the XLTable team, then upload the generated ``.lic`` file in the admin interface. A new server or environment typically requires a new license file.

Question: Why does Excel show XML parsing or connection errors?
Answer: In many cases Excel receives an HTML error page instead of XMLA. Verify the full server URL with protocol, check reverse proxy settings, verify authentication, and inspect XLTable logs after reproducing the issue.

Question: What settings mistakes most often break startup?
Answer: The most frequent causes are incomplete ``settings.json`` and incorrect TLS configuration for database connectivity. Keep all required keys from the template and verify secure connection settings end-to-end.

Question: Why can the same logic be fast on a table but slow on a view?
Answer: Very wide views and heavy transformations often degrade performance. For critical scenarios, reduce selected columns, use a narrower prepared layer, and consider switching to an optimized table or view dedicated to analytics.

Question: Why can XLTable and BI tools show different row counts?
Answer: Results can differ because totals and subtotals may be generated with additional grouping logic. For fair comparison, align grouping depth, subtotal behavior, filters, and metric definitions before validating numbers.

Question: Why do totals look incorrect for some business metrics?
Answer: Many metric discrepancies come from aggregation methodology, not from arithmetic bugs. For example, some metrics should be averaged rather than summed, and stock metrics often represent end-of-period snapshots instead of sum of daily values.

Question: Why does filtering by name fail while filtering by code works?
Answer: A common root cause is special characters in labels (for example, square brackets) that can affect filter behavior in some scenarios. Validate source values and test with normalized names if filtering is inconsistent.

Question: Where should complex business logic live: ClickHouse objects or cube definition?
Answer: Both approaches are valid. For fast pilot iterations, logic in ``olap_definition`` can be convenient. For stable production workloads, frequently reused heavy transformations are usually better materialized in ClickHouse.

Question: What is a practical first checklist for support diagnostics?
Answer: Confirm service status, verify URL and HTTPS path, enable ``WRITE_LOG``, reproduce the issue, inspect generated SQL and errors, verify database credentials and permissions, and validate reverse proxy behavior before deeper tuning.
