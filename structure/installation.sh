#####Installation


_vector() {
	_tryExec "_vector_virtUser"
}




# https://stackoverflow.com/questions/4774358/get-mtime-of-specific-file-using-bash
_test_selfTime_sequence() {
	_start
	
	local iterations
	
	local dateA
	local dateB
	local dateDelta
	
	
	iterations=0
	while [[ "$iterations" -lt 3 ]]
	do
		dateA=$(date +%s)
		! "$scriptAbsoluteLocation" _true && _messageFAIL && _stop 1
		"$scriptAbsoluteLocation" _false && _messageFAIL && _stop 1
		dateB=$(date +%s)
		
		dateDelta=$(bc <<< "$dateB - $dateA")
		#echo "$dateDelta"
		
		if [[ "$dateDelta" -lt 0 ]]
		then
			_messageFAIL
			_stop 1
		fi
		
		if [[ "$dateDelta" -gt 14 ]]
		then
			_messageFAIL
			_stop 1
		fi
		
		let iterations="$iterations + 1"
	done
	
	_stop 0
}

_test_selfTime() {
	"$scriptAbsoluteLocation" _test_selfTime_sequence "$@"
}


_test_bashTime_sequence() {
	_start
	
	local iterations
	
	local dateA
	local dateB
	local dateDelta
	
	
	iterations=0
	while [[ "$iterations" -lt 3 ]]
	do
		dateA=$(date +%s)
		! echo 'echo fake interactive' | bash -i > /dev/null 2>&1 && _messageFAIL && _stop 1
		echo 'false' | bash -i > /dev/null 2>&1 && _messageFAIL && _stop 1
		dateB=$(date +%s)
		
		dateDelta=$(bc <<< "$dateB - $dateA")
		#echo "$dateDelta"
		
		if [[ "$dateDelta" -lt 0 ]]
		then
			_messageFAIL
			_stop 1
		fi
		
		if [[ "$dateDelta" -gt 14 ]]
		then
			_messageFAIL
			_stop 1
		fi
		
		let iterations="$iterations + 1"
	done
	
	_stop 0
}

_test_bashTime() {
	"$scriptAbsoluteLocation" _test_bashTime_sequence "$@"
}


