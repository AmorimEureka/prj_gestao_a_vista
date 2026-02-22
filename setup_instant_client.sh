#!/bin/sh
set -e

apt update
apt install -y libaio1 wget unzip

# assert required packages are correctly installed previously or do it manualy
mkdir .oracle
cd .oracle/

# Download oracle instant client zip
wget --output-document=client.zip https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-basiclite-linux.x64-19.23.0.0.0dbru.zip
unzip client.zip
rm client.zip
apt remove -y wget unzip

echo Linking files
cd instantclient_19_23/
ln -fs libclntsh.so.12.1 libclntsh.so
ln -fs libocci.so.12.1 libocci.so

echo finally, dont forget to set LD_LIBRARY_PATH to /usr/local/airflow/.oracle/instantclient_19_23/