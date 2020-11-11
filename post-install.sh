#! /bin/bash

install_fonts()
{
    echo "Installing fonts..."
    yay -S nerd-fonts-complete otf-san-francisco

    sudo curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/fonts/Youth-Touch.ttf -o /usr/share/fonts/Youth-Touch.ttf

     # Copy Windows fonts over
    echo "Copying Windows fonts..."
    sudo mkdir /usr/share/fonts/windowsfonts
    sudo mkdir /windows10
    sudo mount /dev/sda3 /windows10
    sudo cp /windows10/Windows/Fonts/* /usr/share/fonts/windowsfonts
    fc-cache -f
    sudo umount /windows10
}

install_preload()
{
    echo "Installing preload..."
    yay -S preload
    sudo systemctl enable --now preload
}

install_lightdm()
{
    echo "Installing glorious lightdm theme..."
    yay -S lightdm-webkit2-theme-glorious lightdm
    sudo sed -i 's/^#greeter-session=.*$/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf
    sudo sed -i 's/^debug_mode.*$/debug_mode=true/' /etc/lightdm/lightdm-webkit2-greeter.conf
    sudo sed -i 's/^webkit_theme.*$/webkit_theme=glorious/' /etc/lightdm/lightdm-webkit2-greeter.conf
    sudo systemctl enable lightdm
}

install_ufw()
{
    echo "Enabling firewall..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw allow dns
    sudo ufw allow ntp
    sudo ufw enable
}

install_deepin()
{
    dialog --title 'Installing Deepin...' --msgbox 'Please select deepin-anything-dkms when prompted' 6 50
    clear
    
    # Deepin, nightlight, android phone protocols
    sudo pacman -S deepin deepin-compressor redshift pacman-contrib mtpfs gvfs-mtp gvfs-gphoto2 gvfs-smb file-roller
    yay -S jmtpfs

    # Deepin Arch update notifier
    echo "Installing Deepin update notifier plugin..."
    yay -S deepin-dock-plugin-arch-update

    # xinit config
    echo "exec startdde" >> $HOME/.xinitrc
    echo '[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> $HOME/.bash_profile

    install_fonts
    install_ufw
    install_preload
}

install_plasma()
{    
    echo "Installing Plasma.."
    # Deepin, nightlight, android phone protocols
    sudo pacman -S plasma

    # xinit config
    sudo cat <<EOT >> $HOME/.xinitrc
export DESKTOP_SESSION=plasma
exec startplasma-x11
EOT
    echo '[[ ! $DISPLAY && $XDG_VTNR -eq 2 ]] && exec startx' >> $HOME/.bash_profile

}

install_spotify()
{
    echo "Installing Spotify..."
    #gpg --keyserver pool.sks-keyservers.net --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90 2EBF997C15BDA244B6EBF5D84773BD5E130D1D45
    curl -sS https://download.spotify.com/debian/pubkey.gpg | gpg --import -
    yay -S spotify spicetify-cli spicetify-themes-git
    sudo chmod -R 777 /opt/spotify
    spicetify backup apply
    spicetify config extensions dribbblish.js
    spicetify config current_theme Dribbblish color_scheme horizon
    spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
    spicetify apply
}

install_profile-sync-daemon()
{
    sudo pacman -S profile-sync-daemon
    psd
    sed -i 's/^#BROWSERS=.*$/BROWSERS=(google-chrome)/' $HOME/.config/psd/psd.conf
    sed -i 's/^#USE_OVERLAYFS=.*$/USE_OVERLAYFS="yes")/' $HOME/.config/psd/psd.conf
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper" | sudo tee -a /etc/sudoers
    systemctl --user enable --now psd.service
}

install_apps()
{
    echo "Installing Chrome, VS Code, WPS Office, Gimp..."
    yay -S google-chrome firefox code wps-office gimp vlc

    install_spotify
    install_profile-sync-daemon
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
    echo "Installing Development tools... IntelliJ, Java, gradle"
    sudo pacman -S jre11-openjdk jdk11-openjdk gradle intellij-idea-community-edition
    yay -S postman-bin
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
    2 "Plasma DE"
    3 "Lightdm Display Manager"
    4 "Applications"
    5 "QEMU/KVM"
    6 "Java Development Environment"  
    7 "Exit")

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
            install_plasma
            ;;
        3)
            install_lightdm
            ;;
        4)
            install_apps
            ;;
        5)
            install_qemu
            ;;
        6)
            install_dev
            ;;	   	    
	    7)
            break
            ;;
    esac
done