# https://stackoverflow.com/questions/4774358/get-mtime-of-specific-file-using-bash
_test_filemtime_sequence() {
	_start
	
	local iterations
	
	local currentFileMtimeA
	local currentFileMtimeB
	local currentFileMtimeDelta
	
	
	iterations=0
	while [[ "$iterations" -lt 3 ]]
	do
		echo > "$safeTmp"/test_filemtime
		currentFileMtimeA=$(stat -c %Y "$safeTmp"/test_filemtime)
		sleep 2
		touch "$safeTmp"/test_filemtime
		currentFileMtimeB=$(stat -c %Y "$safeTmp"/test_filemtime)
		
		currentFileMtimeDelta=$(bc <<< "$currentFileMtimeB - $currentFileMtimeA")
		#echo "$currentFileMtimeDelta"
		
		if [[ "$currentFileMtimeDelta" -lt 1 ]]
		then
			_messageFAIL
			_stop 1
		fi
		
		if [[ "$currentFileMtimeDelta" -gt 12 ]]
		then
			_messageFAIL
			_stop 1
		fi
		
		let iterations="$iterations + 1"
	done
	
	
	iterations=0
	while [[ "$iterations" -lt 3 ]]
	do
		echo > "$safeTmp"/test_filemtime
		currentFileMtimeA=$(stat -c %Y "$safeTmp"/test_filemtime)
		sleep 2
		echo 'x' >> "$safeTmp"/test_filemtime
		currentFileMtimeB=$(stat -c %Y "$safeTmp"/test_filemtime)
		
		currentFileMtimeDelta=$(bc <<< "$currentFileMtimeB - $currentFileMtimeA")
		#echo "$currentFileMtimeDelta"
		
		if [[ "$currentFileMtimeDelta" -lt 1 ]]
		then
			_messageFAIL
			_stop 1
		fi
		
		if [[ "$currentFileMtimeDelta" -gt 12 ]]
		then
			_messageFAIL
			_stop 1
		fi
		
		let iterations="$iterations + 1"
	done
	
	
	iterations=0
	while [[ "$iterations" -lt 3 ]]
	do
		if ! rm -f "$safeTmp"/test_filemtime
		then
			_messageFAIL
			_stop 1
		fi
		echo > "$safeTmp"/test_filemtime
		if ! find "$safeTmp"/ -type f -mmin 0.19 | grep test_filemtime > /dev/null 2>&1
		then
			_messageFAIL
			_stop 1
		fi
		if ! find "$safeTmp"/ -type f -mmin -0.19 | grep test_filemtime > /dev/null 2>&1
		then
			_messageFAIL
			_stop 1
		fi
		
		sleep 16
		if find "$safeTmp"/ -type f -mmin 0.19 | grep test_filemtime > /dev/null 2>&1
		then
			_messageFAIL
			_stop 1
		fi
		if find "$safeTmp"/ -type f -mmin -0.19 | grep test_filemtime > /dev/null 2>&1
		then
			_messageFAIL
			_stop 1
		fi
		
		if ! find "$safeTmp"/ -type f -mmin 1 | grep test_filemtime > /dev/null 2>&1
		then
			_messageFAIL
			_stop 1
		fi
		if find "$safeTmp"/ -type f -mmin 2 | grep test_filemtime > /dev/null 2>&1
		then
			_messageFAIL
			_stop 1
		fi
		
		if ! find "$safeTmp"/ -type f -mmin -1 | grep test_filemtime > /dev/null 2>&1
		then
			_messageFAIL
			_stop 1
		fi
		if ! find "$safeTmp"/ -type f -mmin -2700 | grep test_filemtime > /dev/null 2>&1
		then
			_messageFAIL
			_stop 1
		fi
		
		let iterations="$iterations + 1"
	done
	
	
	_stop 0
}

_test_filemtime() {
	"$scriptAbsoluteLocation" _test_filemtime_sequence "$@"
}


#Verifies the timeout and sleep commands work properly, with subsecond specifications.
_timetest() {
	
	local iterations
	local dateA
	local dateB
	local dateDelta
	
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
			_messageFAIL
			_stop 1
		fi
		
		if [[ "$dateDelta" -lt "5" ]]
		then
			_messagePASS
			return 0
		fi
		
		let iterations="$iterations + 1"
	done
	_messageFAIL
	_stop 1
}

_testarglength() {
	local testArgLength
	
	! testArgLength=$(getconf ARG_MAX) && _messageFAIL && _stop 1
	
	
	# Typical UNIX.
	if [[ "$testArgLength" -lt 131071 ]]
	then
		# Typical Cygwin. Marginal result at best.
		[[ "$testArgLength" -ge 32000 ]] && uname -a | grep -i 'cygwin' > /dev/null 2>&1 && _messagePASS && return 0
		
		_messageFAIL && _stop 1
	fi
	
	_messagePASS
}



_variableLocalTestA_procedure() {
	local currentLocalA
	currentLocalA='false'
	[[ "$currentGlobalA" != 'true' ]] && _stop 1
	[[ "$currentLocalA" == '' ]] && _stop 1
	[[ "$currentLocalA" != 'false' ]] && _stop 1
	
	
	return 0
}

_variableLocalTestB_procedure() {
	[[ "$currentGlobalA" != 'true' ]] && return 1
	[[ "$currentLocalA" != '' ]] && return 1
	[[ "$currentLocalA" == 'true' ]] && return 1
	
	return 0
}

_variableLocalTestC_procedure() {
	[[ "$currentGlobalA" != '' ]] && _stop 1
	[[ "$currentGlobalA" == 'true' ]] && _stop 1
	
	return 0
}

