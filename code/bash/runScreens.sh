#!/bin/bash


################MANUAL USAGE OPTIONS################
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--h" ] || [ "$1" == "--help" ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [[ ! "$4" =~ ^(delete|continue)$ ]] ; then
  printf "\nUsage: $(basename $0) executes an order for a specified number of screens.\nThe placeholder to change dinamically the output name is \`screencode\`. \nThe fourth input is to specifiy what to do if the screen already exists: \`delete\` or \`continue\`. \nATTENTION: If \`delete\` is selected, ALL screens with that name will be terminated.\n\n\tExample: bash runScreens.sh 10 screenID 'ls > test_screencode.txt' delete\n\n"
  printf "Your variables were:\nScreens: ${1}\nScreenID:${2}\nMessage:${3}\nOldScreen:${4}"
  exit 0
fi

SCREENS=$1
SCREENID=$2
MESSAGE=$3
OLDSCREEN=$4

# For each screen number, make a screen and execute the order
for SCREEN in $(seq -f "%02g" 1 $SCREENS)  ; do 
	# DELETE: If the screen exists and we want to delete it
	if  screen -list | grep -q "${SCREENID}_${SCREEN}"  && [ "${OLDSCREEN}" == "delete" ]  ; then
		screen -ls | grep "${SCREENID}_${SCREEN}" | awk '{ print $1; }' | xargs -I {} -n 1 screen -S {} -X quit

	fi

	# # CREATE: If the screen does not exist or is not continue
	if   ! screen -list | grep -q "${SCREENID}_${SCREEN}"  || [ "${OLDSCREEN}" != "continue" ] ; then
		screen -dmS ${SCREENID}_${SCREEN} sh
	fi

	# RUN:Once the corrent screen is connected
	ORDER=${MESSAGE/screencode/$SCREEN}

	echo "${SCREEN}:${ORDER}"
	sleep 2
	screen -S ${SCREENID}_${SCREEN} -X stuff "${ORDER} ${SCREEN}
	exit
 	"

done




