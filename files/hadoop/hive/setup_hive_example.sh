/usr/bin/hive -e "create table metlog_json(json STRING);"
/usr/bin/hadoop dfs -mkdir /var/log/aitc
/usr/bin/hadoop dfs -put /var/log/aitc/metrics_hdfs.log /var/log/aitc
/usr/bin/hive -e " LOAD DATA INPATH '/var/log/aitc/metrics_hdfs.log' overwrite into table metlog_json"
