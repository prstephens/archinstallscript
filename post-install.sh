#! /bin/bash

echo "Paul's Arch Configurator - Post Installer"

install_deepin()
{
    # Deepin and VS Code
    echo "Installing Deepin..."
    sudo pacman -S deepin deepin-extra

    # Deepin Arch update notifier
    echo "Installing Deepin update notifier plugin..."
    yay -S deepin-dock-plugin-arch-update

    # xinitrc config
    echo "exec startdde" >> /home/paul/.xinitrc

    # Fix Pulseaudio
    rm -rfd /home/paul/.config/pulse
    sudo echo "set-default-sink output alsa_output.pci-0000_00_1f.3.analog-stereo" >> /etc/pulse/default.pa
}

install_apps()
{
    # chrome
    echo "Installing Chrome, VS Code and WPS Office..."
    yay -S google-chrome code wps-office

     # Spotify
    echo "Installing Spotify..."
    gpg --keyserver pool.sks-keyservers.net --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90 2EBF997C15BDA244B6EBF5D84773BD5E130D1D45
    yay -S spotify
}

if [ -d "/home/paul/yay" ]
then
  echo "Installing yay..."
  cd /home/paul/yay
  makepkg -si
  cd ..
  rm -rfd yay
fi

read -p 'Do you want to install Deepin DE? [y/N]: ' installdeepin
if  [ $installdeepin = 'y' ] && [ $installdeepin = 'Y' ]
then 
    install_deepin
fi

read -p 'Do you want to install some apps? [y/N]: ' installapps
if  [ $installapps = 'y' ] && [ $installapps = 'Y' ]
then 
    install_apps
fi

echo "Post install complete. Enjoy!"