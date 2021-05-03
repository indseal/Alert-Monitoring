#!/bin/bash
#

EMAIL1=youremail@domain
EMAIL2=youremail2@domain

for i in  grid oracle
do

  # convert current date to seconds
  currentdate=`date +%s`

  # find expiration date of user
   userexp=`sudo chage -l $i |grep 'Password expires' | cut -d: -f2`

  if [[ ! -z $userexp ]]
  then

    # convert expiration date to seconds
    passexp=`date -d "$userexp" +%s`

    #if [[ $passexp != "never" ]]
    #then
      # find the remaining days for expiry
      exp=`expr $passexp - $currentdate`
      # convert remaining days from sec to days
      expday=`expr $exp / 86400`

      if [[ $expday -le 8 ]]; then
        echo "Please take  necessary action"  | mailx -s "Password for $i on `hostname` will expire in $expday day/s" $EMAIL1,$EMAIL2
      fi
    #fi
  fi

done
