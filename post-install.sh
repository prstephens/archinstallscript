#! /bin/bash

echo "Paul's Arch Configurator - Post Installer"

function install_deepin()
{
    # Deepin and VS Code
    sudo pacman -S deepin deepin-extra code

    # Deepin Arch update notifier
    yay -S deepin-dock-plugin-arch-update

    # chrome
    yay -S google-chrome

    # xinitrc config
    echo "exec startdde" >> /home/paul/.xinitrc
}

echo "Installing yay..."
cd /home/paul/yay
makepkg -si

# turn off flipping on NVIDIA
echo "Turning off Nvidia flipping..."
nvidia-settings -a AllowFlipping=0

read -p 'Do you want to install Deepin DE and other awesome apps? [y/N]: ' installdeepin
if  [ $installdeepin = 'y' ] && ! [ $installdeepin = 'Y' ]
then 
    install_deepin
fi

echo "Post install complete. Enjoy!"