_variableLocalTest_sequence() {
	_start
	
	export currentGlobalA='true'
	
	local currentLocalA
	currentLocalA='true'
	[[ "$currentLocalA" != 'true' ]] && _stop 1
	! _variableLocalTestA_procedure && _stop 1
	[[ "$currentLocalB" != '' ]] && _stop 1
	[[ "$currentLocalB" == 'true' ]] && _stop 1
	
	_variableLocalTestB_procedure && _stop 1
	! "$scriptAbsoluteLocation" _variableLocalTestB_procedure && _stop 1
	
	local currentGlobalA
	! _variableLocalTestC_procedure && _stop 1
	
	export currentGlobalB='false'
	local currentGlobalB='true'
	[[ "$currentGlobalB" != 'true' ]] && _stop 1
	
	local currentLocalB='true'
	[[ "$currentLocalB" != 'true' ]] && _stop 1
	
	_stop
}


_variableLocalTest() {
	if "$scriptAbsoluteLocation" _variableLocalTest_sequence "$@"
	then
		return 0
	fi
	return 1
}


_uid_test() {
	local current_uid_1
	local current_uid_2
	local current_uid_3
	
	current_uid_1=$(_uid)
	current_uid_2=$(_uid)
	current_uid_3_char=$(_uid 8 | wc -c)
	
	if [[ "$current_uid_1" == "" ]]
	then
		_messageFAIL
		_stop 1
	fi
	
	if [[ "$current_uid_2" == "" ]]
	then
		_messageFAIL
		_stop 1
	fi
	
	if [[ "$current_uid_1" == "$current_uid_2" ]]
	then
		_messageFAIL
		_stop 1
	fi
	
	if [[ "$current_uid_3_char" != "8" ]]
	then
		_messageFAIL
		_stop 1
	fi
	
	return 0
}


# Creating a function from within a function may be relied upon for some overrides.
# Enumerating a function's text with 'declare -f' may be relied upon by some 'here document' functions.
_define_function_test() {
	local current_uid_1
	current_uid_1=$(_uid)
	
	local current_uid_2
	current_uid_2=$(_uid)
	
	# https://stackoverflow.com/questions/7145337/bash-how-do-i-create-function-from-variable
	eval "__$current_uid_1() { __$current_uid_2() { echo $ubiquitiousBashID; }; }"
	
	if [[ $(declare -f __$current_uid_1 | wc -c) -lt 50 ]]
	then
		_messageFAIL
		_stop 1
	fi
	
	if [[ $(declare -f __$current_uid_2 | wc -c) -gt 0 ]]
	then
		_messageFAIL
		_stop 1
	fi
	
	__$current_uid_1
	
	if [[ $(declare -f __$current_uid_2 | wc -c) -lt 15 ]]
	then
		_messageFAIL
		_stop 1
	fi
	
	return 0
}

#_test_prog() {
#	true
#}

_test_embed_procedure-embed() {
	#echo $ub_import
	#echo $ub_import_param
	
	[[ "$ub_import" != 'true' ]] && return 1
	[[ "$ub_import" == '' ]] && return 1
	[[ "$ub_import_param" != '--embed' ]] && return 1
	
	return 0
}

_test_embed_sequence() {
	_start
	
	#echo $ub_import
	#echo $ub_import_param
	
	# CAUTION: Profoundly unexpected to have called '_test' or similar functions after importing into a current shell in any way.
	[[ "$ub_import" == 'true' ]] && return 1
	[[ "$ub_import" != '' ]] && return 1
	[[ "$ub_import_param" != '' ]] && return 1
	
	
	! "$safeTmp"/.embed.sh _true && _stop 1
	"$safeTmp"/.embed.sh _false && _stop 1
	
	
	
	! "$safeTmp"/.embed.sh _test_embed_procedure-embed && _stop 1
	
	! . "$safeTmp"/.embed.sh _test_embed_procedure-embed && _stop 1
	
	_stop
}

_test_embed() {
	"$scriptAbsoluteLocation" _test_embed_sequence "$@"
}

