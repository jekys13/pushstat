#!/bin/bash

txtBlock="\e[33m"
txtQuestion="\e[36m"
txtInfo="\e[93m"
txtSuccess="\e[92m"
txtError="\e[91m"

txtBold="\e[1m"
txtEnd="\e[0m"

function printBlock(){
    symbol="="
    spaces_count=8

    length=$(echo -n $1 | wc -c)
    total_lenght=$(($length + 2*$spaces_count + 2))

    line=$(for ((i=1; i<=$total_lenght; i++)); do echo -e -n "$symbol"; done)
    spaces=$(for ((i=1; i<=$spaces_count; i++)); do echo -e -n " "; done)

    echo -e ""
    echo -e "$txtBlock$line"
    echo -e " $spaces$1$spaces "
    echo -e "$line$txtEnd" 
    echo -e ""
}

function printQuestion(){
    echo -e -n "$txtQuestion$1: $txtEnd"
}

function printInfo(){
    echo -e "$txtInfo$txtBold$1$txtEnd"
}

function printSuccess(){
    echo -e "$txtSuccess$txtBold$1$txtEnd"
}

function printError(){
    echo -e "$txtError$txtBold$1$txtEnd"
}

printBlock 'PUSHSTAT INSTALLER'

printQuestion 'Enter Prometheus URL (example: http://example.com)'
read prometheus_url
if [ -z "$prometheus_url" ]
then
    printError "Prometheus URL is required"
    exit 1
fi

printQuestion 'Enter Prometheus Pushgateway port (default: 9091)'
read prometheus_port
if [ -z "$prometheus_port" ]
then
    prometheus_port='9091' 
fi

printQuestion 'Enter instance name'
read host_name
if [ -z "$host_name" ]
then
    printError "Instance name is required"
    exit 1 
fi

printQuestion 'Enter app folder (default: /var/www)'
read app_path
if [ -z "$app_path" ]
then
    app_path='/var/www'
fi

printQuestion 'Enter metrics push interval (default: 15)'
read interval
if [ -z "$interval" ]
then
    interval='15' 
fi

mkdir '/etc/pushstat'

echo "prometheus_host=$prometheus_url" > '/etc/pushstat/config.ini'
echo "prometheus_port=$prometheus_port" >> '/etc/pushstat/config.ini'
echo "host_name=$host_name" >> '/etc/pushstat/config.ini'
echo "app_path=$app_path" >> '/etc/pushstat/config.ini'
echo "interval=$interval" >> '/etc/pushstat/config.ini'

cp pushstat.sh /usr/local/bin/pushstat
cp pushstat.service /etc/systemd/system/pushstat.service


