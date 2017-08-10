#!/bin/bash

DATAYEAR=2016 # data year
SWITCH10PER=0  # switch for 10 percent processing: 0: Full (blinded)   1: 10 percent (unblinded)
STATIONNUM=01 # station number, make sure to have leading zero if applicable

# END_DIR: where product L1 files will go
if [ $SWITCH10PER -eq 0 ] 
then
    END_DIR=/data/exp/ARA/${DATAYEAR}/blinded/L1/ARA${STATIONNUM} 
else
    END_DIR=/data/exp/ARA/${DATAYEAR}/unblinded/L1/ARA${STATIONNUM} 
fi

CONVENTION=SPS-ARA-RAW.ARA${STATIONNUM}.run #Beginning of raw files to process (for searching)
PEDESTAL_OUTPUT_DIRECTORY=/data/exp/ARA/${DATAYEAR}/calibration/pedestals/ARA${STATIONNUM} # Where pedestal files should go
DATASTORE=/data/exp/ARA/${DATAYEAR}/unbiased/SPS-ARA #where raw data is located
