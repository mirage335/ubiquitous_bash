#!/usr/bin/env bash

#####Utilities

#Run command and output to terminal with colorful formatting. Controlled variant of "bash -v".
_showCommand() {
	echo -e '\E[1;32;46m $ '"$1"' \E[0m'
	"$@"
}

#Retrieves absolute path of current script, while maintaining symlinks, even when "./" would translate with "readlink -f" into something disregarding symlinked components in $PWD.
#However, will dereference symlinks IF the script location itself is a symlink. This is to allow symlinking to scripts to function normally.
#Suitable for allowing scripts to find other scripts they depend on. May look like an ugly hack, but it has proven reliable over the years.
_getScriptAbsoluteLocation() {
	local absoluteLocation
	if [[ (-e $PWD\/$0) && ($0 != "") ]] && [[ "$1" != "/"* ]]
			then
	absoluteLocation="$PWD"\/"$0"
	absoluteLocation=$(realpath -L -s "$absoluteLocation")
			else
	absoluteLocation=$(realpath -L "$0")
	fi

	if [[ -h "$absoluteLocation" ]]
			then
	absoluteLocation=$(readlink -f "$absoluteLocation")
	absoluteLocation=$(realpath -L "$absoluteLocation")
	fi
	echo $absoluteLocation
}
alias getScriptAbsoluteLocation=_getScriptAbsoluteLocation

#Retrieves absolute path of current script, while maintaining symlinks, even when "./" would translate with "readlink -f" into something disregarding symlinked components in $PWD.
#Suitable for allowing scripts to find other scripts they depend on.
_getScriptAbsoluteFolder() {
	dirname "$(_getScriptAbsoluteLocation)"
}
alias getScriptAbsoluteFolder=_getScriptAbsoluteFolder

#Retrieves absolute path of parameter, while maintaining symlinks, even when "./" would translate with "readlink -f" into something disregarding symlinked components in $PWD.
#Suitable for finding absolute paths, when it is desirable not to interfere with symlink specified folder structure.
_getAbsoluteLocation() {
	if [[ "$1" == "" ]]
	then
		echo
		return
	fi
	
	local absoluteLocation
	if [[ (-e $PWD\/$1) && ($1 != "") ]] && [[ "$1" != "/"* ]]
			then
	absoluteLocation="$PWD"\/"$1"
	absoluteLocation=$(realpath -L -s "$absoluteLocation")
			else
	absoluteLocation=$(realpath -L "$1")
	fi
	echo $absoluteLocation
}
alias getAbsoluteLocation=_getAbsoluteLocation

#Retrieves absolute path of parameter, while maintaining symlinks, even when "./" would translate with "readlink -f" into something disregarding symlinked components in $PWD.
#Suitable for finding absolute paths, when it is desirable not to interfere with symlink specified folder structure.
_getAbsoluteFolder() {
	local absoluteLocation=$(_getAbsoluteLocation "$1")
	dirname "$absoluteLocation"
}
alias getAbsoluteLocation=_getAbsoluteLocation

#Reports either the directory provided, or the directory of the file provided.
_findDir() {
	local dirIn=$(_getAbsoluteLocation "$1")
	dirInLogical=$(realpath -L -s "$dirIn")
	
	if [[ -d "$dirInLogical" ]]
	then
		echo "$dirInLogical"
		return
	fi
	
	echo $(_getAbsoluteFolder "$dirInLogical")
	return
	
}

#Checks whether command or function is available.
# WARNING Needed by safeRMR .
_checkDep() {
	if ! type "$1" >/dev/null 2>&1
	then
		echo "$1" missing
		_stop 1
	fi
}

_tryExec() {
	type "$1" >/dev/null 2>&1 && "$1"
}

