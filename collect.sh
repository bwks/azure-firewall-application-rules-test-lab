#! /usr/bin/bash

# Call with:
#  FIREWALL_PIP="x.x.x.x" ./collect.sh


if [ -z "${FIREWALL_PIP}" ]; then
  echo "Environment variable FIREWALL_PIP is not set. Exiting."
  exit 1
fi

declare -A HOSTS;

HOSTS["client"]=2290
HOSTS["webserver1"]=2291 # no inspect
HOSTS["webserver2"]=2292 # inspect
HOSTS["webserver3"]=2293 # lets encrypt inspect

for server in ${!HOSTS[@]}; do
  echo "${server} port ${HOSTS[$server]}"
  scp -P ${HOSTS[$server]} ${FIREWALL_PIP}:~/\*.pcap ./output/
done

# Only client has curl logs
scp -P 2290 ${FIREWALL_PIP}:~/\*-curl.txt ./output/