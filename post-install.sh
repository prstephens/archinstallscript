#! /bin/bash

echo "Paul's Arch Configurator - Post Installer"

install_DE()
{
    # Deepin and VS Code
    echo "Installing Deepin..."
    read -p 'Please select deepin-anything-dkms when prompted. Press any key to continue...' installDE
    sudo pacman -S deepin deepin-extra redshift systemsettings

    # Deepin Arch update notifier
    echo "Installing Deepin update notifier plugin..."
    yay -S deepin-dock-plugin-arch-update

    # xinitrc config
    echo "exec startdde" >> $HOME/.xinitrc

    echo "Installing fonts..."
    yay -S nerd-fonts-complete otf-san-francisco
}

install_apps()
{
    # chrome
    echo "Installing Chrome, VS Code, WPS Office, Gimp..."
    yay -S google-chrome code wps-office gimp

     # Spotify
    echo "Installing Spotify..."
    gpg --keyserver pool.sks-keyservers.net --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90 2EBF997C15BDA244B6EBF5D84773BD5E130D1D45
    yay -S spotify
}

if [ -d "/home/paul/yay" ]
then
  echo "Installing yay..."
  cd $HOME/yay
  makepkg -si
  cd ..
  rm -rfd yay
fi

echo "Installing preload..."
yay -S preload
systemctl enable --now preload

# git credentials
git config --global credential.helper store
git config --global user.email "pr.stephens@gmail.com"
git config --global user.name "prstephens"

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

echo "Post install complete. Enjoy!"