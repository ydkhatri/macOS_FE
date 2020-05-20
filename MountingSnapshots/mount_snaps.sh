# (c) MIT License 2020 Yogesh Khatri
#
# This script automates the mounting of snapshots of a volume by
# listing them using tmutil, then creating folders and mounting
# the snapshots to these folders.
#
# Usage: ./mount_snaps.sh <mounted_vol_path> <output_folder>
#

if [ $# -ne 2 ]
then
    echo ""
    echo "Usage: ./mount_snaps.sh <mounted_vol_path> <output_folder>"
    echo ""
    exit 1
fi

mounted_vol_path=$1
folder_of_snapshots=$2

#mkdir "$folder_of_snapshots"

tmutil listlocalsnapshots "$mounted_vol_path" | while read -r item; do if [[ "$item" = "com"* ]] ; then mkdir "$folder_of_snapshots"/"$item"; mount_apfs -s "$item" "$mounted_vol_path" "$folder_of_snapshots"/"$item"/ ; fi;  done