#Portable sanity checked "rm -r" command.
# WARNING Not foolproof. Use to guard against systematic errors, not carelessness.
#"$1" == directory to remove
_safeRMR() {
	
	#if [[ ! -e "$0" ]]
	#then
	#	return 1
	#fi
	
	if [[ "$1" == "" ]]
	then
		return 1
	fi
	
	if [[ "$1" == "/" ]]
	then
		return 1
	fi
	
	#Blacklist.
	[[ "$1" == "/home" ]] && return 1
	[[ "$1" == "/home/" ]] && return 1
	[[ "$1" == "/home/$USER" ]] && return 1
	[[ "$1" == "/home/$USER/" ]] && return 1
	[[ "$1" == "/$USER" ]] && return 1
	[[ "$1" == "/$USER/" ]] && return 1
	
	[[ "$1" == "/tmp" ]] && return 1
	[[ "$1" == "/tmp/" ]] && return 1
	
	[[ "$1" == "$HOME" ]] && return 1
	[[ "$1" == "$HOME/" ]] && return 1
	
	#Whitelist.
	local safeToRM=false
	
	local safeScriptAbsoluteFolder="$_getScriptAbsoluteFolder"
	
	[[ "$1" == "./"* ]] && [[ "$PWD" == "$safeScriptAbsoluteFolder"* ]] && safeToRM="true"
	
	[[ "$1" == "$safeScriptAbsoluteFolder"* ]] && safeToRM="true"
	
	#[[ "$1" == "/home/$USER"* ]] && safeToRM="true"
	[[ "$1" == "/tmp/"* ]] && safeToRM="true"
	
	[[ "$safeToRM" == "false" ]] && return 1
	
	#Safeguards/
	[[ -d "$1" ]] && find "$1" | grep -i '\.git$' >/dev/null 2>&1 && return 1
	
	#Validate necessary tools were available for path building and checks.
	_checkDep realpath
	_checkDep readlink
	_checkDep dirname
	_checkDep basename
	
	if [[ -e "$1" ]]
	then
		#sleep 0
		#echo "$1"
		# WARNING Recommend against adding any non-portable flags.
		rm -rf "$1"
	fi
}

_discoverResource() {
	local testDir
	local scriptAbsoluteFolder
	scriptAbsoluteFolder=$(_getScriptAbsoluteFolder)
	testDir="$scriptAbsoluteFolder" ; [[ -e "$testDir"/"$1" ]] && echo "$testDir"/"$1" && return
	testDir="$scriptAbsoluteFolder"/.. ; [[ -e "$testDir"/"$1" ]] && echo "$testDir"/"$1" && return
	testDir="$scriptAbsoluteFolder"/../.. ; [[ -e "$testDir"/"$1" ]] && echo "$testDir"/"$1" && return
	testDir="$scriptAbsoluteFolder"/../../.. ; [[ -e "$testDir"/"$1" ]] && echo "$testDir"/"$1" && return
}

#"$1" == test directory
#"$2" == flag file
_flagMount() {
	# TODO: Possible stability/portability improvements.
	#https://unix.stackexchange.com/questions/248472/finding-mount-points-with-the-find-command
	
	mountpoint "$1" >/dev/null 2>&1 && echo -n true > "$2"
}

#End user function, typically used to ensure no mounted filesystems are present before deleting a directory.
#"$1" == test directory
_checkForMounts() {
	_start
	
	local mountCheckFile="$safeTmp"/mc-$(_uid)
	
	echo -n false > "$mountCheckFile"
	
	#Sanity check, file exists.
	! [[ -e "$mountCheckFile" ]] && _stop 0
	
	# TODO: Possible stability/portability improvements.
	#https://unix.stackexchange.com/questions/248472/finding-mount-points-with-the-find-command
	
	find "$1" -type d -exec mountpoint {} 2>/dev/null \; | grep 'is a mountpoint' >/dev/null 2>&1 && echo -n true > "$mountCheckFile"
	
	#find "$1" -type d -exec "$scriptAbsoluteLocation" {} "$mountCheckFile" \;
	
	local includesMount
	includesMount=$(cat "$mountCheckFile")
	
	#Thorough sanity checking.
	[[ "$includesMount" != "false" ]] && _stop 0
	[[ "$includesMount" == "true" ]] && _stop 0
	[[ "$includesMount" == "false" ]] && _stop 1
	_stop 0
}

