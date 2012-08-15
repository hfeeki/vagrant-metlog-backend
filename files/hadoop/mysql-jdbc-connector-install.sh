#!/bin/sh
# This script fetchs the mysql connector and installs it into Hive

mkdir -p /tmp/mysql-connector
cd /tmp/mysql-connector
curl -L 'http://www.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.15.tar.gz/from/http://mysql.he.net/' | tar xz
cp mysql-connector-java-5.1.15/mysql-connector-java-5.1.15-bin.jar /usr/lib/hive/lib/
