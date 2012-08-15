#!/bin/sh

/usr/bin/hadoop dfs -ls /
rc=$?
while [[ $rc -ne 0 ]]
do
    sleep 1
    /usr/bin/hadoop dfs -ls /
done
