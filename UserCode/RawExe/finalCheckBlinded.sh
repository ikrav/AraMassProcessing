#!/bin/bash

source $ARAMASSPROCESS/UserCode/RawExe/bashEchoLoadBar.sh
source $ARAMASSPROCESS/UserCode/RawExe/processingVariables.sh

#user input (not needed): (1)inputFiles  (2)outputFileNameBlinded

if [ $# -gt 0 ]
then
    allfile=(`cat $1`)
else
    allfile=(`cat $ARAMASSPROCESS/UserCode/RawExe/Outputs/okayToProcessARA${STATIONNUM}.txt`)
fi

if [ $# -gt 1 ]
then
    allprobs=$2
else
    allprobs=$ARAMASSPROCESS/UserCode/RawExe/Outputs/problemFiles.Blinded.${DATAYEAR}.ARA${STATIONNUM}.txt
fi

if [ -f $allprobs ] ; then rm $allprobs ; fi

CompareGreaterThan() {
    awk "BEGIN {if ($1>$2) printf 1; else printf 0;}"
}

CleanRemoveFiles() {
    for CKfileCK in $*
    do
	if [ -f "$CKfileCK" ]
	then
	    rm $CKfileCK
	fi
    done
}

END_DIR1=/data/exp/ARA/${DATAYEAR}/blinded/L1/ARA${STATIONNUM}

totcnt=${#allfile[@]}
cnt=0

#temps
allpedes=tempPedes.txt
allevent=tempEvent.txt
alleventhk=tempEventHk.txt
allsensorhk=tempSensorHk.txt
allconfig=tempConfig.txt
allmonitor=tempMonitor.txt
allrunstart=tempRunStart.txt
allrunstop=tempRunStop.txt
alldirect=tempDirect.txt

CleanRemoveFiles $allpedes $allevent $alleventhk $allsensorhk $allconfig $allmonitor $allrunstart $allrunstop $alldirect

find $PEDESTAL_OUTPUT_DIRECTORY -name pedestalValues* > $allpedes
find $END_DIR1 -name event0* > $allevent
find $END_DIR1 -name eventHk* > $alleventhk
find $END_DIR1 -name sensorHk* > $allsensorhk
find $END_DIR1 -name configFile* > $allconfig
find $END_DIR1 -name monitor* > $allmonitor
find $END_DIR1 -name runStart* > $allrunstart
find $END_DIR1 -name runStop* > $allrunstop
find $END_DIR1 -name run0* > $alldirect

echo "#######################################################"
echo "# CHECKING BLINDED DATA ###############################"
echo "#######################################################"

for line in "${allfile[@]}"
do

    ((cnt++))
    percentComplete=`awk "BEGIN{printf ${cnt}/${totcnt}*100.0}"`
    if (( $cnt % 10 == 0 )) ; then echoload $percentComplete ; fi
    
    runNum=`echo "$line" | sed -e "s^.*run_^^g" | awk -v FS='.' '{printf $1}'`
    cat $allpedes | grep -q "$runNum" && findRes=1 || findRes=0
    
    if [ $findRes -eq 0 ]
    then
	
	rundir1=`grep $runNum $alldirect | sed -e "s^event.*^^g"`

	#echoload $percentComplete "$runNum: $rundir1"
	
	if [ -d "$rundir1" ]
	then
	    dataraw=`du -b $line | cut -f 1`
	    dataevent=`du -b $rundir1/ | cut -f 1`
	    dataratio=`awk "BEGIN{ printf $dataevent/$dataraw }"`
	    #echo -e "raw: $dataraw \t Event: $dataevent \t ratio: $dataratio"
	    if [ `CompareGreaterThan $dataratio 1.25` = "1" ] || [ `CompareGreaterThan 1.025 $dataratio` = "1" ]
	    then
		echoload $percentComplete "$runNum ratio: \033[37m\033[41m$dataratio\033[0m \t raw: $dataraw  $line \t Event: $dataevent $rundir1"
		echo "$line" >> $allprobs
	    fi

	    findRes2=0
	    findRes3=0
	    message="$runNum Missing: "
	    tempvar=`grep $runNum $allevent` ; if [ ! -f "$tempvar" ] ; then findRes3=1 ; message+="event$runNum.root " ; fi
	    tempvar=`grep $runNum $alleventhk` ; if [ ! -f "$tempvar" ] ; then findRes2=1 ; message+="eventHk$runNum.root " ; fi
	    tempvar=`grep $runNum $allsensorhk` ; if [ ! -f "$tempvar" ] ; then findRes2=1 ; message+="sensorHk$runNum.root " ; fi
	    tempvar=`grep $runNum $allconfig` ; if [ ! -f "$tempvar" ] ; then findRes2=1 ; message+="configFile.$runNum.dat " ; fi
	    tempvar=`grep $runNum $allmonitor` ; if [ ! -f "$tempvar" ] ; then findRes2=1 ; message+="monitor.run$runNum.dat " ; fi
	    tempvar=`grep $runNum $allrunstart`
	    if [ ! -f "$tempvar" ] 
	    then
		findRes2=1 
		message+="runStart.run$runNum.dat " 
	    else
		runstartdatasize=`du -b $tempvar | cut -f 1`
		if [ $runstartdatasize -gt 2 ] 
		then
		    tempunix=`cat $tempvar | grep Time: | sed -e "s^Time: ^^g"`
		    tempyear=`date -d @$tempunix +"%Y"`
		    if [ ! $tempyear -eq $DATAYEAR ] ; then echoload $percentComplete $asBlue "$rundir1 needs to be moved to: $tempyear" ; fi
		fi
	    fi
	    tempvar=`grep $runNum $allrunstop` ; if [ ! -f "$tempvar" ] ; then findRes2=1 ; message+="runStop.run$runNum.dat " ; fi

	    if [ $findRes3 -eq 1 ]
	    then
		echoload $percentComplete $asBlack "$message" ;
	    else
		if [ $findRes2 -eq 1 ] ; then echoload $percentComplete $asPurple "$message" ; fi
	    fi

	else
	    echoload $percentComplete $asRed "missing run$runNum"
	    echo "$line" >> $allprobs
	fi
    fi
    
done

CleanRemoveFiles $allpedes $allevent $alleventhk $allsensorhk $allconfig $allmonitor $allrunstart $allrunstop $alldirect
echoload 100

