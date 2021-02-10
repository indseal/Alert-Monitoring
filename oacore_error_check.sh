#!/bin/sh
# +===========================================================================+
# | FILENAME
# |   oacore_error_check.sh
# |
# | DESCRIPTION
# |   This script is used to capture oacore errors the E-Business Suite services 12.2
# |
# | USAGE
# |   ./oacore_error_check.sh
# |
# | PLATFORM
# |   Unix Generic
# |
# | NOTES
# |
# | HISTORY
# | Indraneil Seal       07/20/2016      Created
# |
# |
# +===========================================================================+

. /u01/app/PROD/EBSapps.env run
LOG=/home/applmgr/scripts/oacore_monitor/oacore_error_check.log

### Oacore log location ###

OACORE_LOG=$EBS_DOMAIN_HOME/servers/oacore_server2/logs/oacore_server2.log

### Find current line in oacore log ###

cd /home/applmgr/scripts/oacore_monitor

currentline=`cat $OACORE_LOG|wc -l`
#lastline=`cat tmp2.txt`

if [ -f tmp2.txt ]; then
lastline=`cat tmp2.txt`
else
echo $currentline > tmp2.txt
lastline=`cat tmp2.txt`
fi

### Check for matching errors and print/send the error message to DBA ###

if [ $lastline -eq $currentline ]; then
      echo "No action required!!" >> $LOG
else
      sed -n ${lastline},${currentline}p $OACORE_LOG > tmp1.txt
            if [ `cat tmp1.txt | grep -i "error" |wc -l` -eq 0 ]; then
                echo "No error message found in oacore logs!!" >> $LOG
                rm tmp1.txt
                lastline=$currentline ### Set lastline to currentline and store its value to a temp file for retreival in next iteration ###
                rm tmp2.txt
                echo $lastline > tmp2.txt
            else
                echo "Errors are found in oacore logs!!" > $LOG
                mailx -s "Following errors are found in oacore log in $TWO_TASK EBS(DMZ). Please check if EBS is working fine. Check oacore.log for more information!!" "emailaddress@domain.com" < tmp1.txt
                rm tmp1.txt
                lastline=$currentline ### Set lastline to currentline and store its value to a temp file for retreival in next iteration ###
                rm tmp2.txt
                echo $lastline > tmp2.txt
            fi
fi
