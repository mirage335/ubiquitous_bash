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