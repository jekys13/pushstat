# PushStat

Bash script for Prometheus Pushgateway. Collects server metrics and push them to Prometheus.

## Overview

Script collects:
* CPU usage (%)
* Memory uage (%)
* Swap usage (%)
* Disk usage (%)
* SSH connections count
* Days before SSL certificate expiration

## Install

```
git clone https://github.com/jekys13/pushstat.git
cd pushstat
./install.sh
systemctl daemon-reload
systemctl start pushstat
```