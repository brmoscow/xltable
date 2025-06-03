.. XLTable documentation master file, created by
   sphinx-quickstart on Sun Jun  1 13:36:07 2025.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

XLTable documentation
=====================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   self


#############
About XLTable
#############
XLTable - OLAP server for the new data stack. Allows you to work with ClickHouse, BigQuery, Snowflake from an Excel pivot table.

XLTable can be deployed in the cloud or inside your network perimeter on a Linux server. XLTAble receives requests from Excel via the XMLA protocol and returns data from the columnar database you use.

#############
License
#############
XLTable is a product of the company CloudReports. For purchasing or testing, write to us by email help@cloudreports.kz.

#############
Install
#############
In the nearest future XLTable will be available as a ready-to-deploy virtual machine image in Yandex Сloud.

Below are instructions for self-installation for the Ubuntu operating system and ClickHouse. 

Prepare Ubuntu server with minimum requirements: hard drive - 100 gb, ram - 16 gb.

Make sure that the Ubuntu server has access to the ClickHouse server on port 8443 and that the client machines with Excel have access to the Ubuntu server on port 80.

Installing Python, Supervisor, Nginx:

.. code-block:: bash

   $ sudo apt-get -y update
   $ sudo apt-get -y install python3 python3-venv python3-dev
   $ sudo apt-get -y install supervisor nginx git

Create olap folder:

.. code-block:: bash

   $ sudo mkdir /usr/olap
   $ sudo chmod a+rwx /usr/olap 

Copy XLTable distribution files to the olap folder. Example of copying from Windows:

.. code-block:: bash

   scp -r c:\win_local_folder\* user@server_ip:/usr/olap

Creating a Python environment and installing the required Python packages:

.. code-block:: bash

   cd /usr/olap
   $ python3 -m venv venv
   $ source venv/bin/activate
   (venv) $ pip install -r requirements.txt
   (venv) $ pip install gunicorn

Installing Yandex certificates:

.. code-block:: bash

   $ sudo mkdir --parents /usr/local/share/ca-certificates/Yandex/ && \
   $ sudo wget "https://storage.yandexcloud.net/cloud-certs/RootCA.pem" \
      --output-document /usr/local/share/ca-certificates/Yandex/RootCA.crt && \
   $ sudo wget "https://storage.yandexcloud.net/cloud-certs/IntermediateCA.pem" \
      --output-document /usr/local/share/ca-certificates/Yandex/IntermediateCA.crt && \
   $ sudo chmod 655 \
      /usr/local/share/ca-certificates/Yandex/RootCA.crt \
      /usr/local/share/ca-certificates/Yandex/IntermediateCA.crt && \
   $ sudo update-ca-certificates

Set up connections with ClickHouse:

.. code-block:: bash
   $ cd /usr/olap/setting
   $ nano settings.json

Add supervisor configuration:

.. code-block:: bash
   $ cd /etc/supervisor/conf.d
   $ sudo nano olap.conf

   # paste this code into the file
   [program:olap]
   command=/usr/olap/venv/bin/gunicorn -b localhost:5000 -w 4 main:app -t 60 --keep-alive 60
   directory=/usr/olap
   user=bradmin
   autostart=true
   autorestart=true
   stopasgroup=true
   killasgroup=true

   $ sudo supervisorctl reload

Configure Nginx:

.. code-block:: bash

   $ cd /etc/nginx/sites-enabled
   $ sudo rm /etc/nginx/sites-enabled/default
   $ sudo nano olap

   # paste this code into the file
   server {      
      listen 80;
      server_name _;
            
      access_log /var/log/olap_access.log;
      error_log /var/log/olap_error.log;

      location / {      
         proxy_pass http://localhost:5000;
         proxy_redirect off;
         proxy_set_header Host $host;
         proxy_set_header X-Real-IP $remote_addr;
         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      }

   }
   
   $ sudo service nginx reload

#####################
Definition OLAP cubes
#####################

Create a table in the ClickHouse database and place the OLA Pub structure there. Example:

.. code-block:: sql

   CREATE OR REPLACE TABLE db.olap_definition 
   ENGINE = MergeTree() ORDER BY id AS

   SELECT 'olap_table1' AS id,
   '	
      --olap_source Stock
      SELECT
      --olap_measures
         avg(stock_qty) as avg_stock_qty --translation=`Avg stock`
      FROM db.stock
      LEFT JOIN db.stores on stock.store = stores.id

      --olap_source Sale
      SELECT
      --olap_measures
         sum(sale_qty) as sum_sale_qty --translation=`Sale`
      FROM db.sale
      LEFT JOIN db.stores on sale.store = stores.id

      --olap_source Stores
      SELECT
      --olap_dimensions
         id --translation=`Number`
         ,cat --translation=`Сategory`
      FROM db.stores

   ' AS definition

#####################
Connection from Excel
#####################

On the Data tab in Excel, click From Other Sources, and then click From Analysis Services.
Enter the server name in format http://name_or_ip_xltable_server, enter username and password, and then select a cube.

#######
Support
#######

Telegram: https://t.me/brsystems 

Email: help@cloudreports.kz