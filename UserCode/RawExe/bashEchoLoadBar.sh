#!/bin/bash

asRed='\033[37m\033[41m'
asGreen='\033[42m'
asBlue="\033[37m\033[44m"
asPurple="\033[37m\033[45m"
asCyan="\033[46m\033[43m"
asBlack="\033[37m\033[40m"

startTime=`date +%s%N | cut -b1-13`
firstPrint=0

echoload() {

    if [ -t 1 ]; then
	nlin=$(tput lines)
	colLen=`awk "BEGIN{ printf $(tput cols)-7 }"`
	per=`awk "BEGIN{ printf (${1}/100.0)*$colLen  }" | cut -c 1-4` ; ndots=`echo "$per" | awk -v FS='.' '{printf $1}'`
	per2=`echo "$1" | cut -c 1-5`;mess=`printf "%5s[" "$per2"`;mess+="$asGreen";for i in `seq 1 1 $ndots` ; do mess+=" " ; done 
	mess+="$asRed";mndots=`awk "BEGIN{ printf $colLen-1 }"`;for i in `seq $ndots 1 $mndots` ; do mess+=" " ; done
	printf "\033[s\033[$nlin;0H\033[K\033[u"
	if [ $# -eq 2 ] ; then printf "$2\n" ; fi
	if [ $# -eq 3 ] ; then printf "$2$3\033[0m\n" ; fi
	if [ $per2 == 100 ];then printf "\033[$nlin;0H${mess}\033[0m]\n";else printf "\033[s\033[$nlin;0H${mess}\033[0m]\033[u";fi
    fi
}

: <<'Block'


echoloadTime() {

    if [ -t 1 ]; then
	currTime=`date +%s%N | cut -b1-13`
	nlin=$(tput lines)
	nlinm1=`awk "BEGIN{ printf $nlin-1}"`
	colLen=`awk "BEGIN{ printf $(tput cols)-7 }"`
	per=`awk "BEGIN{ printf (${1}/100.0)*$colLen  }" | cut -c 1-4` ; ndots=`echo "$per" | awk -v FS='.' '{printf $1}'`
	per2=`echo "$1" | cut -c 1-5`;mess=`printf "%5s[" "$per2"`;mess+="$asGreen";for i in `seq 1 1 $ndots` ; do mess+=" " ; done 
	mess+="$asRed";mndots=`awk "BEGIN{ printf $colLen-1 }"`;for i in `seq $ndots 1 $mndots` ; do mess+=" " ; done
	if [ "$firstPrint" == 1 ]
	then
	    printf "\033[s\033[$nlinm1;0H\033[K\033[u"
	    printf "\033[s\033[$nlin;0H\033[K\033[u"
	else 
	    firstPrint=1
	fi
	if [ $# -eq 2 ] ; then printf "$2\n" ; fi
	if [ $# -eq 3 ] ; then printf "$2$3\033[0m\n" ; fi
	estTime=`awk "BEGIN{ printf ($currTime-$startTime)/1000 }"`
	if [ $per2 == 100 ];then printf "\033[$nlin;0H${mess}\033[0m]\n";else printf "\033[s\033[$nlinm1;0H${mess}\033[0m]\n";fi
	printf "\033[$nlin;0H$estTime sec\033[u"
    fi
}
Block

echoloadTime() {

    if [ -t 1 ]; then
	currTime=`date +%s%N | cut -b1-13`
	nlin=$(tput lines)
	nlinm1=`awk "BEGIN{ printf $nlin-1}"`
	colLen=`awk "BEGIN{ printf $(tput cols)-7 }"`
	per=`awk "BEGIN{ printf (${1}/100.0)*$colLen  }" | cut -c 1-4` ; ndots=`echo "$per" | awk -v FS='.' '{printf $1}'`
	per2=`echo "$1" | cut -c 1-5`;mess=`printf "%5s[" "$per2"`;mess+="$asGreen";for i in `seq 1 1 $ndots` ; do mess+=" " ; done 
	mess+="$asRed";mndots=`awk "BEGIN{ printf $colLen-1 }"`;for i in `seq $ndots 1 $mndots` ; do mess+=" " ; done

	if [ "$firstPrint" == 1 ]
	then
	    printf "\033[2K"
	    printf "\033[1A\033[2K"
	else
	    firstPrint=1
	    printf "\033[$nlin;0H\n\033[1A\033[1A"
	fi

	if [ $# -eq 2 ] ; then printf "\n\n\033[1A\033[1A$2\n" ; fi
	if [ $# -eq 3 ] ; then printf "\n\n\033[1A\033[1A$2$3\033[0m\n" ; fi

	estTime=`awk "BEGIN{ printf ($currTime-$startTime)/1000 }"`
	if [ $per2 == 100 ];then 
	    printf "\033[$nlin;0H${mess}\033[0m]\n"
	    printf "\033[$nlin;0H$estTime sec"
	else
	    estTime=`awk "BEGIN{ printf $estTime*(1.0-(${1}/100.0))/(${1}/100.0)}"`
	    printf "\033[$nlinm1;0H${mess}\033[0m]\n"
	    printf "\033[$nlin;0H$estTime sec"
	fi
    fi
}