_test_sanity() {
	! "$scriptAbsoluteLocation" _true && _messageFAIL && return 1
	"$scriptAbsoluteLocation" _false && _messageFAIL && return 1
	
	# CAUTION: Profoundly unexpected to have called '_test' or similar functions after importing into a current shell in any way.
	[[ "$ub_import" == 'true' ]] && _messageFAIL && _stop 1
	[[ "$ub_import" != '' ]] && _messageFAIL && _stop 1
	[[ "$ub_import_param" != '' ]] && _messageFAIL && _stop 1
	
	local santiySessionID_length
	santiySessionID_length=$(echo -n "$sessionid" | wc -c | tr -dc '0-9')
	
	[[ "$santiySessionID_length" -lt "18" ]] && _messageFAIL && return 1
	[[ "$uidLengthPrefix" != "" ]] && [[ "$santiySessionID_length" -lt "$uidLengthPrefix" ]] && _messageFAIL && return 1
	
	[[ -e "$safeTmp" ]] && _messageFAIL && return 1
	
	_start
	
	[[ ! -e "$safeTmp" ]] && _messageFAIL && return 1
	
	local currentTestUID=$(_uid 245)
	mkdir -p "$safeTmp"/"$currentTestUID"
	echo > "$safeTmp"/"$currentTestUID"/"$currentTestUID"
	
	[[ ! -e "$safeTmp"/"$currentTestUID"/"$currentTestUID" ]] && _messageFAIL && return 1
	
	rm -f "$safeTmp"/"$currentTestUID"/"$currentTestUID"
	rmdir "$safeTmp"/"$currentTestUID"
	
	[[ -e "$safeTmp"/"$currentTestUID" ]] && _messageFAIL && return 1
	
	echo 'true' > "$safeTmp"/shouldNotOverwrite
	mv "$safeTmp"/doesNotExist "$safeTmp"/shouldNotOverwrite > /dev/null 2>&1 && _messageFAIL && return 1
	[[ $(cat "$safeTmp"/shouldNotOverwrite) != "true" ]] && _messageFAIL && return 1
	rm -f "$safeTmp"/shouldNotOverwrite > /dev/null 2>&1
	
	
	_uid_test
	
	_define_function_test
	
	! _variableLocalTest && _messageFAIL && return 1
	
	
	
	# WARNING: Not tested by default, due to lack of use except where faults are tolerable, and slim possibility of useful embedded systems not able to pass.
	#! echo \$123 | grep -E '^\$[0-9]|^\.[0-9]' > /dev/null 2>&1 && _messageFAIL && return 1
	#! echo \.123 | grep -E '^\$[0-9]|^\.[0-9]' > /dev/null 2>&1 && _messageFAIL && return 1
	#echo 123 | grep -E '^\$[0-9]|^\.[0-9]' > /dev/null 2>&1 && _messageFAIL && return 1
	
	
	
	if ! _test_embed
	then
		_messageFAIL && _stop 1
		#! uname -a | grep -i cygwin > /dev/null 2>&1 && _messageFAIL && _stop 1
		#echo 'warn: broken (cygwin): _test_embed - cygwin detected'
	fi
	
	
	
	
	_getDep flock
	
	( flock 200; echo > "$safeTmp"/ready ; sleep 3 ) 200>"$safeTmp"/flock &
	sleep 1
	if ( flock 200; ! [[ -e "$safeTmp"/ready ]] ) 200>"$safeTmp"/flock
	then
		! uname -a | grep -i cygwin > /dev/null 2>&1 && _messageFAIL && _stop 1
		echo 'warn: broken (cygwin): flock - cygwin may not be able to use flock through MSW network drive'
		return 1
	fi
	rm -f "$safeTmp"/flock > /dev/null 2>&1
	rm -f "$safeTmp"/ready > /dev/null 2>&1
	
	ln -s /dev/null "$safeTmp"/working
	ln -s /dev/null/broken "$safeTmp"/broken
	if ! [[ -h "$safeTmp"/broken ]] || ! [[ -h "$safeTmp"/working ]] || [[ -e "$safeTmp"/broken ]] || ! [[ -e "$safeTmp"/working ]]
	then
		! uname -a | grep -i cygwin > /dev/null 2>&1 && _messageFAIL && _stop 1
		echo 'warn: broken (cygwin): flock - cygwin may not be able to use flock through MSW network drive'
		return 1
	fi
	rm -f "$safeTmp"/working
	rm -f "$safeTmp"/broken
	
	
	
	return 0
}



