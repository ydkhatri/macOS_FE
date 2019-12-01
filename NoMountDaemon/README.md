## To compile and set as service

`clang -Wall -Werror -g -v stop_mounts.m  -lobjc -framework DiskArbitration -framework Foundation -o stop_mount`

#### Change permissions so anyone can execute

`chmod +x stop_mount`  

#### Rename and copy to /usr/local/bin
`cp stop_mount /usr/local/bin/disk_block_daemon`

#### Copy the plist to /Library/LaunchDaemons/

`cp com.swiftforensics.diskblock > /Volumes/<YOUR_BOOT_VOLUME - Data>/Library/LaunchDaemons/`

Do not try this on local machine. The daemon is set to deny all internal disk mounts.
