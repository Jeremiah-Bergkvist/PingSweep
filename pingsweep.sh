#!/usr/bin/env bash

# Author: Jeremiah Bergkvist
# Last Edit: 2020-02-14
# Version 1.0 - initial release of pingsweep.sh
# Reference: https://stackoverflow.com/a/58218274

display_usage() { 
    echo -e "Usage:\n$0 <IP/CIDR> \n" 
    echo -e "Example:\n$0 10.0.0.15/29"
} 

# Display usage if missing arguments or -h was supplied
if [  $# -lt 1 ] 
then 
    display_usage
    exit 1
elif [[ ( $# == "--help") ||  $# == "-h" ]] 
then 
    display_usage
    exit 0
fi

base=${1%/*}
cidr=${1#*/}
[ $cidr -lt 8 ] && { echo "Max range is /8."; exit 1;}
mask=$(( 0xFFFFFFFF << (32 - $cidr) ))
IFS=. read o1 o2 o3 o4 <<< $base
ip=$(( ($o2 << 16) + ($o3 << 8) + $o4 ))
ipstart=$(( $ip & $mask ))
ipend=$(( ($ipstart | ~$mask ) & 0x7FFFFFFF ))

seq $ipstart $ipend | while read i; do
    o2=$(( ($i & 0xFF0000) >> 16 ))
    o3=$(( ($i & 0xFF00) >> 8 ))
    o4=$(( $i & 0x00FF ))
    ttl=$( ping -c 1 -W 1  "$o1.$o2.$o3.$o4" | grep -oP 'ttl=([0-9]+)' )
    if [ "$?" -eq "0" ]; then
        echo "$o1.$o2.$o3.$o4 is alive $ttl"
    else
        echo "$o1.$o2.$o3.$o4 is not responding"
    fi
done