#http://stackoverflow.com/questions/687948/timeout-a-command-in-bash-without-unnecessary-delay
_timeout() { ( set +b; sleep "$1" & "${@:2}" & wait -n; r=$?; kill -9 `jobs -p`; exit $r; ) } 

#Waits for the process PID specified by first parameter to end. Useful in conjunction with $! to provide process control and/or PID files. Unlike wait command, does not require PID to be a child of the current shell.
_pauseForProcess() {
	while ps --no-headers -p $1 &> /dev/null
	do
		sleep 0.3
	done
}
alias _waitForProcess=_pauseForProcess
alias waitForProcess=_pauseForProcess

#True if daemon is running.
_daemonStatus() {
	if [[ -e "$pidFile" ]]
	then
		export daemonPID=$(cat "$pidFile")
	fi
	
	ps -p "$daemonPID" >/dev/null 2>&1 && return 0
	return 1
}

_waitForTermination() {
	_daemonStatus && sleep 0.1
	_daemonStatus && sleep 0.3
	_daemonStatus && sleep 1
	_daemonStatus && sleep 2
}
alias _waitForDaemon=_waitForTermination

#Kills background process using PID file.
_killDaemon() {
	_daemonStatus && kill -TERM "$daemonPID" >/dev/null 2>&1
	
	_waitForTermination
	
	_daemonStatus && kill -KILL "$daemonPID" >/dev/null 2>&1
	
	_waitForTermination
	
	rm "$pidFile" >/dev/null 2>&1
}

#Executes self in background (ie. as daemon).
_execDaemon() {
	"$scriptAbsoluteLocation" >/dev/null 2>&1 &
	echo "$!" > "$pidFile"
}

#http://unix.stackexchange.com/questions/55913/whats-the-easiest-way-to-find-an-unused-local-port
_findPort() {
	lower_port="$1"
	upper_port="$2"
	
	#read lower_port upper_port < /proc/sys/net/ipv4/ip_local_port_range
	[[ "$lower_port" == "" ]] && lower_port=54000
	[[ "$upper_port" == "" ]] && upper_port=55000
	
	local portRangeOffset
	portRangeOffset=$RANDOM
	let "portRangeOffset %= 150"
	
	let "lower_port += portRangeOffset"
	
	while true
	do
		for (( port = lower_port ; port <= upper_port ; port++ )); do
			if ! ss -lpn | grep ":$port " > /dev/null 2>&1
			then
				sleep 0.1
				if ! ss -lpn | grep ":$port " > /dev/null 2>&1
				then
					break 2
				fi
			fi
		done
	done
	echo $port
}

#Generates random alphanumeric characters, default length 18.
_uid() {
	local uidLength
	[[ -z "$1" ]] && uidLength=18 || uidLength="$1"
	
	cat /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c "$uidLength"
}

#Validates non-empty request.
_validateRequest() {
	echo -e -n '\E[1;32;46m Validating request '"$1"'...	\E[0m'
	[[ "$1" == "" ]] && echo -e '\E[1;33;41m BLANK \E[0m' && return 1
	echo "PASS"
	return
}

