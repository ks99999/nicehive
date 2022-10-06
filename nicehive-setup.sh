#!/bin/bash

URL=https://raw.githubusercontent.com/ks99999/nicehive/main
wget --no-cache "$URL/nicehive.sh" -O /hive/sbin/nicehive.sh
chmod a+rx /hive/sbin/nicehive.sh
echo "*/10 * * * * /hive/sbin/nicehive.sh >> /tmp/nicehive.log" >> /hive/etc/crontab.root
echo "1 0 * * 1 rm /tmp/nicehive.log" >> /hive/etc/crontab.root
sync  
