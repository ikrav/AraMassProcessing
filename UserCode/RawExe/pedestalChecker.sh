#!/bin/bash

source $ARAMASSPROCESS/UserCode/RawExe/bashEchoLoadBar.sh
source $ARAMASSPROCESS/UserCode/RawExe/processingVariables.sh

outputtext=${PEDESTAL_OUTPUT_DIRECTORY}/goodPedestals.txt

if [ -f $outputtext ] ; then rm $outputtext ; fi

inpedes=(`find $PEDESTAL_OUTPUT_DIRECTORY -name pedestalValues*`)
loadcnt=0
loadtot=${#inpedes[@]}

for file in ${inpedes[@]}
do
    ckfile=`python ./goodPedChecker.py $file`
    if [ -f $ckfile ] 
    then
	echo "$file" >> $outputtext
    fi
    ((loadcnt++))
    if (($loadcnt % 10 == 0)) ; then echoload `awk "BEGIN{printf ($loadcnt/$loadtot)*100}"` ; fi
done

echoload 100
