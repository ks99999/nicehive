#!/bin/bash

source /hive-config/rig.conf

baseUrl='https://api2.hiveos.farm/api/v2'
switchPercent=10
fsPrefix='AUTO'

accessToken=`cat /hive-config/nicehive.token`

# coefficients for correct price finding
declare -A DELIM
DELIM[ETCHASH]=0.01
DELIM[AUTOLYKOS]=0.01
DELIM[OCTOPUS]=0.01
DELIM[KAWPOW]=0.01
DELIM[DAGGERHASHIMOTO]=0.01
DELIM[ZELHASH]=0.00000001

# get workers
response=`curl -s -H "Content-Type: application/json" \
        -H "Authorization: Bearer $accessToken" "$baseUrl/farms/$FARM_ID/workers/$RIG_ID"`
[ $? -ne 0 ] && (>&2 echo 'Curl error') && exit 1

if `echo $response | grep -q 'Unauthenticated'` ; then
        rm /tmp/nicehive.token
        exit
fi

echo "$response" > /tmp/nicehive.worker

CURRENTFS=`cat /tmp/nicehive.worker | jq -r ". | select (.id == $RIG_ID) | .flight_sheet.name"`
if ! `echo $CURRENTFS | grep -q ^$fsPrefix-` ; then
    echo Manual fs, do nothing. Change fs to any $fsPrefix-* for autoswitching
    exit
fi

# get farms
response=`curl -s -H "Content-Type: application/json" \
        -H "Authorization: Bearer $accessToken" "$baseUrl/farms/$FARM_ID/fs"`
[ $? -ne 0 ] && (>&2 echo 'Curl error') && exit 1
echo "$response" | jq '.data[]' > /tmp/nicehive.fs

wget -q https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info -O -| jq ".miningAlgorithms[]" > /tmp/nicehive.prices

date

BESTPROFIT=0
declare -A DAILYPROFIT
for LINE in `cat /tmp/nicehive.fs | jq -r '.name' | grep $fsPrefix` ; do
 ALGO=`echo $LINE | cut -d '-' -f 2`
 RATE=`echo $LINE | cut -d '-' -f 3`
 PRICE=`cat /tmp/nicehive.prices | jq -r ". | select (.algorithm == \"$ALGO\") | .paying" | awk '{printf("%.8f\n", $1)}'`
 DAILYPROFIT[$ALGO]=`echo "$RATE * $PRICE * ${DELIM[$ALGO]}" | bc | sed -e 's/^-\./-0./' -e 's/^\./0./'`
 echo Fs $fsPrefix-$ALGO-$RATE daily_profit=${DAILYPROFIT[$ALGO]}
 if (( $(echo "$BESTPROFIT < ${DAILYPROFIT[$ALGO]}" |bc -l) )) ; then
    BESTPROFIT=${DAILYPROFIT[$ALGO]}
    BESTPROFITALGO="$ALGO"
 fi
done


CURRENTALGO=`echo $CURRENTFS | cut -d '-' -f 2`
echo - current fs $CURRENTFS daily_profit=${DAILYPROFIT[$CURRENTALGO]}

NEWFS=`cat /tmp/nicehive.fs | jq -r '.name' | grep $fsPrefix-$BESTPROFITALGO-`
echo - most profitable fs $NEWFS daily_profit=$BESTPROFIT

if [ "$1" != "" ] ; then exit; fi

if (( $(echo "(${DAILYPROFIT[$CURRENTALGO]} * (100 + $switchPercent) / 100) < $BESTPROFIT" |bc -l) )) ; then
        FSID=`cat /tmp/nicehive.fs | jq -r ". | select (.name == \"$NEWFS\") | .id"`
        echo "!!! Changing fs to $NEWFS ($FSID)"
        response=`curl -s -H "Content-Type: application/json" \
                -H "Authorization: Bearer $accessToken" -X PATCH -d "{\"fs_id\": $FSID}" \
                "$baseUrl/farms/$FARM_ID/workers/$RIG_ID"`
        [ $? -ne 0 ] && (>&2 echo 'Curl error') && exit 1
else
        echo "Profit from change to most profitable fs will be less than $switchPercent% - do nothing"
fi
