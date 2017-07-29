#!/bin/sh

set +x

source $ARAMASSPROCESS/UserCode/RawExe/processingVariables.sh

echo `date`

echo "In processRuns.sh script    "
echo "list of files to process:   "   $1
echo "Path for storing log files: "   $2
echo "Section/Job number:         "   $3
#echo "Results output path:        "   $4
JOB_NUMBER=$3
OUTPUT_DIR=$TMPDIR/Job_${JOB_NUMBER}   #TMPDIR is local tmp given by Condor with a lot of space
#L1_DIR=$4                         # where final output files will be stored
#L1_DIR=/data/user/aschultz/FinalizedL0/2014/ARA02/10Per/
#L1_DIR=/data/user/aschultz/TestFinalizedL0/
L1_DIR=$END_DIR
LOG_DIR=$2/Job_${JOB_NUMBER}
TAR_FILES=$1

echo "$OUTPUT_DIR"

RAW_DIR=

#binaries
RANDOM_FILTER_BIN=$ARARAWDATATOOLS/build/randomFilter
ARA_EVENT_PICKER_BIN=$ARARAWDATATOOLS/build/AraEventPicker
NUM_EVENTS=100

#To log failed event files.
TAR_FAILED=${LOG_DIR}/'Tar_failures'${JOB_NUMBER}'.log'
EVENT_ALL_FAILED=${LOG_DIR}/'Event_all_failures'${JOB_NUMBER}'.log'
EVENT_FAILED=${LOG_DIR}/'Event_failures'${JOB_NUMBER}'.log'

RUN_FILE_LIST=${LOG_DIR}/runs.txt
YEAR_NOT_MATCH=${LOG_DIR}/yearnotmatch.txt

#Dummy ped file(we don't really need one for the random filter)
PED_FILE=/home/meures/data_files/ARA03/pedestals/run_003787/pedestalValues.run003787.dat

cat $TAR_FILES

# check to see if we have enough files to process
if test `cat $TAR_FILES | wc -l` -lt 1; then
    echo "No FILES to process... EXITING!!!"
#    rm ${TAR_FILES}
    return 1
fi

if [[ -d $OUTPUT_DIR ]]; then
    echo $OUTPUT_DIR "exsists"
else
    mkdir -p ${OUTPUT_DIR}
fi

if [[ -d $LOG_DIR ]]; then
    echo $LOG_DIR "exsists"
else
    mkdir ${LOG_DIR}
fi

while IFS='' read -r line || [[ -n "$line" ]]
do

    file=`echo "$line" | sed -e "s^ ^^g" -e "s^Day:.*^^g"`
#    DAY=`echo "$line" | sed -e "s^$file^^g" -e "s^ ^^g" -e "s^Day:^^g"`    

    if [[ -f $file ]]; then
	
	echo "Processing: $file"

	#Unpack file
	SPEC_OUTPUT_DIR=`mktemp -d $OUTPUT_DIR/XXXXXXXX`

	tar -xf $file -C $SPEC_OUTPUT_DIR
	RUN_NUMBER_OUTER=`echo $file | awk -v FS="(run_|.flat)" '{print $2}'`
	NEW_FILE=`ls $SPEC_OUTPUT_DIR/*.tar | head -n 1`
	tar -xf $NEW_FILE -C $SPEC_OUTPUT_DIR
