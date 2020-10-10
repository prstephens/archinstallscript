#! /bin/bash

install_deepin()
{
    # Deepin
    dialog --title 'Installing Deepin...' --msgbox 'Please select deepin-anything-dkms when prompted' 6 50
    clear
    
    sudo pacman -S deepin deepin-compressor redshift pacman-contrib

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
    #gpg --keyserver pool.sks-keyservers.net --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90 2EBF997C15BDA244B6EBF5D84773BD5E130D1D45
    curl -sS https://download.spotify.com/debian/pubkey.gpg | gpg --import -
    yay -S spotify

    # Install psd
    sudo pacman -S profile-sync-daemon
    psd
    sed -i 's/^#BROWSERS=.*$/BROWSERS=(google-chrome)/' $HOME/.config/psd/psd.conf
    sed -i 's/^#USE_OVERLAYFS=.*$/USE_OVERLAYFS="yes")/' $HOME/.config/psd/psd.conf
    systemctl --user enable --now psd.service
}

install_qemu()
{
    echo "Installing QEMU/KVM"
    sudo pacman -S libvirt virt-manager ovmf qemu

    # Enable Virtualization Technology for Directed I/O in rEFInd config as boot param
    sudo sed -i.bak 's/linux-zen.img[^"]*/& intel_iommu=on/' /boot/refind_linux.conf

    sudo usermod -a -G libvirt $USER

sudo cat <<EOT >> /etc/libvirt/qemu.conf
nvram = [
	"/usr/share/ovmf/x64/OVMF_CODE.fd:/usr/share/ovmf/x64/OVMF_VARS.fd"
]
EOT

    sudo systemctl enable --now libvirtd.service
    sudo systemctl enable --now virtlogd.socket
}

install_dev()
{
    echo "Installing Development tools... IntelliJ, Java gradle"
    sudo pacman -S jre11-openjdk jdk11-openjdk gradle intellij-idea-community-edition
}

#=== START ===
if [[ -d $HOME/yay ]]
then
  echo "Installing yay..."
  cd $HOME/yay
  makepkg -si
  cd ..
  rm -rfd yay
fi

# git credentials
git config --global credential.helper store
git config --global user.email "pr.stephens@gmail.com"
git config --global user.name "prstephens"

# Dialog menu
HEIGHT=15
WIDTH=50
CHOICE_HEIGHT=4
BACKTITLE="Arch Linux Post Installer"
TITLE="Arch Linux Post Installer"
MENU="Choose one of the following options to install:"

OPTIONS=(1 "Deepin DE"
    2 "Applications"
    3 "QEMU/KVM"
    4 "Java Development Environment"  
    5 "Exit")

while CHOICE=$(dialog --clear \
        --nocancel \
        --backtitle "$BACKTITLE" \
        --title "$TITLE" \
        --menu "$MENU" \
        $HEIGHT $WIDTH $CHOICE_HEIGHT \
        "${OPTIONS[@]}" \
    2>&1 >/dev/tty)
clear
do
    case $CHOICE in
        1)
            install_deepin
            ;;
        2)
            install_apps
            ;;
        3)
            install_qemu
            ;;
        4)
            install_dev
            ;;	   	    
	    5)
            break
            ;;
    esac
done