_test() {
	_messageNormal "Sanity..."
	_test_sanity && _messagePASS
	
	
	
	_messageNormal "Permissions..."
	! _test_permissions_ubiquitous && _messageFAIL
	_messagePASS
	
	#Environment generated by ubiquitous bash is typically 10000 characters.
	echo -n -e '\E[1;32;46m Argument length...	\E[0m'
	
	_testarglength
	
	_messageNormal "Absolute pathfinding..."
	#_tryExec "_test_getAbsoluteLocation"
	_messagePASS
	
	echo -n -e '\E[1;32;46m Timing...		\E[0m'
	! _test_selfTime && echo '_test_selfTime broken' && _stop 1
	! _test_bashTime && echo '_test_selfTime broken' && _stop 1
	! _test_filemtime && echo '_test_selfTime broken' && _stop 1
	_timetest
	
	_messageNormal "Dependency checking..."
	
	## Check dependencies
	
	# WARNING: Although '#!/usr/bin/env bash' is used as header when possible, some high-speed 'heredoc' scripts may instead rely on '#!/bin/bash' or '#!/bin/dash' to ensure performance. For these important use cases, the typical '/bin/bash' and '/bin/dash' binary locations are required.
	_getDep /bin/bash
	! [[ -e /bin/bash ]] && echo '/bin/bash missing' && _stop 1
	! [[ -x /bin/bash ]] && echo '/bin/bash nonexecutable' && _stop 1
	_getDep /bin/dash
	! [[ -e /bin/dash ]] && echo '/bin/dash missing' && _stop 1
	! [[ -x /bin/dash ]] && echo '/bin/dash nonexecutable' && _stop 1
	
	#"generic/filesystem"/permissions.sh
	_checkDep stat
	
	_getDep wget
	_getDep grep
	_getDep fgrep
	_getDep sed
	_getDep awk
	_getDep cut
	_getDep head
	_getDep tail
	
	_getDep wc
	
	
	! _compat_realpath && ! _wantGetDep realpath && echo 'realpath missing'
	_getDep readlink
	_getDep dirname
	_getDep basename
	
	_getDep sleep
	_getDep wait
	_getDep kill
	_getDep jobs
	_getDep ps
	_getDep exit
	
	_getDep env
	_getDep bash
	_getDep echo
	_getDep cat
	_getDep tac
	_getDep type
	_getDep mkdir
	_getDep trap
	_getDep return
	_getDep set
	
	# WARNING: Deprecated. Migrate to 'type -p' instead when possible.
	# WARNING: No known production use.
	#https://unix.stackexchange.com/questions/85249/why-not-use-which-what-to-use-then
	_getDep which
	
	_getDep printf
	
	_getDep stat
	_getDep touch
	
	_getDep dd
	
	_getDep rm
	
	_getDep find
	_getDep ln
	_getDep ls
	
	_getDep id
	
	_getDep test
	
	_getDep true
	_getDep false
	
	_getDep diff
	
	_test_readlink_f
	
	_tryExec "_test_package"
	
	_tryExec "_test_daemon"
	
	_tryExec "_testFindPort"
	_tryExec "_test_waitport"
	
	_tryExec "_testProxySSH"
	
	_tryExec "_testAutoSSH"
	
	_tryExec "_testTor"
	
	_tryExec "_testProxyRouter"
	
	#_tryExec "_test_build"
	
	_tryExec "_testGosu"
	
	_tryExec "_testMountChecks"
	_tryExec "_testBindMountManager"
	_tryExec "_testDistro"
	_tryExec "_test_fetchDebian"
	
	_tryExec "_test_image"
	_tryExec "_test_transferimage"
	
	_tryExec "_testCreatePartition"
	_tryExec "_testCreateFS"
	
	_tryExec "_test_mkboot"
	
	_tryExec "_test_abstractfs"
	_tryExec "_test_fakehome"
	_tryExec "_testChRoot"
	_tryExec "_testQEMU"
	_tryExec "_testQEMU_x64-x64"
	_tryExec "_testQEMU_x64-raspi"
	_tryExec "_testQEMU_raspi-raspi"
	_tryExec "_testVBox"
	
	_tryExec "_test_vboxconvert"
	
	_tryExec "_test_dosbox"
	
	_tryExec "_testWINE"
	
	_tryExec "_test_docker"
	
	_tryExec "_test_docker_mkimage"
	
	_tryExec "_testVirtBootdisc"
	
	_tryExec "_testExtra"
	
	_tryExec "_testGit"
	
	_tryExec "_test_bup"
	
	_tryExec "_testX11"
	
	_tryExec "_test_virtLocal_X11"
	
	_tryExec "_test_gparted"
	
	_tryExec "_test_synergy"
	
	_tryExec "_test_devatom"
	_tryExec "_test_devemacs"
	_tryExec "_test_deveclipse"
	
	_tryExec "_test_ethereum"
	_tryExec "_test_ethereum_parity"
	
	_tryExec "_test_metaengine"
	
	_tryExec "_test_channel"
	
	! [[ -e /dev/urandom ]] && echo /dev/urandom missing && _stop 1
	
	_messagePASS
	
	_messageNormal 'Vector...'
	_vector
	_messagePASS
	
	_tryExec "_test_prog"
	
	_stop
}

