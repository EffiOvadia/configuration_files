# Generate fstab file
echo -e "# /etc/fstab:\n" > /etc/fstab.new
echo '#UUID MOUNTPOINT FSTYPE OPTIONS' >> /etc/fstab.new
# Locate and add "EFI System" boot partition to fstab
read UUID FSTYPE <<< "$(lsblk -p -o PARTTYPENAME,UUID,FSTYPE -P | awk -F'"' '$2=="EFI System" {print $4, $6}')"
echo "UUID=$UUID /boot/efi $FSTYPE defaults,noatime,discard,umask=0077,shortname=winnt 0 1" >> /etc/fstab.new
# Locate and add "Linux filesystem" root partition to fstab
read UUID FSTYPE <<< "$(lsblk -p -o PARTTYPENAME,UUID,FSTYPE -P | awk -F'"' '$2=="Linux filesystem" {print $4, $6}')"
echo "UUID=$UUID / $FSTYPE defaults,noatime,discard,commit=60,errors=remount-ro 0 1" >> /etc/fstab.new
# Locate and add "Linux home" partition to fstab
read UUID FSTYPE <<< "$(lsblk -p -o PARTTYPENAME,UUID,FSTYPE -P | awk -F'"' '$2=="Linux home" {print $4, $6}')"
echo "UUID=$UUID /home $FSTYPE defaults,noatime,discard,commit=60,x-systemd.automount 0 1" >> /etc/fstab.new
# Locate and add "Linux swap" partition to fstab
read UUID FSTYPE <<< "$(lsblk -p -o PARTTYPENAME,UUID,FSTYPE -P | awk -F'"' '$2=="Linux swap" {print $4, $6}')"
echo "UUID=$UUID none $FSTYPE sw,discard,pri=10,nofail 0 0" >> /etc/fstab.new
# Add example lines for NFS and SMB remote shares mounting
echo -e '\n#COMPUTERNAME/IPADDRESS MOUNTPOINT FSTYPE OPTIONS' >> /etc/fstab.new
echo "192.168.50.100:/ /nfc/tv nfs nfsvers=4,_netdev,x-systemd.automount,nofail 0 0" >> /etc/fstab.new
echo "#host:/export/share /nfc/share nfs nfsvers=4,_netdev,x-systemd.automount,nofail 0 0" >> /etc/fstab.new
echo "#//SERVER/Share /smb/share cifs guest,iocharset=utf8,vers=3.0,_netdev,nofail 0 0" >> /etc/fstab.new                                                      
# Backup the current fstab file to fstab
cp /etc/fstab /etc/fstab.backup.$(date +%F)
# Find the line number of the first entry for the second table
LN=$(sed -n '/#COMPUTERNAME\/IPADDRESS/=' /etc/fstab.new)
# Organize the fstab file in columns format (Overwrite the file with the formatted output using sponge)
sed -n '3,$p' /etc/fstab.new | sed '/^$/s/^/__EMPTY__/' | column -t | sed 's/__EMPTY__//' | sponge /etc/fstab.new
# validate the fstab file 
sudo findmnt --verify --verbose
# Update grub to enable TRIP on SSD 
sudo sed -i 's/[# ]*GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash scsi_mod.use_blk_mq=1"/g' /etc/default/grub
sudo update-grub
