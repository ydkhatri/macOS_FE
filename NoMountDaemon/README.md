This daemon uses the Disk Arbitration framework to block all internal disks from mounting. Disks/Volumes mounted from Disk Utility or diskutil will be blocked. However explicit mounts using `sudo mount ..` will be allowed.

## To compile and set as service

`clang -Wall -Werror -g -v stop_mounts.m  -lobjc -framework DiskArbitration -framework Foundation -o stop_mount`

#### Change permissions so anyone can execute

`chmod +x stop_mount`  

#### Rename and copy to /usr/local/bin
`cp stop_mount /usr/local/bin/disk_block_daemon`

#### Copy the plist to /Library/LaunchDaemons/

`sudo cp com.swiftforensics.diskblock.plist /Library/LaunchDaemons/`

:warning: Do not try this on local machine. The daemon is set to deny all internal disk mounts.  
:warning: This method isn't perfect, and there are conditions under which this will fail and disks will be mounted at boot.
