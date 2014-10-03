#!/bin/bash
# sheetomatic.sh
#
# App copies new run diaries (log files) to Google Drive folder
# and launches (then kills) Google Drive app
# 
# Launch from MATLAB with eg, 
# unix(['/Users/yul/Google\ Drive/sheetomaticBashScript/sheetomatic.sh'])

##############################################################################
# USAGE

scriptName=$0
function usage {
    echo "usage: $scriptName [Int] [noSync] ["
    echo "	Int		How far back to look for log files (in number of days)"
    echo "	noSync  Do not launch Google Drive app. Must be used with Int or blank first argumnent, eg, sheetomatic \"\" noSync"
    exit 1
}

##############################################################################
# CONFIGURATION
# Current user environment for purposes of defining directories
user="$(echo $USER)"

# Directory containing original logs
sourceDir="/Users/$user/Dropbox/CodeNData/Data/Shadlen/+MDD/+expr"

# Regexes to match diary filenames only and exclude json variants.
# Note: 'find' command does not support lookbehind to do both regexes in one
regex='.*diary_.*.txt'
notRegex='.*diary_.*json.txt'

# Destination Google Drive directory
destinationDir="/Users/$user/Google Drive/logs"

# Google Drive app location
driveApp='/Applications/Google Drive.app'

# Google Drive app sync time (in seconds), after which process is killed
driveSyncWindow=120	


##############################################################################
# Handle unrecognized argumnets

# Handle unrecognized time argument
if [[ -n "$1"  &&  ! "$1" -gt "0" ]]; then
	echo "Argument $1 not recognized."
	usage	
# Handle unrecognized NoSync argument
elif [[ -n "$2" && ! "$2" == "noSync" ]]; then
	echo "Argument $2 not recognized."
	usage	
fi



##############################################################################
# RESTRICT TIME RANGE FOR LOG FILES OF INTEREST 
# Current user environment for purposes of defining directories

# Use number of days specified in command argument
if [ "$1" -gt "0" ]; then	
	# Artificially set modified date back
	modifiedSince="$(date  -v-"$1"d "+%Y%m%d%H%M.%S")"
	printf  "Looking for logs modified in last "$1" days ...\n"

# By default restrict to log files modified since last execution
elif [ -f /tmp/sheetomatic ]; then
	read modifiedSince < /tmp/sheetomatic
	printf "Previous execution time: $modifiedSince.\nLooking for log files modified since previous execution ...\n" # TODO: pretty date

# In the absence of stored execution date, restrict search to files 
# modified within last 24hr
else
	modifiedSince="$(date  -v-1d "+%Y%m%d%H%M.%S")"
	printf "No record of previous execution time.\nLooking logs modified since: $modifiedSince\n"
fi


##############################################################################
# COPY DIARIES TO DRIVE FOLDER 

# Set date range for file search
touch -t "$modifiedSince" /tmp/sheetomaticTimestamp

# Find and copy relevant log files. 
# Play safe with -n to prevent overwrites
find "$sourceDir" -newer /tmp/sheetomaticTimestamp -not -regex "$notRegex" -regex "$regex" | xargs -I {} cp -v {} "$destinationDir" | tee /tmp/sheetomaticLog

# Check if new files present in destination dir
read sheetomaticLog < /tmp/sheetomaticLog
if [[ $sheetomaticLog =~ .*\-\>.* ]] ; then
	logsCopied="true"
fi


##############################################################################
# STORE EXECUTION TIME 

# Persist time of execution to restrict subsequent copies to new files
modifiedSince="$(date "+%Y%m%d%H%M.%S")"
echo $modifiedSince > /tmp/sheetomatic


##############################################################################
# SYNC W/GOOGLE

if [ "$logsCopied" != "true" ]; then
    printf "No new log files to copy.\nExiting without launching Google Drive."

# Handle NoSync argument
elif [[ $2 == "noSync" ]]; then	
	printf  "Option set to noSync.\nFinishing without launching Google Drive.\n"

# If new files in Google Drive directory, start Google Drive app, wait, then quit TODO: robustify
else
	echo "Launching Google Drive App ..."
	open -a "$driveApp"
	echo "Waiting $driveSyncWindow seconds for Google Drive to sync ..."	
	sleep $driveSyncWindow
	echo "Quitting Google Drive	..."	
	osascript -e 'tell application "Google Drive" to quit'
	echo "Done."
fi

