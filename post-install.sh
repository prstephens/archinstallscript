#! /bin/bash

echo "Paul's Arch Configurator - Post Installer"

function install_deepin()
{
    # Deepin and VS Code
    echo "Installing Deepin..."
    sudo pacman -S deepin deepin-extra

    # Deepin Arch update notifier
    echo "Installing Deepin update notifier plugin..."
    yay -S deepin-dock-plugin-arch-update

    # xinitrc config
    echo "exec startdde" >> /home/paul/.xinitrc
}

function install_apps()
    # chrome
    echo "Installing Chrome..."
    yay -S google-chrome code

     # Spotify
    echo "Installing Spotify..."
    gpg --keyserver pool.sks-keyservers.net --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90 2EBF997C15BDA244B6EBF5D84773BD5E130D1D45
    yay -S spotify

    # WPS Office
    echo "Installing WPS Office..."
    yay -S wps-office
}

echo "Installing yay..."
cd /home/paul/yay
makepkg -si
cd ..
rm -rfd yay

read -p 'Do you want to install Deepin DE? [y/N]: ' installdeepin
if  [ $installdeepin = 'y' ] && ! [ $installdeepin = 'Y' ]
then 
    install_deepin
fi

echo "Post install complete. Enjoy!"