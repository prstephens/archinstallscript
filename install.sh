#! /bin/bash

echo "Paul's Arch Installer"

loadkeys uk

# Set up network connection
read -p 'Are you connected to internet? [y/N]: ' neton
if ! [ $neton = 'y' ] && ! [ $neton = 'Y' ]
then 
    echo "Connect to internet to continue..."
    exit
fi

# Set up time
timedatectl set-ntp true

# Initate pacman keyring
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

# Setup the partitions
read -p 'You are about to wipe /dev/md/RAIDVOL1_0p4? [y/N]: ' wipe
if [ $wipe = 'y' ] && ! [ $wipe = 'Y' ]
then
    mkfs.ext4 /dev/md/RAIDVOL1_0p4
else
    echo "Install stopped"
    exit
fi

mount /dev/md/RAIDVOL1_0p4 /mnt

# Install Arch Linux
echo "Starting install.."
echo "Installing Arch Linux with default kernal, GRUB2 as bootloader" 
pacstrap /mnt base base-devel mdadm networkmanager reflector linux linux-headers linux-firmware grub os-prober intel-ucode ntfs-3g dosfstools mtools xorg xorg-server xorg-xinit nano sudo git nvidia nvidia-settings pacman-contrib bluez bluez-utils

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy post-install system cinfiguration script to new /root
cp -rfv config.sh /mnt/root
chmod a+x /mnt/root/config.sh

cp -rfv post-install.sh /mnt/root

# Chroot into new system
echo "After chrooting into newly installed OS, please run the config.sh by executing ./root/config.sh"
echo "Press any key to chroot..."
read tmpvar
arch-chroot /mnt /bin/bash

# Finish
echo "If config.sh was run succesfully, you will now have a fully working bootable Arch Linux system installed."
echo "The only thing left is to reboot into the new system."
echo "Login as you and then run post-install.sh to complete the installation"
echo "Press any key to reboot or Ctrl+C to cancel..."
read tmpvar
reboot