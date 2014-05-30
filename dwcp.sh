#!/bin/bash - 
#===============================================================================
#
#          FILE: dwcp.sh
# 
#         USAGE: ./dwcp.sh 
# 
#   DESCRIPTION: Control Panel for a minecraft/direwolf20 Server
# 
#       OPTIONS: ---
#  REQUIREMENTS: screen, java, rlwrap
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Robin Cerny (rc), tschaerni@gmail.com
#  ORGANIZATION: private
#       CREATED: 29.11.2013 04:15:59 CET
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

#trap "kill -TERM -$$" INT

# Settings
MAXMEMORY='14G'
MINMEMORY='14G'
SERVICE='mcpc.jar'
BACKUPHISTORY=3
#=================================================================================================
BASEDIR=$(dirname `readlink -f $0`)
SCREENSESSION=direwolf
TIMESTAMP=$(date '+%b_%d_%Y_%H.%M.%S')
#=================================================================================================
dw_start(){

	screen -wipe

	if ps aux | grep $SERVICE | grep -v grep | grep -v tee | grep -v rlwrap >/dev/null
	then

		echo "Tried to start but $SERVICE was already running!"

	else

		echo "$SERVICE was not running... starting."
		cd $BASEDIR

		if [ ! -d "$BASEDIR/logs" ]
		then
			echo "No logs directory detected creating for logging"
			mkdir $BASEDIR/logs
		fi

		if [ -e $BASEDIR/logs/output.log ]
		then
			MOVELOG=$BASEDIR/logs/output_$TIMESTAMP.log
			mv $BASEDIR/logs/output.log $MOVELOG
		fi

		screen -dmS $SCREENSESSION -m sh -c "ionice -c2 -n0 nice -n -10 rlwrap java -Xmx$MAXMEMORY -Xms$MINMEMORY -XX:PermSize=256M -XX:MaxPermSize=512M -XX:UseSSE=4 -XX:ParallelGCThreads=8 -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection -XX:+UseParNewGC -XX:+DisableExplicitGC -XX:+AggressiveOpts -d64 -jar $SERVICE nogui 2>&1 | tee $BASEDIR/logs/output.log"
		
		sleep 7
		if ps aux | grep $SERVICE | grep -v grep | grep -v tee | grep -v rlwrap >/dev/null
		then
			echo "$SERVICE is now running."
		else
			echo "Could not start $SERVICE."
		fi
	fi
}
#=================================================================================================
dw_stop(){
	if ps aux | grep $SERVICE | grep -v grep | grep -v tee | grep -v rlwrap >/dev/null
	then
		echo "$SERVICE is running... stopping."
		screen -S $SCREENSESSION -p 0 -X stuff "say stop in 5 Min.!$(printf \\r)"
		echo "$SERVICE is stopping in 5min"
		sleep 60
		screen -S $SCREENSESSION -p 0 -X stuff "say stop in 4 Min.!$(printf \\r)"
		echo "$SERVICE is stopping in 4min"
		sleep 60
		screen -S $SCREENSESSION -p 0 -X stuff "say stop in 3 Min.!$(printf \\r)"
		echo "$SERVICE is stopping in 3min"
		sleep 60
		screen -S $SCREENSESSION -p 0 -X stuff "say stop in 2 Min.!$(printf \\r)"
		echo "$SERVICE is stopping in 2min"
		sleep 60
		screen -S $SCREENSESSION -p 0 -X stuff "say stop in 1 Min.!$(printf \\r)"
		echo "$SERVICE is stopping in 1min"
		sleep 30
		screen -S $SCREENSESSION -p 0 -X stuff "say stop in 30 Sec.!$(printf \\r)"
		echo "$SERVICE is stopping in 30sec"
		sleep 25
		screen -S $SCREENSESSION -p 0 -X stuff "say stop in 5sec.!$(printf \\r)"
		sleep 5
		screen -S $SCREENSESSION -p 0 -X stuff "kickall Server shutdown!$(printf \\r)"
		sleep 2
		screen -S $SCREENSESSION -p 0 -X stuff "save-all$(printf \\r)"
		echo "Saving Database"
		sleep 10
		screen -S $SCREENSESSION -p 0 -X stuff "stop$(printf \\r)"
		sleep 60
		
		if ps aux | grep $SERVICE | grep -v grep | grep -v tee | grep -v rlwrap >/dev/null
		then
			PID=$(ps aux | grep -v grep | grep $SERVICE | grep -v tee | grep -v rlwrap | awk '{print $2}')
			kill $PID
			sleep 30

			if ps aux | grep $SERVICE | grep -v grep | grep -v tee | grep -v rlwrap >/dev/null
			then
				PID=$(ps aux | grep -v grep | grep $SERVICE | grep -v tee | grep -v rlwrap | awk '{print $2}')
				kill -9 $PID
				screen -wipe
			fi
		fi
	else
		echo "$SERVICE not running"
	fi
}
#=================================================================================================
dw_backup(){
	if [ ! -d "$BASEDIR/backup" ]
	then
		mkdir $BASEDIR/backup
	fi

	if ps aux | grep $SERVICE | grep -v grep | grep -v tee | grep -v rlwrap >/dev/null
	then
		echo "$SERVICE is running. Beginning Backup..."
		screen -S $SCREENSESSION -p 0 -X stuff "say §3Start backupprocess$(printf \\r)"
		screen -S $SCREENSESSION -p 0 -X stuff "save-off$(printf \\r)"
		screen -S $SCREENSESSION -p 0 -X stuff "save-all$(printf \\r)"
		sleep 5
		# sync to prevent caching of the database
		sync
		sleep 5
		zip -r $BASEDIR/backup/fuyb_backup_$TIMESTAMP.zip $BASEDIR/FeedUpYourBeast
		if [ "$?" == "0" ]
		then
			screen -S $SCREENSESSION -p 0 -X stuff "say §3Backup successfully.$(printf \\r)"
			echo "Backup successfully."
		else
			screen -S $SCREENSESSION -p 0 -X stuff "say §3Backup going wrong, please check.$(printf \\r)"
			echo "Backup going wrong, please check."
		fi
		screen -S $SCREENSESSION -p 0 -X stuff "save-on$(printf \\r)"
		echo "Deleting following:"
		echo $(find $BASEDIR/backup -type d -mtime +$BACKUPHISTORY)
		echo "Deleting old backups"
		find $BASEDIR/backup -type d -mtime +$BACKUPHISTORY | grep -v -x "$BASEDIR/backup" | xargs rm -rf
	else

		echo "$SERVICE is not running. Starting offline backup..."
		zip -r $BASEDIR/backup/fuyb_backup_$TIMESTAMP.zip $BASEDIR/FeedUpYourBeast
		if [ "$?" == "0" ]
		then
			echo "Backup successfully."
		else
			echo "Backup going wrong, please check."
		fi
	fi
}
#=================================================================================================
dialog_menu(){
	dialog --backtitle "DWCP - Direwolf Control Panel" --title " Server Managment "\
		--menu "Move using [UP] and [DOWN], [ENTER] to select" 16 60 9\
		start "Start the direwolf server"\
		stop "Stop the direwolf server"\
		restart "Restart the direwolf server"\
		status "Retrieves the status of the server"\
		check "check the server for deadlock"\
		backup "make a on- or offline backup"\
		console "go to the Java console"\
		help "usage page"\
		exit "close the DWCP" 3>&1 1>&2 2>&3
}


