#!/bin/bash

###############################################################################
#   check_snmp_cisco_mem_pct.sh v 0.01
#   jwageman(AT)itrsgroup.com / https://github.com/misterdubs/
#
# DESCRIPTION:
#   OP5 / Nagios Plugin to monitor Cisco memory by percentage used
#
#   **** CURRENTLY ONLY SUPPORTING SNMPv3 authPriv ****
################################################################################

read -r -d '' HELP << EOM
Usage:
check_snmp_cisco_mem_pct.sh -U <secUser> -a <SHA|MD5> -A <authPass> -H <ip_address> -x <AES|DES> -X privPass -w warnValue -c critValue

Options:
 -h
    Print detailed help screen
 -H
    IP address or valid hostname
 -a
    SNMPv3 auth protocol (SHA | MD5)
 -x
    SNMPv3 priv protocol (AES | DES)
 -U
    SNMPv3 username
 -A
    SNMPv3 authentication password
 -X
    SNMPv3 privacy password
 -w
    Warning threshold
 -c
    Critical threshold 
EOM

# Cisco free and used memory OID Values
FREEOID=".1.3.6.1.4.1.9.9.48.1.1.1.6.1"
USEDOID=".1.3.6.1.4.1.9.9.48.1.1.1.5.1"

# Parse arguments
while getopts "U:H:a:x:A:X:w:c:h" flag
    do
        case ${flag} in
            U ) USER=${OPTARG} ;;
            H ) HOST=${OPTARG} ;;
            a ) AUTHPRO=${OPTARG} ;;
            x ) PRIVPRO=${OPTARG} ;;
            A ) AUTHPASS=${OPTARG} ;;
            X ) PRIVPASS=${OPTARG} ;;
            w ) WARNLVL=${OPTARG} ;;
            c ) CRITLVL=${OPTARG} ;;
            h ) echo "$HELP" && exit 3;;
        esac
    done

# Execute and parse snmpget values
SNMPCOM="snmpget -v3 -l authPriv -u $USER -a $AUTHPRO -A $AUTHPASS -x $PRIVPRO -X $PRIVPASS $HOST"

USEDMEM=$($SNMPCOM $USEDOID | awk '{print $4}')
FREEMEM=$($SNMPCOM $FREEOID | awk '{print $4}')

# Calcuate percentage used using awk since bash sucks at math
MEMPCT=$(echo $USEDMEM $FREEMEM | awk '{printf "%0.2f", 100 - (100 * ($1 / ($1 + $2)))}')

# Response
if [[ $MEMPCT > $CRITLVL ]]
    then
        echo "CRITICAL: Memory Usage at $MEMPCT % | '%'=$MEMPCT;$WARNLVL;$CRITLVL;0;100"
        exit 2
elif [[ $MEMPCT > $WARNLVL ]]
    then 
        echo "WARNING: Memory Usage at $MEMPCT % | '%'=$MEMPCT;$WARNLVL;$CRITLVL;0;100"
        exit 1
else
    echo "OK: Memory Usage at $MEMPCT % | '%'=$MEMPCT;$WARNLVL;$CRITLVL;0;100"
    exit 0
fi
