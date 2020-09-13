#! /bin/bash

echo "Paul's Arch Installer"

performInstall()
{
    # Set up time
    timedatectl set-ntp true

    # Initate pacman keyring
    pacman-key --init
    pacman-key --populate archlinux
    pacman-key --refresh-keys

    # Setup the partitions
    read -p 'You are about to wipe /dev/sdb2? [y/N]: ' wipe
    if [ $wipe = 'y' ]
    then
        mkfs.ext4 /dev/sdb2
    else
        echo "Install stopped"
        exit
    fi

    mkswap /dev/sdb1
    swapon /dev/sdb1
    mount /dev/sdb2 /mnt

    # Install Arch Linux
    echo "Starting install.."
    echo "Installing Arch Linux with default kernel, GRUB2 as bootloader" 
    pacstrap /mnt base base-devel networkmanager reflector linux-zen linuz-zen-headers linux-firmware grub efibootmgr os-prober intel-ucode ntfs-3g dosfstools mtools xorg xorg-server xorg-xinit nano sudo git nvidia-dkms nvidia-settings pacman-contrib bluez bluez-utils pulseaudio rxvt-unicode lsd unzip cups hplip

    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab

    # Copy post-install system configuration script to new /root
    cp -rfv config.sh /mnt/root
    chmod a+x /mnt/root/config.sh

    cp -rfv post-install.sh /mnt/root
}

# Check for Connection
checkConnection() 
{
    if [[ $(ping -q -w1 -c1 google.com &>/dev/null && echo online || echo offline) == "online" ]]; 
    then
        echo "You're connected to the interwebs... lets do this!"
        performInstall
    else
        echo "Oh dear. You need to be connected to the information highway..."
        exit
    fi
}

# START
loadkeys uk
checkConnection

# Chroot into new system
echo "After chrooting into newly installed OS, please run the config.sh by executing ./root/config.sh"
echo "Press any key to chroot..."
read tmpvar
arch-chroot /mnt /bin/bash

# Finish
echo "If config.sh was run succesfully, you will now have a fully working bootable Arch Linux system installed."
echo "The only thing left is to reboot into the new system."
echo "Login as you and then run post-install.sh to complete the installation"