#=================================================================================================
if [ "$1" = "" ]
then
	clear

	echo -e "


                                                              
                 @@@@@@@   @@@  @@@  @@@   @@@@@@@  @@@@@@@   
                 @@@@@@@@  @@@  @@@  @@@  @@@@@@@@  @@@@@@@@  
                 @@!  @@@  @@!  @@!  @@!  !@@       @@!  @@@  
                 !@!  @!@  !@!  !@!  !@!  !@!       !@!  @!@  
                 @!@  !@!  @!!  !!@  @!@  !@!       @!@@!@!   
                 !@!  !!!  !@!  !!!  !@!  !!!       !!@!!!    
                 !!:  !!!  !!:  !!:  !!:  :!!       !!:       
                 :!:  !:!  :!:  :!:  :!:  :!:       :!:       
                  :::: ::   :::: :: :::    ::: :::   ::       
                 :: :  :     :: :  : :     :: :: :   :        
                                                              


                      The famous control panel for n00bs

                                 by \e[31mZ\e[34modiak\e[0m
                                                      
"
	sleep 5
	clear
	#dialog_menu
	dialog_menu_answer=$(dialog_menu)

	opt=${?}
	if [ $opt != 0 ]
	then
		clear
		exit 0
	fi
else
	dialog_menu_answer="$1"
fi
#================================================================================================
	
	case $dialog_menu_answer in

		start)
			if [ "$1" = "" ]
			then
				clear
			fi
			dw_start
		;;

		stop)
			if [ "$1" = "" ]
			then
				clear
			fi
			dw_stop
		;;

		restart)
			if [ "$1" = "" ]
			then
				clear
			fi
			dw_stop
			sleep 1
			dw_start
		;;

		status)
			if [ "$1" = "" ]
			then
				clear
				if ps aux | grep $SERVICE | grep -v grep | grep -v tee | grep -v rlwrap >/dev/null
				then
					dialog --backtitle "DWCP - Direwolf Control Panel" --msgbox\
						"$SERVICE is running" 5 24
				else
					dialog --backtitle "DWCP - Direwolf Control Panel" --msgbox\
						"$SERVICE not running" 5 24
				fi
			fi
		;;

		check)
			if [ "$1" = "" ]
			then
				clear
			else
				clear
				exit 1
			fi

			ANSWER=0

			while [ "$ANSWER" = "0" ] ; do

				#NUMOFLINES=$(wc -l $BASEDIR/logs/output.log | cut -d" " -f1)
				#if [ -z "$LINESTART" ]
				#then
					#LINESTART=1
				#fi

				#if [ "$NUMOFLINES" -gt "$LINESTART" ]
				#then
					#LOGSTRING=$(awk "NR==$LINESTART, NR==$NUMOFLINES" $BASEDIR/logs/output.log)
					#LINESTART=$((NUMOFLINES+1))
				#fi

				if ps aux | grep $SERVICE | grep -v grep | grep -v tee | grep -v rlwrap >/dev/null
				then
					screen -S $SCREENSESSION -p 0 -X stuff "ping$(printf \\r)"
				else
					dialog --backtitle "DWCP - Direwolf Control Panel" --msgbox\
						"$SERVICE not running" 5 25
				fi

				sleep 0.5
				if grep "\[INFO\] Pong\!" $BASEDIR/logs/output.log >/dev/null
				then
					dialog --backtitle "DWCP - Direwolf Control Panel" --msgbox\
						"$SERVICE is running and Responsive" 5 67
					MOVELOG=$BASEDIR/logs/output_$TIMESTAMP.log
					cp $BASEDIR/logs/output.log $MOVELOG
					echo "" > $BASEDIR/logs/output.log
					break
				else
					dialog --backtitle "DWCP - Direwolf Control Panel" --yesno "$SERVICE is currently not responsive, wait 5sec?" 0 0
					ANSWER=$?
					sleep 5
				fi
			done
		;;

		backup)
			if [ "$1" = "" ]
			then
				clear
			fi
			dw_backup
		;;

		console)
			if [ "$1" = "" ]
			then
				if ps aux | grep $SERVICE | grep -v grep | grep -v tee | grep -v rlwrap >/dev/null
				then
					dialog --backtitle "DWCP - Direwolf Control Panel" --msgbox\
						"for return, press and hold the buttons [CTRL LEFT], [A] and [D]" 5 67
					screen -rx $SCREENSESSION
				else
					dialog --backtitle "DWCP - Direwolf Control Panel" --msgbox\
						"$SERVICE not running" 5 25
				fi
				clear
			else
				exit 1
			fi
		;;

		compresslog)
			zip -r -j $BASEDIR/logs/serverlog.zip $BASEDIR/logs/output_*.log && rm $BASEDIR/logs/output_*.log
		;;

		help|*)
			# some usage informations
			if [ "$1" = "" ]
			then
				exit 1
			fi
		;;

		exit)
			exit 0
		;;
esac

exit 0
# EOF
