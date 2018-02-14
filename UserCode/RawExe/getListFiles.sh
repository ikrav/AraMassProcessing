#!/bin/bash

source $ARAMASSPROCESS/UserCode/RawExe/bashEchoLoadBar.sh
source $ARAMASSPROCESS/UserCode/RawExe/processingVariables.sh

echo "Searching $DATASTORE/ for *ARA${STATIONNUM}*.tar"

ALL_FILES=(`find $DATASTORE/ -name "*ARA${STATIONNUM}*.tar"`)
crtcnt=-1
totcnt=${#ALL_FILES[@]}
goodfiles=
goodfilesOut=$ARAMASSPROCESS/UserCode/RawExe/Outputs/okayToProcessARA${STATIONNUM}.txt
duplicates=$ARAMASSPROCESS/UserCode/RawExe/Outputs/duplicates.${DATAYEAR}.ARA${STATIONNUM}.txt
smalls=$ARAMASSPROCESS/UserCode/RawExe/Outputs/smalls.${DATAYEAR}.ARA${STATIONNUM}.txt

if [ -f $goodfilesOut ] ; then rm $goodfilesOut ; fi
if [ -f $duplicates ] ; then rm $duplicates ; fi

echo "$totcnt files found"

for ifile in "${ALL_FILES[@]}"
do
    
    ((crtcnt++))
    percentComplete=`awk "BEGIN{printf ${crtcnt}/${totcnt}*100.0}"`
    if (( $crtcnt % 50 == 0 )) ; then echoloadTime $percentComplete ; fi
    
    datasize=`du -k $ifile | awk '{ printf $1 }'`
    runnum=`echo "$ifile" | awk -v FS="." '{printf $3}'`
    
    if [ $datasize -gt 1000 ]
    then
	echo "$goodfiles" | grep -q "$runnum" && findRes=1 || findRes=0
	if [ $findRes -eq 0 ] 
	then
	    goodfiles+=`printf "%s " $ifile`
	else 
	    loc=`echo "$goodfiles" | sed -e 's/\ /\n/g' | grep "$runnum"`
	    datasize2=`du -k $loc | awk '{ printf $1 }'`
	    echoloadTime $percentComplete $asRed "Duplicate found: $runnum"
	    if [ $datasize -gt $datasize2 ]
	    then
		echoloadTime $percentComplete $asGreen "removing $loc from list"
		goodfiles=`echo $goodfiles | sed -e "s^ $loc^^g"`
		goodfiles+=`printf " %s " $ifile`
	    else
		echoloadTime $percentComplete $asGreen "keeping $loc in list"
	    fi
	    echoloadTime $percentComplete "file1: $loc \t Data Size: $datasize2 kB"
	    echoloadTime $percentComplete "file2: $ifile \t Data Size: $datasize kB"
	    echo "$runnum" >> $duplicates
	fi
    else
	echoloadTime $percentComplete $asBlue "Small file: $ifile \t Data Size: $datasize kB"
	echo "$runnum" >> $smalls
    fi
    
done

echoloadTime 100

#for ifile in $goodfiles
#do
#    echo "$ifile" >> $goodfilesOut
#done

echo "$goodfiles" | sed -e 's^\ ^\n^g' >> "$goodfilesOut"