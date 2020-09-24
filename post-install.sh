#! /bin/bash

clear

echo "     _             _       ___           _        _ _           "
echo "    / \   _ __ ___| |__   |_ _|_ __  ___| |_ __ _| | | ___ _ __ "
echo "   / _ \ | '__/ __| '_ \   | || '_ \/ __| __/ _\` | | |/ _ \ '__|"
echo "  / ___ \| | | (__| | | |  | || | | \__ \ || (_| | | |  __/ |   "
echo " /_/   \_\_|  \___|_| |_| |___|_| |_|___/\__\__,_|_|_|\___|_|   "
echo "                                                                "
echo " Post Installation - Version 2.0"
echo " "

if [[ -d /home/paul/yay ]]
then
  echo "Installing yay..."
  cd $HOME/yay
  makepkg -si
  cd ..
  rm -rfd yay
fi

sudo pacman -S archlinux-keyring

# git credentials
git config --global credential.helper store
git config --global user.email "pr.stephens@gmail.com"
git config --global user.name "prstephens"

install_DE()
{
    # Deepin
    echo "Installing Deepin..."
    read -p 'NOTE: Please select deepin-anything-dkms when prompted. Press any key to continue...' installDE
    sudo pacman -S deepin redshift pacman-contrib

    # Deepin Arch update notifier
    echo "Installing Deepin update notifier plugin..."
    yay -S deepin-dock-plugin-arch-update

    # xinit config
    echo "exec startdde" >> $HOME/.xinitrc
    echo '[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> $HOME/.bash_profile

    echo "Installing glorious lightdm theme..."
    yay -S lightdm-webkit2-theme-glorious
    sudo sed -i 's/^#greeter-session=.*$/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf
    sudo sed -i 's/^debug_mode.*$/debug_mode=true/' /etc/lightdm/lightdm-webkit2-greeter.conf
    sudo sed -i 's/^webkit_theme.*$/webkit_theme=glorious/' /etc/lightdm/lightdm-webkit2-greeter.conf
    sudo systemctl enable lightdm

    echo "Installing fonts..."
    yay -S nerd-fonts-complete otf-san-francisco

     # Copy Windows fonts over
    echo "Copying Windows fonts..."
    sudo mkdir /usr/share/fonts/windowsfonts
    sudo mkdir /windows10
    sudo mount /dev/sda3 /windows10
    sudo cp /windows10/Windows/Fonts/* /usr/share/fonts/windowsfonts
    fc-cache -f
    sudo umount /windows10
}

install_apps()
{
    echo "Installing Chrome, VS Code, WPS Office, Gimp..."
    yay -S google-chrome firefox code wps-office gimp vlc

     # Spotify
    echo "Installing Spotify..."
    gpg --keyserver pool.sks-keyservers.net --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90 2EBF997C15BDA244B6EBF5D84773BD5E130D1D45
    yay -S spotify
}

install_qemu()
{
    echo "Installing QEMU/KVM"
    sudo pacman -S libvirt virt-manager ovmf qemu

    sudo systemctl enable --now libvirtd.service
    sudo systemctl enable --now virtlogd.socket

    # Enable Virtualization Technology for Directed I/O in rEFInd config as boot param
    sudo sed -i.bak 's/linux-zen.img[^"]*/& intel_iommu=on/' /boot/refind_linux.conf

    sudo usermod -a -G libvirt paul
}

read -p 'Do you want to install Deepin [y/N]: ' installDE
if  [ $installDE = 'y' ]
then 
    install_DE
fi

read -p 'Do you want to install some apps? [y/N]: ' installapps
if  [ $installapps = 'y' ] 
then 
    install_apps
fi

read -p 'Do you want to install QEMU/KVM? [y/N]: ' installqemu
if  [ $installqemu = 'y' ] 
then 
    install_qemu
fi

echo "Post install complete. Enjoy!"