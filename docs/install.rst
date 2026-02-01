
Install
=======
XLTable available as a ready-to-deploy virtual machine image in Yandex Сloud:
https://yandex.cloud/ru/marketplace/products/cloudreports/xltable

Below are instructions for self-installation for the Ubuntu operating system and ClickHouse. 

Prepare Ubuntu server with minimum requirements: hard drive - 100 gb, ram - 16 gb.

Make sure that the Ubuntu server has access to the ClickHouse server on port 8443 and that the client machines with Excel have access to the Ubuntu server on port 80 or 443.

Installing Supervisor, Nginx and some other:

.. code-block:: bash

   $ sudo apt-get -y update
   $ sudo apt-get -y install supervisor nginx git p7zip-full

Create olap folder:

.. code-block:: bash

   $ sudo mkdir /usr/olap
   $ sudo chmod a+rwx /usr/olap 

Copy XLTable distribution file to the olap folder. Example of copying from Windows:

.. code-block:: bash

   scp -r c:\win_local_folder\xltable.7z user@server_ip:/usr/olap

Unpacking the distribution file and grant execution rights:

.. code-block:: bash

   $ cd /usr/olap
   $ 7z x xltable.7z
   $ cd /usr/olap/xltable
   $ chmod +x main.bin

Installing Yandex certificates if needed for ClickHouse connection (need only for YandexCloud):

.. code-block:: bash

   sudo mkdir --parents /usr/local/share/ca-certificates/Yandex/ && \
   sudo wget "https://storage.yandexcloud.net/cloud-certs/RootCA.pem" \
      --output-document /usr/local/share/ca-certificates/Yandex/RootCA.crt && \
   sudo wget "https://storage.yandexcloud.net/cloud-certs/IntermediateCA.pem" \
      --output-document /usr/local/share/ca-certificates/Yandex/IntermediateCA.crt && \
   sudo chmod 655 \
      /usr/local/share/ca-certificates/Yandex/RootCA.crt \
      /usr/local/share/ca-certificates/Yandex/IntermediateCA.crt && \
   sudo update-ca-certificates

Set up connections with database (configuration examples in the folder /usr/olap/xltable/setting):

.. code-block:: bash

   $ cd /usr/olap/xltable/setting
   $ nano settings.json

Add supervisor configuration:

.. code-block:: bash
   
   $ cd /etc/supervisor/conf.d
   $ sudo nano olap.conf

   # paste this code into the file and change <you_user>
   [program:olap]
   command=/usr/olap/xltable/main.bin
   directory=/usr/olap/xltable
   user=<you_user>
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

   # paste this code into the file, change if necessary 80 to 443 for https
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

-----------------
Important points:
-----------------
- After each changing the settings.json file, need to restart the service using the command:
   
.. code-block:: bash
   $ sudo supervisorctl reload