#_testBuilt_prog() {
#	true
#}

_testBuilt() {
	_start
	
	_messageProcess "Binary checking"
	
	_tryExec "_testBuiltIdle"
	_tryExec "_testBuiltGosu"	#Note, requires sudo, not necessary for docker .
	
	_tryExec "_test_ethereum_built"
	_tryExec "_test_ethereum_parity_built"
	
	_tryExec "_testBuiltChRoot"
	_tryExec "_testBuiltQEMU"
	
	_tryExec "_testBuiltExtra"
	
	_tryExec "_testBuilt_prog"
	
	_messagePASS
	
	_stop
}

#Creates symlink in "$HOME"/bin, to the executable at "$1", named according to its residing directory and file name.
_setupCommand() {
	mkdir -p "$HOME"/bin
	! [[ -e "$HOME"/bin ]] && return 1
	
	local clientScriptLocation
	clientScriptLocation=$(_getAbsoluteLocation "$1")
	
	local clientScriptFolder
	clientScriptFolder=$(_getAbsoluteFolder "$1")
	
	local commandName
	commandName=$(basename "$1")
	
	local clientName
	clientName=$(basename "$clientScriptFolder")
	
	_relink_relative "$clientScriptLocation" "$HOME"/bin/"$commandName""-""$clientName"
	
	
}

_setupCommand_meta() {
	mkdir -p "$HOME"/bin
	! [[ -e "$HOME"/bin ]] && return 1
	
	local clientScriptLocation
	clientScriptLocation=$(_getAbsoluteLocation "$1")
	
	local clientScriptFolder
	clientScriptFolder=$(_getAbsoluteFolder "$1")
	
	local clientScriptFolderResidence
	clientScriptFolderResidence=$(_getAbsoluteFolder "$clientScriptFolder")
	
	local commandName
	commandName=$(basename "$1")
	
	local clientName
	clientName=$(basename "$clientScriptFolderResidence")
	
	_relink_relative "$clientScriptLocation" "$HOME"/bin/"$commandName""-""$clientName"
	
	
}

_find_setupCommands() {
	find -L "$scriptAbsoluteFolder" -not \( -path \*_arc\* -prune \) -not \( -path \*/_local/ubcp/\* -prune \) "$@"
}

