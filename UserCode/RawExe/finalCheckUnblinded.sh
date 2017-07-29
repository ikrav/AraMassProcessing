#!/bin/bash

source $ARAMASSPROCESS/UserCode/RawExe/bashEchoLoadBar.sh
source $ARAMASSPROCESS/UserCode/RawExe/processingVariables.sh

#user input (not needed): (1)inputFiles  (2)outputFileNameBlinded

echo "#######################################################"
echo "# RUNNING FINAL CHECK #################################"
echo "#######################################################"

if [ $# -gt 0 ]
then
    allfile=(`cat $1`)
else
    allfile=(`cat okayToProcessARA${STATIONNUM}.txt`)
fi

if [ $# -gt 1 ]
then
    allprobsten=$2
else
    allprobsten=$ARAMASSPROCESS/UserCode/RawExe/Outputs/problemFiles.Unblinded.${DATAYEAR}.ARA${STATIONNUM}.txt
fi

if [ -f $allprobsten ] ; then rm $allprobsten ; fi

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
END_DIR2=/data/exp/ARA/${DATAYEAR}/unblinded/L1/ARA${STATIONNUM}

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

allevent10=tempEvent10.txt
alleventhk10=tempEventHk10.txt
allsensorhk10=tempSensorHk10.txt
allconfig10=tempConfig10.txt
allmonitor10=tempMonitor10.txt
allrunstart10=tempRunStart10.txt
allrunstop10=tempRunStop10.txt
alldirect10=tempDirect10.txt

CleanRemoveFiles $allpedes $allevent $alleventhk $allsensorhk $allconfig $allmonitor $allrunstart $allrunstop $alldirect  $allevent10 $alleventhk10 $allsensorhk10 $allconfig10 $allmonitor10 $allrunstart10 $allrunstop10 $alldirect10

find $PEDESTAL_OUTPUT_DIRECTORY -name pedestalValues* > $allpedes

find $END_DIR1 -name event0* > $allevent
find $END_DIR1 -name eventHk* > $alleventhk
find $END_DIR1 -name sensorHk* > $allsensorhk
find $END_DIR1 -name configFile* > $allconfig
find $END_DIR1 -name monitor* > $allmonitor
find $END_DIR1 -name runStart* > $allrunstart
find $END_DIR1 -name runStop* > $allrunstop
find $END_DIR1 -name run0* > $alldirect


find $END_DIR2 -name event0* > $allevent10
find $END_DIR2 -name eventHk* > $alleventhk10
find $END_DIR2 -name sensorHk* > $allsensorhk10
find $END_DIR2 -name configFile* > $allconfig10
find $END_DIR2 -name monitor* > $allmonitor10
find $END_DIR2 -name runStart* > $allrunstart10
find $END_DIR2 -name runStop* > $allrunstop10
find $END_DIR2 -name run0* > $alldirect10

for line in "${allfile[@]}"
do

    ((cnt++))
    percentComplete=`awk "BEGIN{printf ${cnt}/${totcnt}*100.0}"`
    if (( $cnt % 10 == 0 )) ; then echoloadTime $percentComplete ; fi
    
    runNum=`echo "$line" | sed -e "s^.*run_^^g" | awk -v FS='.' '{printf $1}'`
    cat $allpedes | grep -q "$runNum" && findRes=1 || findRes=0
    
    if [ $findRes -eq 0 ]
    then
	
	rundir1=`grep $runNum $alldirect | sed -e "s^event.*^^g"`
	rundir2=`grep $runNum $alldirect10 | sed -e "s^event.*^^g"`

	#echoloadTime $percentComplete "$runNum: $rundir1"

	if [ -d "$rundir1" ] && [ -d "$rundir2" ]
	then
	    eventfileloc1=`grep $runNum $allevent`
	    eventfileloc2=`grep $runNum $allevent10`
	    if [ -f "$eventfileloc1" ] && [ -f "$eventfileloc2" ]
	    then
		#echoloadTime $percentComplete $asCyan "Found $eventfileloc1"
		#echoloadTime $percentComplete $asCyan "Found $eventfileloc2"
		datafull=`du -b $eventfileloc1 | cut -f 1`
		data10=`du -b $eventfileloc2 | cut -f 1`
		dataratio=`awk "BEGIN{ printf $data10/$datafull }"`
		if [ `CompareGreaterThan $dataratio 0.125` = "1" ] || [ `CompareGreaterThan 0.08 $dataratio` = "1" ]
		then
		    echoloadTime $percentComplete "$runNum ratio: \033[37m\033[41m$dataratio\033[0m \t Full: $datafull  $line \t 10Percent: $data10 $rundir2"
		    echo "$line" >> $allprobsten
		fi
		#echoloadTime $percentComplete $asCyan "run$runNum ratio: $dataratio"

		tempvar=`grep $runNum $allrunstart10`
		if [ -f "$tempvar" ] 
		then
		    tempunix=`cat $tempvar | grep Time: | sed -e "s^Time: ^^g"`
		    tempyear=`date -d @$tempunix +"%Y"`
		    if [ ! $tempyear -eq $DATAYEAR ] ; then echoloadTime $percentComplete $asBlue "$rundir1 needs to be moved to: $tempyear" ; fi
		else
		    tempvar=`grep $runNum $allrunstart`
		    if [ -f "$tempvar" ] 
		    then
			tempunix=`cat $tempvar | grep Time: | sed -e "s^Time: ^^g"`
			tempyear=`date -d @$tempunix +"%Y"`
			if [ ! $tempyear -eq $DATAYEAR ] ; then echoloadTime $percentComplete $asBlue "$rundir1 needs to be moved to: $tempyear" ; fi
		    fi
		fi


	    elif [ -f "$eventfileloc1" ] && [ ! -f "$eventfileloc2" ]
	    then
		echoloadTime $percentComplete $asBlack "missing event$runNum.root in unblinded set (10 percent)"
		echo "$line" >> $allprobsten
	    elif [ ! -f "$eventfileloc1" ] && [ -f "$eventfileloc2" ]
	    then
		echoloadTime $percentComplete $asBlack "missing event$runNum.root in blinded set (Full)"
	    else
		echoloadTime $percentComplete $asBlack "missing event$runNum.root in both unblinded and blinded sets"
		echo "$line" >> $allprobsten
	    fi




	elif [ -d "$rundir1" ] && [ ! -d "$rundir2" ]
	then
	    echoloadTime $percentComplete $asRed "missing run$runNum in unblinded set (10 percent)"
	    echo "$line" >> $allprobsten
	elif [ ! -d "$rundir1" ] && [ -d "$rundir2" ]
	then
	    echoloadTime $percentComplete $asRed "missing run$runNum in blinded set (Full)"
	else
	    echoloadTime $percentComplete $asRed "missing run$runNum in both unblinded and blinded sets "
	    echo "$line" >> $allprobsten
	fi



    fi
    
done

CleanRemoveFiles $allpedes $allevent $alleventhk $allsensorhk $allconfig $allmonitor $allrunstart $allrunstop $alldirect $allevent10 $alleventhk10 $allsensorhk10 $allconfig10 $allmonitor10 $allrunstart10 $allrunstop10 $alldirect10
echoloadTime 100
