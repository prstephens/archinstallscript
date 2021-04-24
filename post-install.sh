#! /bin/bash

install_fonts()
{
    echo "Installing fonts..."
    #yay -S nerd-fonts-complete
    yay -S otf-san-francisco

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

install_deepin()
{
    clear
    
    # Deepin, nightlight
    sudo pacman -S deepin deepin-compressor redshift pacman-contrib file-roller
    yay -S jmtpfs

    # Deepin Arch update notifier
    echo "Installing Deepin update notifier plugin..."
    yay -S deepin-dock-plugin-arch-update

    # xinit config
sudo cat <<EOT >> $HOME/.xinitrc
nvidia-settings --load-config-only &
exec startdde
EOT

    echo '[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> $HOME/.bash_profile

    install_fonts
    install_preload
}

restore_bigsur()
{
    konsave -i $HOME/bigsur.knsv
    konsave -a 1
}

install_plasma()
{    
    clear
    
    echo "Installing Plasma.."
    sudo pacman -S plasma ark dolphin xscreensaver konsole sshfs
    yay -S latte-dock-git plasma5-applets-kde-arch-update-notifier-git
    
    # konsave
    sudo pacman -S python-pip
    python -m pip install konsave

    # mac os big sur dark theme with latte config. complete restore.
    curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/bigsur.knsv -o $HOME/bigsur.knsv

    # xscreensaver settings - 10 min timeout - GL matrix 
    curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/.xscreensaver -o $HOME/.xscreensaver

    # Dracula colour scheme for Konsole
    curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/Dracula.colorscheme -o $HOME/.local/konsole/Dracula.colorscheme

    # xinit config
    sudo cat <<EOT >> $HOME/.xinitrc
nvidia-settings --load-config-only &
export DESKTOP_SESSION=plasma
exec startplasma-x11
EOT
    echo '[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> $HOME/.bash_profile
    
    install_fonts
    install_preload

    # apply MacOs bigsur theme
    restore_bigsur
}

install_spotify()
{
    echo "Installing Spotify..."
    curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | gpg --import -
    yay -S spotify spicetify-cli spicetify-themes-git
    sudo chmod -R 777 /opt/spotify
}

apply_spicetify()
{
    spicetify backup apply
    spicetify config extensions dribbblish.js
    spicetify config current_theme Dribbblish color_scheme dracula
    spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
    spicetify apply
}

install_profile-sync-daemon()
{
    sudo pacman -S profile-sync-daemon
    psd
    sed -i 's/^#BROWSERS=.*$/BROWSERS=(google-chrome)/' $HOME/.config/psd/psd.conf
    sed -i 's/^#USE_OVERLAYFS=.*$/USE_OVERLAYFS="yes"/' $HOME/.config/psd/psd.conf
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/psd-overlay-helper" | sudo tee -a /etc/sudoers
    systemctl --user enable --now psd.service

    # asd config
    sudo sed -i "s/^WHATTOSYNC=.*$/WHATTOSYNC=('\/home\/paul\/.cache')/" /etc/asd.conf
    sudo sed -i 's/^#USE_OVERLAYFS=.*$/USE_OVERLAYFS="yes"/' /etc/asd.conf
    sudo sed -i 's/^#VOLATILE=.*$/VOLATILE="/dev/shm")/' /etc/asd.conf
    sudo systemctl enable --now asd
}

install_apps()
{
    echo "Installing Chrome, VS Code, WPS Office, Gimp..."
    yay -S google-chrome firefox code wps-office gimp vlc balena-etcher kodi dropbox handbrake pamac-aur

    install_spotify
    apply_spicetify
    install_profile-sync-daemon
}

install_qemu()
{
    echo "Installing QEMU/KVM"
    sudo pacman -S libvirt virt-manager ovmf qemu iptables-nft dnsmasq

    # Enable Virtualization Technology for Directed I/O in rEFInd config as boot param
    sudo sed -i.bak 's/linux.img[^"]*/& intel_iommu=on/' /boot/refind_linux.conf

    sudo usermod -a -G libvirt $USER

sudo bash -c 'sudo cat <<EOT >> /etc/libvirt/qemu.conf
nvram = [
	"/usr/share/ovmf/x64/OVMF_CODE.fd:/usr/share/ovmf/x64/OVMF_VARS.fd"
]
EOT'

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

# optimise yay when building packages
sudo sed -i 's/^#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
sudo sed -i "s/^PKGEXT=.*$/PKGEXT='.pkg.tar'/" /etc/makepkg.conf

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