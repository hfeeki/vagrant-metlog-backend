CREATE DATABASE metastore;
USE metastore;
SOURCE /usr/lib/hive/scripts/metastore/upgrade/mysql/hive-schema-0.7.0.mysql.sql;

CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'password';
GRANT SELECT,INSERT,UPDATE,DELETE ON metastore.* TO 'hiveuser'@'%';
REVOKE ALTER,CREATE ON metastore.* FROM 'hiveuser'@'%';