#Consider placing files like ' _vnc-machine-"$netName" ' in an "_index" folder for automatic installation.
_setupCommands() {
	#_find_setupCommands -name '_command' -exec "$scriptAbsoluteLocation" _setupCommand '{}' \;
	
	_tryExec "_setup_ssh_commands"
	_tryExec "_setup_command_commands"
}

#_setup_pre() {
#	true
#}

#_setup_prog() {
#	true
#}


_setup_anchor() {
	if type "_associate_anchors_request" > /dev/null 2>&1
	then
		_tryExec "_associate_anchors_request"
		return
	fi
}

_setup() {
	_start
	
	"$scriptAbsoluteLocation" _test || _stop 1
	
	#Only attempt build procedures if their functions have been defined from "build.sh" . Pure shell script projects (eg. CoreAutoSSH), and projects using only statically compiled binaries, need NOT include such procedures.
	local buildSupported
	type _build > /dev/null 2>&1 && type _test_build > /dev/null 2>&1 && buildSupported="true"
	
	[[ "$buildSupported" == "true" ]] && ! "$scriptAbsoluteLocation" _test_build && _stop 1
	
	if ! "$scriptAbsoluteLocation" _testBuilt
	then
		! [[ "$buildSupported" == "true" ]] && _stop 1
		[[ "$buildSupported" == "true" ]] && ! "$scriptAbsoluteLocation" _build "$@" && _stop 1
		! "$scriptAbsoluteLocation" _testBuilt && _stop 1
	fi
	
	_setupCommands
	
	_tryExec "_setup_pre"
	
	_tryExec "_setup_ssh"
	
	_tryExec "_setup_prog"
	
	_setup_anchor
	
	_stop
}

# DANGER: Especially not expected to modify system program behavior (eg. not to modify "$HOME"/.ssh ).
# WARNING: Strictly expected to not modify anyting outside the script directory.
_setup_local() {
	export ub_setup_local='true'
	
	_setup
}

_test_package() {
	_getDep tar
	_getDep gzip
}

_package_prog() {
	true
}


_package_ubcp_copy() {
	mkdir -p "$safeTmp"/package/_local
	
	if [[ -e "$scriptLocal"/ubcp ]]
	then
		cp -a "$scriptLocal"/ubcp "$safeTmp"/package/_local/
		return 0
	fi
	if [[ -e "$scriptLib"/ubcp ]]
	then
		cp -a "$scriptLib"/ubcp "$safeTmp"/package/_local/
		return 0
	fi
	if [[ -e "$scriptAbsoluteFolder"/ubcp ]]
	then
		cp -a "$scriptAbsoluteFolder"/ubcp "$safeTmp"/package/_local/
		return 0
	fi
	
	
	if [[ -e "$scriptLib"/ubiquitous_bash/_local/ubcp ]]
	then
		cp -a "$scriptLib"/ubiquitous_bash/_local/ubcp "$safeTmp"/package/_local/
		return 0
	fi
	if [[ -e "$scriptLib"/ubiquitous_bash/_lib/ubcp ]]
	then
		cp -a "$scriptLib"/ubiquitous_bash/_lib/ubcp "$safeTmp"/package/_local/
		return 0
	fi
	if [[ -e "$scriptLib"/ubiquitous_bash/ubcp ]]
	then
		cp -a "$scriptLib"/ubiquitous_bash/ubcp "$safeTmp"/package/_local/
		return 0
	fi
	
	
	cd "$outerPWD"
	_stop 1
}

