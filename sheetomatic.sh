#!/bin/bash
# sheetomatic.sh
#
# App copies new run diaries (log files) to Google Drive folder
# and launches (then kills) Google Drive app
# 
# Launch from MATLAB with eg, 
# unix(['/Users/yul/Google\ Drive/sheetomaticBashScript/sheetomatic.sh'])

scriptName=$0
function usage {
    echo "usage: $scriptName [-t]"
    echo "	-t		use test settings"
    exit 1
}

##########################
# CONFIGURE

# Current user environment for purposes of defining directories
user="$(echo $USER)"

# PRODUCTION settings. Default when no argument passed to script
if [ -z "$1" ]; then
	# Google Drive app sync time (in seconds), after which process is killed
	driveSyncWindow=120	

	# Destination Google Drive directory
	destinationDir="/Users/$user/Google Drive/logs"

	# Restrict to log files modified since last execution
	if [ -f /tmp/sheetomatic.txt ]; then
		read modifiedSince < /tmp/sheetomatic.txt
		echo "Previous execution time: $modifiedSince."

	# In the absence of stored execution date, restrict search to files 
	# modified within last 24hr
	else
		modifiedSince="$(date  -v-1d "+%Y%m%d%H%M.%S")"
		echo "No record of previous execution time. Copying logs modified since: $modifiedSince"
	fi

# TEST settings. Invoked by -t argument
elif [ $1 == "-t" ]; then
	echo "TESTING TESTING TESTING"

	# Short time before quitting drive app
	driveSyncWindow=10

	# Destination Google Drive directory
	destinationDir="/Users/$user/Google Drive/logsTest"

	# Artificially set modified date back
	modifiedSince="$(date  -v-5d "+%Y%m%d%H%M.%S")"
	echo "Last execution time set to 5 days ago: $modifiedSince."

# EXIT if unexpected argument passed
else 
	echo "Argument $1 not recognized."	
	usage
fi

# UNIVERSAL settings
# Google Drive app location
driveApp='/Applications/Google Drive.app'

# Directory containing original logs
sourceDir="/Users/$user/Dropbox/CodeNData/Data/Shadlen/+MDD/+expr"

# Regexes to match diary filenames only and exclude json variants.
# Note: 'find' command does not support lookbehind to do both regexes in one
regex='.*diary_.*.txt'
notRegex='.*diary_.*json.txt' 

##########################
# COPY NEW DIARIES TO DRIVE FOLDER 

# Set date range for file search
touch -t "$modifiedSince" /tmp/logTimestamp

# Find and copy relevant log files. 
# Play safe with -n to prevent overwrites
find "$sourceDir" -newer /tmp/logTimestamp -not -regex "$notRegex" -regex "$regex" -exec cp -n {} "$destinationDir" \;  

# for terminal display TODO: non-redundant
find "$sourceDir" -newer /tmp/logTimestamp -not -regex "$notRegex" -regex "$regex" 

##########################
# STORE STATE 

# Persist time of execution to restrict subsequent copies to new files
modifiedSince="$(date "+%Y%m%d%H%M.%S")"
echo $modifiedSince > /tmp/sheetomatic.txt


##########################
# SYNC W/GOOGLE

# If files were found, start Google Drive app, wait, then quit TODO: robustify
if [[ -n $(find "$sourceDir" -newer /tmp/logTimestamp -not -regex "$notRegex" -regex "$regex") ]]; then
	echo "Launching Google Drive App ..."
	open -a "$driveApp"
	echo "Waiting $driveSyncWindow seconds for Google Drive to sync ..."	
	sleep $driveSyncWindow
	echo "Quitting Google Drive	..."	
	osascript -e 'tell application "Google Drive" to quit'
	echo "Done"
else
    printf "No new log files.\nExiting without launching Google Drive\n"
fi

