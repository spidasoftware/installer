# installer

Installation Requirements
----------

1. Ubuntu 14.04+, RHEL 6.5+
2. A Docker Username that you have provided to SPIDA.


Default Installation
-------------------

A complete installation is completed by running the following command on the server

`sudo curl -o install https://raw.githubusercontent.com/spidasoftware/installer/master/install && sudo chmod +x install && sudo ./install -tag tag -username dockerUsername -email dockerEmail [-host host] [--no-spidamin] [--no-postgresql] [--no-mongodb] && sudo rm install`

