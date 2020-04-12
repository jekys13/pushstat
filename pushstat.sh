#!/bin/bash

opt_prometeus_host=
opt_prometeus_port=9091
opt_host_name=
opt_app_path='/var/www'
opt_interval=15
opt_ssl_domain=
opt_ssl_port='443'

opt_config=
opt_test_mode=false

help () {
  echo
  usage
  echo
  echo "  Simple script for pushing system stats to the Prometheus Pushgateway"
  echo
  echo "  Options: "
  echo "    -n, --name <name>          instance name in prometeus"
  echo "    -h, --host <address>       prometeus pushgateway host (example: http://example.net)"
  echo "    -p, --port <port>          prometeus pushgateway port (default: 9091)"  
  echo "    -a, --app_path <path>      app path (default: /var/www)"     
  echo "    -i, --interval <seconds>   collect metrics every n seconds (default: 15)" 
  echo "    -d, --domain <domain>      domain for SSL certificate check"
  echo "    -s, --ssl_port <port>      domain port for SSL certificate check (default: 443)"   
  echo "    -c, --config <path>        set file config"  
  echo "    -t, --test                 run this script in a test mode"
  echo "    -h, --help                 show this text"
  echo
}

usage () {
  echo "  Usage: $0 -n -h [-p] [-a] [-i] [-d] [-s] [-c] [-t]"
}

push_stat() {
	if [ $opt_test_mode = true ]; then
		echo "$1: $2"
	else
		echo "$1 $2" | curl --data-binary @- "$opt_prometeus_host:$opt_prometeus_port/metrics/job/pushgateway/instance/$opt_host_name"		
	fi
}

while [ $# -gt 0 ]; do
  case $1 in
    -n|--name)
      shift
      opt_host_name=$1
      ;;  
    -h|--host)
      shift
      opt_prometeus_host=$1
      ;;
    -p|--port)
      shift
      opt_prometeus_port=$1
      ;;   
    -a|--app_path)
      shift
      opt_app_path=$1
      ;;               	  	
    -i|--interval)
      shift
      opt_interval=$1
      ;;  	
    -t|--test)
      opt_test_mode=true
      ;;
    -c|--config)
	  shift
      opt_config=$1
      ;;
    -h|--help)
      help
      exit
      ;;
  esac

  shift
done

if [ -n "$opt_config" ]; then
	. $opt_config

	opt_prometeus_host=$(awk -F "=" '/prometheus_host/ {print $2}' $opt_config)
	opt_prometeus_port=$(awk -F "=" '/prometheus_port/ {print $2}' $opt_config)
	opt_host_name=$(awk -F "=" '/host_name/ {print $2}' $opt_config)
	opt_interval=$(awk -F "=" '/interval/ {print $2}' $opt_config)
	opt_ssl_domain=$(awk -F "=" '/ssl_domain/ {print $2}' $opt_config)
	opt_ssl_port=$(awk -F "=" '/ssl_port/ {print $2}' $opt_config)
	opt_app_path=$(awk -F "=" '/app_path/ {print $2}' $opt_config)
fi

if [ -z "$opt_prometeus_host" ] || [ -z "$opt_prometeus_port" ] || [ -z "$opt_host_name" ] || [ -z "$opt_interval" ]
then
	echo 'One of required params is empty'
	exit 1
fi

while :
do
	cpu_usage=$(ps axo %cpu | awk '{ sum+=$1 } END { printf "%.1f\n", sum }' | tail -n 1)
	push_stat 'cpu_usage' $cpu_usage

	memory_usage=$(free | awk '/Mem:/ {
	              printf "%.1f", 100 - $4 / ($3 + $4) * 100}')
	push_stat 'memory_usage' $memory_usage

	swap_usage=$(free |
	        awk '/Swap/{ if (int($2) == 0) exit; printf "%.1f", $3 / $2 * 100.0 }')
	if [ -z "$swap_usage" ]
	then
		swap_usage='0.0'
	fi
	push_stat 'swap_usage' $swap_usage

	disk_usage=$(cd $opt_app_path && df . | awk '{if ($1 != "Filesystem") print $5}' | tr -d %)
	push_stat 'disk_usage' $disk_usage

	ssh_connections=$(who | wc -l)
	push_stat 'ssh_connections' $ssh_connections

	if [ ! -z "$opt_ssl_domain" ] && [ ! -z "$opt_ssl_domain" ]
	then
		now_epoch=$( date +%s )
		ssl_date=$(echo | openssl s_client -showcerts -connect "$opt_ssl_domain:$opt_ssl_port" 2>/dev/null | openssl x509 -inform pem -noout -enddate | cut -d "=" -f 2)
		ssl_epoch=$( date -d "$ssl_date" +%s )
		ssl_days="$(( ($ssl_epoch - $now_epoch) / (3600 * 24) ))"
		push_stat 'ssl_days' $ssl_days
	fi

	sleep $opt_interval
done 