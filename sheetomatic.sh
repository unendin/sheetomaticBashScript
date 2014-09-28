#!/bin/bash
#	sheetomatic.sh
#   App copies new run diaries (log files) to Google Drive folder
#   and launches Google Drive app
# 
# 	Launch from MATLAB with eg, unix(['/Users/yul/sheetomatic.sh'])

##########################
# CONFIGURE

# Google Drive app location
driveApp='/Applications/Google Drive.app'

# Google Drive app sync time, after which process is killed
driveSyncWindow=10

# Directory containing original logs
sourceDir='/Users/ted/Desktop/logs'

# Destination Google Drive directory
destinationDir='/Users/ted/Google Drive/logDest'

# Regex to match diary filenames only
regex='.*txt.*'

# Restrict to log files modified since last execution
if [ -f /tmp/sheetomatic.txt ]; then
    read modifiedSince < /tmp/sheetomatic.txt
    echo "Last execution time: $modifiedSince."
# In the absence of stored execution date, restrict search to files 
# modified within last 24hr
else
    modifiedSince="$(date  -v-1d "+%Y%m%d%H%M.%S")"
    echo "No record of previous execution time. Copying logs modified since: $modifiedSince"
fi

##########################
# COPY TO DRIVE FOLDER 

# Set date range for file search
touch -t "$modifiedSince" /tmp/logTimestamp

# Find and copy relevant log files
find "$sourceDir" -newer /tmp/logTimestamp -regex "$regex" -exec cp {} "$destinationDir" \;

##########################
# REPORT 

# Display copied filenames  
find "$destinationDir" -newer /tmp/logTimestamp -regex "$regex"

# Persist time of execution to restrict further copies to new files
modifiedSince="$(date "+%Y%m%d%H%M.%S")"
echo $modifiedSince > /tmp/sheetomatic.txt


##########################
# SYNC W/GOOGLE

# If files are copied, start Google Drive app, wait, then quit
if [[ -n $(find "$destinationDir" -newer /tmp/logTimestamp -regex "$regex") ]]; then
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