#Copy log files to "$permaLog" or current directory (default) for analysis.
_preserveLog() {
	if [[ ! -d "$permaLog" ]]
	then
		permaLog="$PWD"
	fi
	
	cp "$logTmp"/* "$permaLog"/
}

#Checks if file/directory exists on remote system. Overload this function with implementation specific to the container/virtualization solution in use (ie. docker run).
_checkBaseDirRemote() {
	false
}

#Reports the highest-level directory containing all files in given parameter set.
#"$@" == parameters to search
_searchBaseDir() {
	local baseDir
	local newDir
	
	baseDir=""
	
	local processedArgs
	local currentArg
	local currentResult
	
	for currentArg in "$@"
	do
		if _checkBaseDirRemote "$currentArg"
		then
			continue
		fi
		
		currentResult="$currentArg"
		processedArgs+=("$currentResult")
	done
	
	for currentArg in "${processedArgs[@]}"
	do	
		
		if [[ ! -e "$currentArg" ]]
		then
			continue
		fi
		
		if [[ "$baseDir" == "" ]]
		then
			baseDir=$(_findDir "$currentArg")
		fi
		
		for subArg in "${processedArgs[@]}"
		do
			if [[ ! -e "$subArg" ]]
			then
				continue
			fi
			
			newDir=$(_findDir "$subArg")
			
			while [[ "$newDir" != "$baseDir"* ]]
			do
				baseDir=$(_findDir "$baseDir"/..)
				
				if [[ "$baseDir" == "/" ]]
				then
					break
				fi
			done
			
		done
		
		
		
		
	done
	
	echo "$baseDir"
}

#Converts to relative path, if provided a file parameter.
#"$1" == parameter to search
#"$2" == sharedProjectDir
#"$3" == sharedGuestProjectDir (optional)
_localDir() {
	if _checkBaseDirRemote "$1"
	then
		echo "$1"
		return
	fi
	
	if [[ ! -e "$2" ]]
	then
		echo "$1"
		return
	fi
	
	if [[ ! -e "$1" ]]
	then
		echo "$1"
		return
	fi
	
	[[ "$3" != "" ]] && echo -n "$3"/
	realpath -L -s --relative-to="$2" "$1"
	
}

#Lists all chrooted processes. First parameter is chroot directory. Script might need to run as root.
#Techniques originally released by other authors at http://forums.grsecurity.net/viewtopic.php?f=3&t=1632 .
#"$1" == ChRoot Dir
_listprocChRoot() {
	CHROOT=$(_getAbsoluteLocation "$1")
	PROCS=""
	for p in `ps -o pid -A`; do
		if [ "`readlink /proc/$p/root`" = "$CHROOT" ]; then
			PROCS="$PROCS $p"
		fi
	done
	echo "$PROCS"
}

#End user and diagnostic function, shuts down all processes in a chroot.
_stopChRoot() {
	
	ChRootDir=$(_getAbsoluteLocation "$1")
	
	echo "TERMinating all chrooted processes."
	sleep 5
	kill -TERM $(_listprocChRoot "$ChRootDir") >/dev/null 2>&1
	sleep 15
	
	echo "KILLing all chrooted processes."
	kill -KILL $(_listprocChRoot "$ChRootDir") >/dev/null 2>&1
	sleep 1
	
	echo "Remaining chrooted processes."
	_listprocChRoot "$ChRootDir"
	
	echo '-----'
	
}





 

 

 

 

#Determines if user is root. If yes, then continue. If not, exits after printing error message.
_mustBeRoot() {
if [[ $(id -u) != 0 ]]; then 
	echo "This must be run as root!"
	exit
fi
}
alias mustBeRoot=_mustBeRoot

#Determines if sudo is usable by scripts.
_mustGetSudo() {
	local rootAvailable
	rootAvailable=false
	
	rootAvailable=$(sudo -n echo true)
	
	#[[ $(id -u) == 0 ]] && rootAvailable=true
	
	! [[ "$rootAvailable" == "true" ]] && exit 1
}

#Returns a UUID in the form of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
_getUUID() {
	cat /proc/sys/kernel/random/uuid
}
alias getUUID=_getUUID

#####Shortcuts

_gitInfo() {
	#Git Repository Information
	export repoDir="$PWD"

	export repoName=$(basename "$repoDir")
	export bareRepoDir=../."$repoName".git
	export bareRepoAbsoluteDir=$(_getAbsoluteLocation "$bareRepoDir")

	#Set $repoHostName in user ".bashrc" or similar. May also set $repoPort including colon prefix.
	[[ "$repoHostname" == "" ]] && export repoHostname=$(hostname -f)
	
	true
}


_gitNew() {
	git init
	git add .
	git commit -a -m "first commit"
}

_gitCheck() {
	find . -name .git -type d -exec bash -c 'echo ----- $(basename $(dirname $(realpath {}))) ; cd $(dirname $(realpath {})) ; git status' \;
}

_gitImport() {
	cd "$scriptFolder"
	
	mkdir -p "$1"
	cd "$1"
	shift
	git clone "$@"
	
	cd "$scriptFolder"
}

# DANGER
#Removes all but the .git folder from the working directory.
#_gitFresh() {
#	find . -not -path '\.\/\.git*' -delete
#}


#####Program

_createBareGitRepo() {
	mkdir -p "$bareRepoDir"
	cd $bareRepoDir
	
	git --bare init
	
	echo "-----"
}


_setBareGitRepo() {
	cd "$initPWD"
	
	git remote rm origin
	git remote add origin "$bareRepoDir"
	git push --set-upstream origin master
	
	echo "-----"
}

_showGitRepoURI() {
	echo git clone --recursive ssh://"$USER"@"$repoHostname""$repoPort""$bareRepoAbsoluteDir" "$repoName"
	
	
	if [[ "$repoHostname" != "" ]]
	then
		clear
		echo ssh://"$USER"@"$repoHostname""$repoPort""$bareRepoAbsoluteDir"
		sleep 15
	fi
}

_gitBareSequence() {
	_gitInfo
	
	if [[ -e "$bareRepoDir" ]]
	then
		_showGitRepoURI
		return 2
	fi
	
	if ! [[ -e "$initPWD"/.git ]]
	then
		return 1
	fi
	
	_createBareGitRepo
	
	_setBareGitRepo
	
	_showGitRepoURI
	
}

_gitBare() {
	
	_gitBareSequence
	
}



_visualPrompt() {
export PS1='\[\033[01;40m\]\[\033[01;36m\]+\[\033[01;34m\]-|\[\033[01;31m\]${?}:${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u\[\033[01;32m\]@\h\[\033[01;36m\]\[\033[01;34m\])-\[\033[01;36m\]----------\[\033[01;34m\]-(\[\033[01;35m\]$(date +%H:%M:%S\ %b\ %d,\ %y)\[\033[01;34m\])-\[\033[01;36m\]--- - - - |\[\033[00m\]\n\[\033[01;40m\]\[\033[01;36m\]+\[\033[01;34m\]-|\[\033[37m\][\w]\[\033[00m\]\n\[\033[01;36m\]+\[\033[01;34m\]-|\#) \[\033[36m\]>\[\033[00m\] '
} 

_importShortcuts() {
	_visualPrompt
}

_setupUbiquitous() {
	
	mkdir -p "$HOME"/bin/
	
	ln -s "$scriptAbsoluteLocation" "$HOME"/bin/ubiquitous_bash.sh
	
	echo '. '"$scriptAbsoluteLocation"' _importShortcuts' >> "$HOME"/.bashrc
	
} 

#####Basic Variable Management

#####Global variables.

export sessionid=$(_uid)
export scriptAbsoluteLocation=$(_getScriptAbsoluteLocation)
export scriptAbsoluteFolder=$(_getScriptAbsoluteFolder)

export initPWD="$PWD"
intInitPWD="$PWD"

#Temporary directories.
export safeTmp="$scriptAbsoluteFolder"/w_"$sessionid"
export logTmp="$safeTmp"/log
export shortTmp=/tmp/w_"$sessionid"	#Solely for misbehaved applications called upon.
export scriptBin="$scriptAbsoluteFolder"/_bin

#export varStore="$scriptAbsoluteFolder"/var

#Process control.
[[ "$pidFile" == "" ]] && export pidFile="$safeTmp"/.bgpid
export daemonPID="cwrxuk6wqzbzV6p8kPS8J4APYGX"	#Invalid do-not-match default.

#Monolithic shared files.

#Resource directories.
#export guidanceDir="$scriptAbsoluteFolder"/guidance

#Current directory for preservation.
export outerPWD=$(_getAbsoluteLocation "$PWD")

#Object Dir
export objectDir="$scriptAbsoluteFolder"

#Object Name
export objectName=$(basename "$objectDir")

#Modify PATH to include own directories.
export PATH="$PATH":"$scriptAbsoluteFolder"
[[ -d "$scriptBin" ]] && export PATH="$PATH":"$scriptBin"

#####Local Environment Management (Resources)

_extra() {
	true
}


_prepare() {
	
	mkdir -p "$safeTmp"
	
	mkdir -p "$shortTmp"
	
	mkdir -p "$logTmp"
	
	_extra
}

#####Local Environment Management (Instancing)

_start() {
	
	_prepare
	
	#touch "$varStore"
	#. "$varStore"
	
	
}

_saveVar() {
	true
	#declare -p varName > "$varStore"
}

_stop() {
	
	_safeRMR "$safeTmp"
	_safeRMR "$shortTmp"
	
	_tryExec _killDaemon
	
	if [[ "$1" != "" ]]
	then
		exit "$1"
	else
		exit 0
	fi
}

_preserveLog() {
	cp "$logTmp"/* ./  >/dev/null 2>&1
}

#####Idle

_idle() {
	_start
	
	_checkDep getIdle
	
	_killDaemon
	
	while true
	do
		sleep 5
		
		idleTime=$("$scriptBin"/getIdle)
		
		if [[ "$idleTime" -lt "3300000" ]] && _daemonStatus
		then
			true
			_killDaemon	#Comment out if unnecessary.
		fi
		
		
		if [[ "$idleTime" -gt "3600000" ]] && ! _daemonStatus
		then
			_execDaemon
		fi
		
		
		
	done
	
	_stop
}

_idleTest() {
	
	_checkDep getIdle
	
	idleTime=$("$scriptBin"/getIdle)
	
	if ! echo "$idleTime" | grep '^[0-9]*$' >/dev/null 2>&1
	then
		echo getIdle invalid response
		_stop 1
	fi
	
}

_idleBuild() {
	
	idleSourceCode=$(find "$scriptAbsoluteFolder" -type f -name "getIdle.c" | head -n 1)
	
	mkdir -p "$scriptBin"
	gcc -o "$scriptBin"/getIdle "$idleSourceCode" -lXss -lX11
	
}

#####Installation

#Verifies the timeout and sleep commands work properly, with subsecond specifications.
_timetest() {
	
	iterations=0
	while [[ "$iterations" -lt 10 ]]
	do
		dateA=$(date +%s)
		
		sleep 0.1
		sleep 0.1
		sleep 0.1
		sleep 0.1
		sleep 0.1
		sleep 0.1
		
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		_timeout 0.1 sleep 10
		
		dateB=$(date +%s)
		
		dateDelta=$(bc <<< "$dateB - $dateA")
		
		if [[ "$dateDelta" -lt "1" ]]
		then
			echo "FAIL"
			_stop 1
		fi
		
		if [[ "$dateDelta" -lt "5" ]]
		then
			echo "PASS"
			return 0
		fi
		
		let iterations="$iterations + 1"
	done
	echo "FAIL"
	_stop 1
}

_test() {
	_start
	
	echo -e -n '\E[1;32;46m Dependency checking...	\E[0m'
	
	# Check dependencies
	_checkDep wget
	_checkDep grep
	_checkDep fgrep
	_checkDep sed
	_checkDep awk
	_checkDep cut
	_checkDep head
	_checkDep tail
	
	
	_checkDep realpath
	_checkDep readlink
	_checkDep dirname
	
	_checkDep sleep
	_checkDep wait
	_checkDep kill
	_checkDep jobs
	_checkDep ps
	_checkDep exit
	
	_checkDep env
	_checkDep bash
	_checkDep echo
	_checkDep cat
	_checkDep type
	_checkDep mkdir
	_checkDep trap
	_checkDep return
	_checkDep set
	
	_checkDep rm
	
	_checkDep find
	_checkDep ln
	_checkDep ls
	
	_checkDep mountpoint
	
	_tryExec "_idleTest"
	
	[[ -e /dev/urandom ]] || echo /dev/urandom missing _stop
	
	echo "PASS"
	
	echo -n -e '\E[1;32;46m Timing...		\E[0m'
	_timetest
	
	_stop
	
}

#Creates symlink in ~/bin, to the executable at "$1", named according to its residing directory and file name.
_setupCommand() {
	local clientScriptLocation
	clientScriptLocation=$(_getAbsoluteLocation "$1")
	
	local clientScriptFolder
	clientScriptFolder=$(_getAbsoluteFolder "$1")
	
	local commandName
	commandName=$(basename "$1")
	
	local clientName
	clientName=$(basename "$clientScriptFolder")
	
	ln -s -r "$clientScriptLocation" ~/bin/"$commandName""-""$clientName"
	
	
}

_setupCommands() {
	#find . -name '_command' -exec "$scriptAbsoluteLocation" _setupCommand {} \;
	true
}

_setup() {
	_start
	
	"$scriptAbsoluteLocation" _test
	
	"$scriptAbsoluteLocation" _build "$@"
	
	_setupCommands
	
	_stop
}

#####Program

_build() {
	_tryExec _idleBuild
	false
}

#Typically launches an application - ie. through virtualized container.
_launch() {
	false
}

#Typically gathers command/variable scripts from other (ie. yaml) file types (ie. AppImage recipes).
_collect() {
	false
}

#Typical program entry point, absent any instancing support.
_enter() {
	_launch
}

#Typical program entry point.
_main() {
	_start
	
	_collect
	
	_enter
	
	_stop
}

#####Overrides

#Traps, if script is not imported into existing shell, or bypass requested.
if ! [[ "${BASH_SOURCE[0]}" != "${0}" ]] || ! [[ "$1" != "--bypass" ]]
then
	trap 'excode=$?; _stop $excode; trap - EXIT; echo $excode' EXIT HUP INT QUIT PIPE TERM		# reset
	trap 'excode=$?; trap "" EXIT; _stop $excode; echo $excode' EXIT HUP INT QUIT PIPE TERM		# ignore
fi

#Override functions with external definitions from a separate file if available.
#if [[ -e "./ops" ]]
#then
#	. ./ops
#fi

#Override functions with external definitions from a separate file if available.
if [[ -e "$objectDir"/ops ]]
then
	. "$objectDir"/ops
fi


#Launch internal functions as commands.
#if [[ "$1" != "" ]] && [[ "$1" != "-"* ]] && [[ ! -e "$1" ]]
if [[ "$1" == '_'* ]]
then
	"$@"
	#Exit if not imported into existing shell, or bypass requested, else fall through to subsequent return.
	if ! [[ "${BASH_SOURCE[0]}" != "${0}" ]] || ! [[ "$1" != "--bypass" ]]
	then
		exit "$?"
	fi
	#_stop "$?"
fi

#Stop if script is imported into an existing shell and bypass not requested.
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ "$1" != "--bypass" ]]
then
	return
fi

if ! [[ "$1" != "--bypass" ]]
then
	shift
fi

#####Entry

#"$scriptAbsoluteLocation" _setup


_main "$@"