#	chmod -R 664 $SPEC_OUTPUT_DIR/
	
	rm ${NEW_FILE}
	rm ${SPEC_OUTPUT_DIR}/*.xml

	RUN_DIR=`find $SPEC_OUTPUT_DIR/ -name run_*`
	RUN_NUMBER=`echo "$RUN_DIR" | sed -e "s^.*run_^^g" -e "s^/.*^^g"`
	echo $RUN_NUMBER
	echo $RUN_NUMBER >> $RUN_FILE_LIST
	LOGS=$RUN_DIR/logs
#	RUN_SIZE=`du -k -s $RUN_DIR | cut -f 1`
		
	if [ -f $LOGS/runStart* ] 
	then
	    DATE=`less $LOGS/runStart* | tr '\n' ' ' | sed -e "s^.*Time: ^^g" -e "s^Message:.*^^g"`
	    DATE_YEAR=`date -d @$DATE +"%Y"`
	    DATE_MONTH=`date -d @$DATE +"%m"`
	    DATE_DAY=`date -d @$DATE +"%d"`
	    RUN_DATE=${DATE_MONTH}${DATE_DAY}
	    if [ "$DATAYEAR" != "$DATE_YEAR" ]
	    then
		echo "Year does not match expected, look closer at: $file $DATAYEAR -> $DATE_YEAR"
		echo "$file $DATAYEAR -> $DATE_YEAR"  >> $YEAR_NOT_MATCH
	    fi
	else
	    RUN_DATE=`echo $file | awk -v FS="(SPS-ARA/|/SPS-ARA-RAW)" '{print $2}'`
	fi
	
	PEDFILE=`find $RUN_DIR -name pedestalValues*`
	if [ -f "$PEDFILE" ]
	then
	    if [ "$SWITCH10PER" = "0" ]
	    then
		if [ -d $PEDESTAL_OUTPUT_DIRECTORY ]
		then
		    echo "$PEDESTAL_OUTPUT_DIRECTORY exsists"
		else
		    mkdir -p $PEDESTAL_OUTPUT_DIRECTORY
		fi
		RUNSTART=`find $RUN_DIR -name runStart*`
		RUNSTOP=`find $RUN_DIR -name runStop*`
		RUNWIDTH=`find $RUN_DIR -name pedestalWidths*`
		RUNCONFIG=`find $RUN_DIR -name configFile*`
		mv $PEDFILE $PEDESTAL_OUTPUT_DIRECTORY/
		mv $RUNSTART $PEDESTAL_OUTPUT_DIRECTORY/
		mv $RUNSTOP $PEDESTAL_OUTPUT_DIRECTORY/
		mv $RUNCONFIG $PEDESTAL_OUTPUT_DIRECTORY/
		mv $RUNWIDTH $PEDESTAL_OUTPUT_DIRECTORY/
#		chmod 644 $PEDESTAL_OUTPUT_DIRECTORY/$PEDFILE
#		chmod 644 $PEDESTAL_OUTPUT_DIRECTORY/$RUNSTART
#		chmod 644 $PEDESTAL_OUTPUT_DIRECTORY/$RUNSTOP
#		chmod 644 $PEDESTAL_OUTPUT_DIRECTORY/$RUNWIDTH
#		chmod 644 $PEDESTAL_OUTPUT_DIRECTORY/$RUNCONFIG
#		chown $USER:ARA-cali $PEDESTAL_OUTPUT_DIRECTORY/$PEDFILE
#		chown $USER:ARA-cali $PEDESTAL_OUTPUT_DIRECTORY/$RUNSTART
#		chown $USER:ARA-cali $PEDESTAL_OUTPUT_DIRECTORY/$RUNSTOP
#		chown $USER:ARA-cali $PEDESTAL_OUTPUT_DIRECTORY/$RUNWIDTH
#		chown $USER:ARA-cali $PEDESTAL_OUTPUT_DIRECTORY/$RUNCONFIG
	    fi
	else

	    ROOT_DIR=${L1_DIR}/${RUN_DATE}/run${RUN_NUMBER}
	    
	    if [[ -d ${ROOT_DIR} ]]; then
		echo $ROOT_DIR "exists"
	    else
		mkdir -p ${ROOT_DIR}
	    fi
	    
	    EVENT_FILE=${ROOT_DIR}/event${RUN_NUMBER}.root
	    SENSOR_HK_FILE=${ROOT_DIR}/sensorHk${RUN_NUMBER}.root
	    EVENT_HK_FILE=${ROOT_DIR}/eventHk${RUN_NUMBER}.root
	    
	    echo "input: $file"
	    echo "output: $EVENT_FILE"
	    echo "outputsensorhk: $SENSOR_HK_FILE"
	    echo "outputeventhk: $EVENT_HK_FILE"
	    
	    if [ "$SWITCH10PER" = "1" ]
	    then
	 	
		EVENT_FILE_LIST=`mktemp event.XXXXXX`
		for event in ${RUN_DIR}/event/ev_*/*; 
		do
		    if [[ -f $event ]]; then
			echo $event >> ${EVENT_FILE_LIST}
		    fi
		done
		
		ONE_IN_TEN_DIR=${SPEC_OUTPUT_DIR}/OneInTen
		if [[ -d ${ONE_IN_TEN_DIR} ]]; then
		    echo ""
		else
		    echo "One in ten directory doesn't exist, making..."
		    mkdir -p ${ONE_IN_TEN_DIR}
		fi
		
		MONITOR_FILE=${LOG_DIR}/monitoringThis${RUN_NUMBER}.root
		
		if test `cat ${EVENT_FILE_LIST} | wc -l` -gt 0; then
		    ${RANDOM_FILTER_BIN} ${EVENT_FILE_LIST} ${ONE_IN_TEN_DIR} ${RUN_NUMBER} ${MONITOR_FILE} ${NUM_EVENTS} ${PED_FILE}
		    rm ${EVENT_FILE_LIST}
		    echo "Done event File"
		else
		    rm ${EVENT_FILE_LIST}
		    echo "No event Files"
		    echo $file "No event files 100" >> ${EVENT_ALL_FAILED}
		fi
		
		FILE_LIST=`mktemp event$RUN_NUMBER.XXXXXX`
		GZ_ONE_IN_TEN_DIR=`find $ONE_IN_TEN_DIR/ -name run_*`
		
		for eventfile in $GZ_ONE_IN_TEN_DIR/event/ev_*/*;
		do
		    if [[ -f $eventfile ]]; then
			echo $eventfile >> ${FILE_LIST}
		    fi
		done
	    
		OUT_DIR=${SPEC_OUTPUT_DIR}/Picked
	    
		if [[ -d ${OUT_DIR} ]]; then
		    echo ""
		else
		    echo "One in ten directory doesn't exist"
		    mkdir -p ${OUT_DIR}
		fi
		
		
		if test `cat ${FILE_LIST} | wc -l` -gt 0; then
		    ${ARA_EVENT_PICKER_BIN} ${FILE_LIST} ${OUT_DIR} ${RUN_NUMBER}
		    rm ${FILE_LIST}
		    echo "done event file"
		else
		    rm ${FILE_LIST}
		    echo "no event file"
		fi
		
		cp -rf ${RUN_DIR}/eventHk ${OUT_DIR}/run_${RUN_NUMBER}/
		cp -rf ${RUN_DIR}/sensorHk ${OUT_DIR}/run_${RUN_NUMBER}/
		cp -rf ${RUN_DIR}/monitorHk ${OUT_DIR}/run_${RUN_NUMBER}/
		cp -rf ${RUN_DIR}/logs ${OUT_DIR}/run_${RUN_NUMBER}/
		rm -rf ${RUN_DIR}
		RAW_DIR=${OUT_DIR}/run_${RUN_NUMBER}
		
	    else
		RAW_DIR=${RUN_DIR}
	    fi
	    
	    echo "Starting Event File"
	    EVENT_FILE_LIST=`mktemp event.XXXX`
	    for file in ${RAW_DIR}/event/ev_*/*; 
	    do
		if [[ -f $file ]]; then
		    echo $file >> ${EVENT_FILE_LIST}
		fi
	    done
	    
	    if [[ -f ${EVENT_FILE} ]]; then
		rm ${EVENT_FILE}
		echo "Removing preexistant ${EVENT_FILE}"
	    fi
	    
	    if [[ -f ${SENSOR_HK_FILE} ]]; then
		rm ${SENSOR_HK_FILE}
		echo "Removing preexistant ${SENSOR_HK_FILE}"
	    fi

	    if [[ -f ${EVENT_HK_FILE} ]]; then
		rm ${EVENT_HK_FILE}
		echo "Removing preexistant ${EVENT_HK_FILE}"
	    fi


	    if  test `cat ${EVENT_FILE_LIST} | wc -l` -gt 0 ; then
		${ARA_UTIL_INSTALL_DIR}/bin/makeAtriEventTree ${EVENT_FILE_LIST} ${EVENT_FILE} ${RUN_NUMBER}
		rm ${EVENT_FILE_LIST}
		echo "Done Event File"
	    else
		rm ${EVENT_FILE_LIST}
		echo "No event files"
		echo $file "No event files" >> ${EVENT_FAILED}
	    fi
	    
	    echo "Starting Sensor Hk File"
	    SENSOR_HK_FILE_LIST=`mktemp sensor.XXXX`
	    for file in ${RAW_DIR}/sensorHk/sensorHk_*/*; 
	    do
		if [[ -f $file ]]; then
		    echo $file >> ${SENSOR_HK_FILE_LIST}
		fi
	    done
	    
	    if  test `cat ${SENSOR_HK_FILE_LIST} | wc -l` -gt 0 ; then
		${ARA_UTIL_INSTALL_DIR}/bin/makeAtriSensorHkTree ${SENSOR_HK_FILE_LIST} ${SENSOR_HK_FILE} ${RUN_NUMBER}
		rm ${SENSOR_HK_FILE_LIST}
		echo "Done Sensor Hk File"
	    else
		rm ${SENSOR_HK_FILE_LIST}
		echo "No sensor hk files"
	    fi
	    
	    
	    echo "Starting Event Hk File"
	    EVENT_HK_FILE_LIST=`mktemp event.XXXX`
	    for file in ${RAW_DIR}/eventHk/eventHk_*/*; 
	    do
		if [[ -f $file ]]; then
		    echo $file >> ${EVENT_HK_FILE_LIST}
		fi
	    done
	    

	    if  test `cat ${EVENT_HK_FILE_LIST} | wc -l` -gt 0 ; then
		${ARA_UTIL_INSTALL_DIR}/bin/makeAtriEventHkTree ${EVENT_HK_FILE_LIST} ${EVENT_HK_FILE} ${RUN_NUMBER}
		rm ${EVENT_HK_FILE_LIST}
		echo "Done Event Hk File"
	    else
		rm ${EVENT_HK_FILE_LIST}
		echo "No event hk files"
	    fi
	    
	    echo "RUN NUMBER ............." ${RUN_NUMBER}

	    mv ${RAW_DIR}/logs/* ${ROOT_DIR}/
	    mv ${RAW_DIR}/monitorHk/* ${ROOT_DIR}/
	    chmod 775 ${ROOT_DIR}
	    chown $USER:ARA-filt ${ROOT_DIR}
	    chmod 775 ${ROOT_DIR}/*
	    chown $USER:ARA-filt ${ROOT_DIR}/*
	    
	    rm -rf ${SPEC_OUTPUT_DIR}
	    
	fi
	
    fi

done < "$TAR_FILES"

echo `date`
