#!/bin/bash

clear
#set -uo pipefail
#trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
loadkeys uk

BACKTITLE="Arch Installer v2.1"
MIRRORLIST_URL="https://archlinux.org/mirrorlist/?country=GB&protocol=https&use_mirror_status=on"

#devicelistraw=$(lsblk -o name,size,type)
#devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
#device=$(dialog --backtitle "$BACKTITLE" --title "Select installation disk" --stdout --menu "${devicelistraw}" 0 0 0 ${devicelist}) || exit 1

#dialog --yesno "Have you partitioned your drive ready?" 0 0
#response=$?

#if [ "$response" -eq 1 ]; then
#  cfdisk $device
#fi 

pacman -Sy --noconfirm pacman-contrib dialog

if [[ $(ping -q -w1 -c1 google.com &>/dev/null && echo online || echo offline) == "offline" ]]; 
    then
        dialog --backtitle "$BACKTITLE" --title 'Installation Stopped' --msgbox 'No Interent connection' 0 0
        exit
fi

echo "Updating mirror list"
curl -sL "$MIRRORLIST_URL" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

### Get infomation from user ###
hostname=$(dialog --backtitle "$BACKTITLE" --stdout --inputbox "Enter hostname" 0 0) || exit 1
clear
: ${hostname:?"hostname cannot be empty"}

user=$(dialog --backtitle "$BACKTITLE" --stdout --inputbox "Enter admin username" 0 0) || exit 1
clear
: ${user:?"user cannot be empty"}

password=$(dialog --backtitle "$BACKTITLE" --stdout --passwordbox "Enter admin password" 0 0) || exit 1
clear
: ${password:?"password cannot be empty"}

password2=$(dialog --backtitle "$BACKTITLE" --stdout --passwordbox "Enter admin password again" 0 0) || exit 1
clear
[[ "$password" == "$password2" ]] || ( echo "Passwords did not match"; exit 1; )


performInstall()
{
    clear

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

    #swap
    mkswap /dev/sdb1
    swapon /dev/sdb1

    #root
    mount /dev/sdb2 /mnt

    #data
    mkdir /mnt/data
    mount /dev/sdb3 /mnt/data

    # Install Arch Linux
    echo "Starting install.."
    echo "Installing Arch Linux with Zen kernel, rEFInd as bootloader" 
    pacstrap /mnt base base-devel networkmanager dnsutils reflector linux linux-firmware refind efibootmgr intel-ucode ntfs-3g xorg xorg-server xorg-xinit nano nano-syntax-highlighting sudo git nvidia nvidia-settings bluez bluez-utils pulseaudio rxvt-unicode wget dialog cups hplip ufw gufw archlinux-keyring anything-sync-daemon mtpfs gvfs-mtp gvfs-gphoto2 gvfs-smb openssh openvpn ncdu

    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
}

configuration()
{
    clear

    # Set Cloudfare as our DNS
    cat <<EOT > /mnt/etc/resolv.conf
nameserver 1.1.1.1
nameserver 1.0.0.1
EOT

    chattr +i /mnt/etc/resolv.conf

    cat <<EOT >> /mnt/etc/hosts
192.168.1.192   rainbowdash.localdomain rainbowdash
192.168.1.66    libreelec.localdomain libreelec
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
    echo "${hostname}" > /mnt/etc/hostname
    echo "127.0.1.1 archpc.localdomain  archpc" >> /mnt/etc/hosts

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
"Boot with standard options"  "rw root=UUID=${ROOTUUID} quiet loglevel=3 rd.udev.log_priority=3 nvidia-drm.modeset=1 nouveau.modeset=0 initrd=boot\intel-ucode.img initrd=boot\initramfs-linux.img"
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
    arch-chroot /mnt sed -i 's/^MODULES=.*$/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -P

    # Create new user
    arch-chroot /mnt useradd -m -G wheel $user
    arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    echo "Defaults insults" >> /mnt/etc/sudoers
    echo "Set password for new user ${user}"

    # Set root password
    echo "Setting user and root password..."
    echo "$user:$password" | chpasswd --root /mnt
    echo "root:$password" | chpasswd --root /mnt

    # config files
    echo "Getting some sweet config files..."
    arch-chroot /mnt mkdir /home/$user/.config
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/.Xresources -o /home/$user/.Xresources
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/.bashrc -o /home/$user/.bashrc
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/issue -o /etc/issue

    arch-chroot /mnt chown -R $user:$user /home/$user/.config
    
    # Get yay ready 
    echo "Getting yay all ready for ${user}..."
    arch-chroot /mnt git clone https://aur.archlinux.org/yay.git /home/$user/yay
    arch-chroot /mnt chown -R $user:$user /home/$user/yay/

    # Copy post-install file to /home/$user
    echo "Copy post-install file to /home/${user}..."
    arch-chroot /mnt curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/post-install.sh -o /home/$user/post-install.sh
    arch-chroot /mnt chown $user:$user /home/$user/post-install.sh
    arch-chroot /mnt chmod a+x /home/$user/post-install.sh

    # Create user xinit config file 
    echo "Creating .xinitrc file..."
    head -n -5 /mnt/etc/X11/xinit/xinitrc >> /mnt/home/$user/.xinitrc
    arch-chroot /mnt chown $user:$user /home/$user/.xinitrc

    cat >> /mnt/home/${user}/.xinitrc <<EOT 
xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto
EOT

    cat <<EOT > /mnt/etc/X11/xorg.conf.d/20-nvidia.conf
Section "OutputClass"
Identifier "intel"
MatchDriver "i915"
Driver "modesetting"
EndSection

Section "OutputClass"
Identifier "nvidia"
MatchDriver "nvidia-drm"
Driver "nvidia"
Option "AllowEmptyInitialConfiguration"
Option "PrimaryGPU" "yes"
ModulePath "/usr/lib/nvidia/xorg"
ModulePath "/usr/lib/xorg/modules"
EndSection
EOT

    # Set keyboard FN keys to act normal!
    echo "options hid_apple fnmode=2" > /mnt/etc/modprobe.d/hid_apple.conf
    
    # nano syntax highlighting
    echo "include /usr/share/nano/*.nanorc" >> /mnt/etc/nanorc

    # swappiness config for swap
    echo "vm.swappiness=10" >> /mnt/etc/sysctl.d/99-swappiness.conf

    # Set correct sound card for PulseAudio
    echo "set-default-sink output alsa_output.pci-0000_00_1f.3.analog-stereo" >> /mnt/etc/pulse/default.pa

    # Create the pacman mirrorlist updater service
cat <<EOT > /mnt/etc/systemd/system/reflector.service
[Unit]
Description=Pacman mirrorlist update
Wants=network-online.target
After=network-online.target nss-lookup.target

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector -c GB -l 25 --age 12 -p http -p https --sort rate --save /etc/pacman.d/mirrorlist

[Install]
WantedBy=multi-user.target
EOT

    # Enable services
    echo "Enabling services..."
    arch-chroot /mnt systemctl enable NetworkManager.service
    arch-chroot /mnt systemctl enable bluetooth.service
    arch-chroot /mnt systemctl enable cups.service
    arch-chroot /mnt systemctl enable reflector
    arch-chroot /mnt systemctl enable reflector.timer
    arch-chroot /mnt systemctl enable fstrim.timer
    arch-chroot /mnt systemctl enable ufw
}

# START
performInstall
configuration

dialog --backtitle "$BACKTITLE" --title 'Install Complete' --msgbox 'Congratulations! \n\nThe system will now reboot' 0 0

umount -a
reboot
