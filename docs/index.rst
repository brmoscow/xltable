.. XLTable documentation master file, created by
   sphinx-quickstart on Sun Jun  1 13:36:07 2025.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

XLTable documentation
=====================


#############
About XLTable
#############
XLTable - OLAP server for the new data stack. Allows you to work with ClickHouse, BigQuery, Snowflake from an Excel pivot table.

XLTable can be deployed in the cloud or inside your network perimeter on a Linux server. XLTAble receives requests from Excel via the XMLA protocol and returns data from the columnar database you use.

#############
License
#############
XLTable is a product of the company CloudReports. For questions about purchasing or testing, write to us by email help@cloudreports.kz.

#############
Install
#############
In the nearest future XLTable will be available as a ready-to-deploy virtual machine image in Yandex Сloud.

Below are instructions for self-installation for the Ubuntu operating system and ClickHouse. 

1. Prepare ubuntu server with minimum requirements: hard drive - 100 gb, ram - 16 gb.

2. Make sure that the Ubuntu server has access to the ClickHouse server on port 8443 and that the client machines with Excel have access to the Ubuntu server on port 80.

3. Installing Python, Supervisor, Nginx:

.. code-block::

$ sudo apt-get -y update
$ sudo apt-get -y install python3 python3-venv python3-dev
$ sudo apt-get -y install supervisor nginx git



.. toctree::
   :maxdepth: 2
   :caption: Contents: