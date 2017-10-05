# TODO TODO Mount project directory if isolation configuration variable is set. Set directory permissions correctly. Use either root or ubvrtusr home directory as appropriate.
_mountChRoot_project() {
	
	_bindMountManager "$sharedHostProjectDir" "$sharedGuestProjectDir" || return 1
	
}

_umountChRoot_project() {
	
	_wait_umount "$chrootDir""$sharedGuestProjectDir"
	
}


_mountChRoot_user() {
	
	_bindMountManager "$globalChRootDir" "$instancedChrootDir" || return 1
	_mountChRoot "$instancedChrootDir" || return 1
	
	return 0
	
}

_umountChRoot_user() {
	
	mountpoint "$chrootDir" > /dev/null 2>&1 || return 1
	_umountChRoot "$instancedChrootDir"
	
}



_mountChRoot_user_home() {
	
	sudo -n mount -t tmpfs -o size=4G tmpfs "$instancedChrootDir"/home/ubvrtusr || return 1
	
	return 0
	
}

_umountChRoot_user_home() {
	
	_wait_umount "$instancedChrootDir"/home/ubvrtusr || return 1
	mountpoint "$instancedChrootDir"/home/ubvrtusr > /dev/null 2>&1 && return 1
	
	return 0
	
} 
