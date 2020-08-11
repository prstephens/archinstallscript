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

# Mount the partitions
mount /dev/md/RAIDVOL1_0p4 /mnt

# Install Arch Linux
echo "Starting install.."
echo "Installing Arch Linux with Zen Kernal, GRUB2 as bootloader" 
pacstrap /mnt base base-devel mdadm networkmanager reflector linux-zen linux-zen-headers linux-firmware grub os-prober intel-ucode ntfs-3g dosfstools mtools xorg xorg-server xorg-xinit nano sudo git nvidia-dkms

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy post-install system cinfiguration script to new /root
cp -rfv post-install.sh /mnt/root
chmod a+x /mnt/root/post-install.sh

# Chroot into new system
echo "After chrooting into newly installed OS, please run the post-install.sh by executing ./post-install.sh"
echo "Press any key to chroot..."
read tmpvar
arch-chroot /mnt /bin/bash

# Finish
echo "If post-install.sh was run succesfully, you will now have a fully working bootable Arch Linux system installed."
echo "The only thing left is to reboot into the new system."
echo "Press any key to reboot or Ctrl+C to cancel..."
read tmpvar
reboot