# ATTENTION: Override with 'ops' or similar ONLY if necessary.
_package_subdir() {
	#return 0
	
	# ATTENTION: Error message about 'cannot move' ... 'subdirectory of itself' ... is normal .
	mkdir -p "$safeTmp"/package/"$objectName"/
	( shopt -s dotglob ; mv "$safeTmp"/package/* "$safeTmp"/package/"$objectName"/ )
}

# WARNING Must define "_package_license" function in ops to include license files in package!
_package_procedure() {
	_start
	mkdir -p "$safeTmp"/package
	
	# WARNING: Largely due to presence of '.gitignore' files in 'ubcp' .
	export safeToDeleteGit="true"
	
	_package_prog
	
	_tryExec "_package_license"
	
	_tryExec "_package_cautossh"
	
	#cp -a "$scriptAbsoluteFolder"/.git "$safeTmp"/package/ > /dev/null 2>&1
	cp "$scriptAbsoluteFolder"/.gitmodules "$safeTmp"/package/ > /dev/null 2>&1
	
	cp "$scriptAbsoluteFolder"/COPYING "$safeTmp"/package/ > /dev/null 2>&1
	cp "$scriptAbsoluteFolder"/COPYING* "$safeTmp"/package/ > /dev/null 2>&1
	
	cp "$scriptAbsoluteFolder"/gpl.txt "$safeTmp"/package/ > /dev/null 2>&1
	cp "$scriptAbsoluteFolder"/gpl-*.txt "$safeTmp"/package/ > /dev/null 2>&1
	cp "$scriptAbsoluteFolder"/gpl-3.0.txt "$safeTmp"/package/ > /dev/null 2>&1
	
	cp "$scriptAbsoluteFolder"/agpl.txt "$safeTmp"/package/ > /dev/null 2>&1
	cp "$scriptAbsoluteFolder"/agpl-*.txt "$safeTmp"/package/ > /dev/null 2>&1
	cp "$scriptAbsoluteFolder"/agpl-3.0.txt "$safeTmp"/package/ > /dev/null 2>&1
	
	cp "$scriptAbsoluteFolder"/license.txt "$safeTmp"/package/ > /dev/null 2>&1
	cp "$scriptAbsoluteFolder"/license*.txt "$safeTmp"/package/ > /dev/null 2>&1
	
	#scriptBasename=$(basename "$scriptAbsoluteLocation")
	#cp -a "$scriptAbsoluteLocation" "$safeTmp"/package/"$scriptBasename"
	cp -a "$scriptAbsoluteLocation" "$safeTmp"/package/
	cp -a "$scriptAbsoluteFolder"/ops "$safeTmp"/package/
	cp -a "$scriptAbsoluteFolder"/ops.sh "$safeTmp"/package/
	
	cp "$scriptAbsoluteFolder"/_* "$safeTmp"/package/
	cp "$scriptAbsoluteFolder"/*.sh "$safeTmp"/package/
	
	cp -a "$scriptLocal"/ops "$safeTmp"/package/
	cp -a "$scriptLocal"/ops.sh "$safeTmp"/package/
	
	#cp -a "$scriptAbsoluteFolder"/_bin "$safeTmp"
	#cp -a "$scriptAbsoluteFolder"/_config "$safeTmp"
	#cp -a "$scriptAbsoluteFolder"/_prog "$safeTmp"
	
	#cp -a "$scriptAbsoluteFolder"/_local "$safeTmp"/package/
	
	cp -a "$scriptAbsoluteFolder"/README.md "$safeTmp"/package/
	cp -a "$scriptAbsoluteFolder"/USAGE.html "$safeTmp"/package/
	
	if [[ "$ubPackage_enable_ubcp" == 'true' ]]
	then
		_package_ubcp_copy "$@"
	fi
	
	cd "$safeTmp"/package/
	_package_subdir
	
	! [[ "$ubPackage_enable_ubcp" == 'true' ]] && tar -czvf "$scriptAbsoluteFolder"/package.tar.gz .
	[[ "$ubPackage_enable_ubcp" == 'true' ]] && tar -czvf "$scriptAbsoluteFolder"/package_ubcp.tar.gz .
	
	if [[ "$ubPackage_enable_ubcp" == 'true' ]]
	then
		_messagePlain_request 'request: review contents of _local/ubcp/cygwin/home and similar directories'
	fi
	
	cd "$outerPWD"
	_stop
}

_package() {
	export ubPackage_enable_ubcp='false'
	"$scriptAbsoluteLocation" _package_procedure "$@"
	
	export ubPackage_enable_ubcp='true'
	"$scriptAbsoluteLocation" _package_procedure "$@"
}






