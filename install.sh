#!/bin/bash

set -e

clear

echo "     _             _       ___           _        _ _           "
echo "    / \   _ __ ___| |__   |_ _|_ __  ___| |_ __ _| | | ___ _ __ "
echo "   / _ \ | '__/ __| '_ \   | || '_ \/ __| __/ _\` | | |/ _ \ '__|"
echo "  / ___ \| | | (__| | | |  | || | | \__ \ || (_| | | |  __/ |   "
echo " /_/   \_\_|  \___|_| |_| |___|_| |_|___/\__\__,_|_|_|\___|_|   "
echo "                                                                "
echo " Version 2.0"
echo " "

performInstall()
{
    # Set up time
    echo "Setting date and time..."
    timedatectl set-ntp true

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
    echo "Installing Arch Linux with Zen kernel, rEFInd as bootloader" 
    pacstrap /mnt base base-devel networkmanager reflector linux-zen linux-zen-headers linux-firmware refind efibootmgr intel-ucode ntfs-3g xorg xorg-server xorg-xinit nano sudo git nvidia-dkms nvidia-settings bluez bluez-utils pulseaudio rxvt-unicode dialog unzip cups hplip ufw gufw archlinux-keyring

    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
}

configuration()
{
    # Set Cloudfare as our DNS
    cat <<EOT > /mnt/etc/resolv.conf.head
nameserver 1.1.1.1
nameserver 1.0.0.1
EOT

    echo "Updating pacman mirrors to awesomeness..."
    # Update pacman mirror list
    arch-chroot /mnt reflector --verbose -c GB -l 25 --age 12 -p http -p https --sort rate --save /etc/pacman.d/mirrorlist

    echo "Setting up spacetime continuum..."
    # Set date time
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
    arch-chroot /mnt hwclock --systohc

    # Set locale to en_US.UTF-8 UTF-8
    arch-chroot /mnt sed -i '/en_GB.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=en_GB.UTF-8" >> /mnt/etc/locale.conf

    # Set the console keymap
    echo "KEYMAP=uk" >> /mnt/etc/vconsole.conf

    # Set hostname
    echo "archpc" >> /mnt/etc/hostname
    echo "127.0.1.1 archpc.localdomain  archpc" >> /mnt/etc/hosts

    # Set root password
    echo "Set root password"
    arch-chroot /mnt passwd

    # Install bootloader
    # rEFInd
    echo "Installing rEFInd..."

    ROOTUUID=$(blkid -s UUID -o value /dev/sdb2)

    arch-chroot /mnt mkdir /boot/efi

    # mount windows EFI boot (on sda1)
    arch-chroot /mnt mount /dev/sda1 /boot/efi

    # clean it up before install
    [[ -d /mnt/boot/efi/EFI/refind ]] && rm -rdf /mnt/boot/efi/EFI/refind

    arch-chroot /mnt refind-install

    # early KMS NVIDIA module and silent boot parameters
    cat <<EOT > /mnt/boot/refind_linux.conf
"Boot with standard options"  "rw root=UUID=${ROOTUUID} nvidia-drm.modeset=1 quiet loglevel=3 splash rd.udev.log_priority=3 vt.global_cursor_default=0 initrd=boot\intel-ucode.img initrd=boot\initramfs-linux-zen.img"
"Boot to single-user mode"    "rw root=UUID=${ROOTUUID} loglevel=3 quiet single"
"Boot with minimal options"   "rw root=UUID=${ROOTUUID}"
EOT

    # Morpheous theme for refind 
    arch-chroot /mnt mkdir /boot/efi/EFI/refind/themes
    arch-chroot /mnt git clone https://github.com/prstephens/Matrix-rEFInd.git /boot/efi/EFI/refind/themes/Matrix-rEFInd

    cat <<EOT > /mnt/boot/efi/EFI/refind/refind.conf
resolution 1920 1080
timeout 5
default_selection Microsoft
include themes/Matrix-rEFInd/theme.conf
EOT

    # early KMS NVIDIA module load
    arch-chroot /mnt sed -i 's/^MODULES=.*$/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -P

    # Create new user
    arch-chroot /mnt useradd -m -G wheel paul
    arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    echo "Set password for new user paul"
    arch-chroot /mnt passwd paul

    # config files
    echo "Getting some sweet config files..."
    arch-chroot /mnt mkdir /home/paul/.config
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/.Xresources -o /home/paul/.Xresources
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/.bashrc -o /home/paul/.bashrc
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/issue -o /etc/issue
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/reflector.service -o /etc/systemd/system/reflector.service
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/kwinrc -o /home/paul/.config/kwinrc

    arch-chroot /mnt chown -R paul:paul /home/paul/.config
    arch-chroot /mnt chown paul:paul /home/paul/.Xresources

    # Set keyboard FN keys to act normal!
    echo "options hid_apple fnmode=2" > /mnt/etc/modprobe.d/hid_apple.conf

    # Get yay ready 
    echo "Getting yay all ready for paul..."
    arch-chroot /mnt git clone https://aur.archlinux.org/yay.git /home/paul/yay
    arch-chroot /mnt chown -R paul:paul /home/paul/yay/

    # Copy post-install file to /home/paul
    echo "Copy post-install file to /home/paul..."
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/post-install.sh -o /home/paul/post-install.sh
    arch-chroot /mnt chown paul:paul /home/paul/post-install.sh
    arch-chroot /mnt chmod a+x /home/paul/post-install.sh

    # Create user xinit config file 
    echo "Creating .xinitrc file..."
    head -n -5 /mnt/etc/X11/xinit/xinitrc >> /mnt/home/paul/.xinitrc
    arch-chroot /mnt chown paul:paul /home/paul/.xinitrc

    # swappiness config for swap
    echo "vm.swappiness=10" >> /mnt/etc/sysctl.d/99-swappiness.conf

    # Set correct sound card for PulseAudio
    sudo echo "set-default-sink output alsa_output.pci-0000_00_1f.3.analog-stereo" >> /mnt/etc/pulse/default.pa

    # Enable firewall
    echo "Enabling firewall..."
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow http
    ufw allow https
    ufw allow dns
    ufw allow ntp
    ufw enable

    # Enable services
    echo "Enabling services..."
    arch-chroot /mnt systemctl enable NetworkManager.service
    arch-chroot /mnt systemctl enable bluetooth.service
    arch-chroot /mnt systemctl enable org.cups.cupsd.service
    arch-chroot /mnt systemctl enable reflector
    arch-chroot /mnt systemctl enable reflector.timer
    arch-chroot /mnt systemctl enable fstrim.timer
    arch-chroot /mnt systemctl enable ufw
}

checkConnection() 
{
    if [[ $(ping -q -w1 -c1 google.com &>/dev/null && echo online || echo offline) == "offline" ]]; 
    then
        echo "Oh dear. You need to be connected to the information highway..."
        echo "Installation stopped"
        exit
    fi
}

# START
loadkeys uk
checkConnection
performInstall
configuration

echo " "
echo "===== Installation Complete ====="
