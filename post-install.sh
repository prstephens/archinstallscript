#! /bin/bash

echo "Paul's Arch Configurator - Post Installer"

install_DE()
{
    # Deepin and VS Code
    echo "Installing Deepin..."
    read -p 'Please select deepin-anythin-dkms when prompted. Press any key to continue...' installDE
    sudo pacman -S deepin deepin-extra redshift

    # Deepin Arch update notifier
    echo "Installing Deepin update notifier plugin..."
    yay -S deepin-dock-plugin-arch-update

    # xinitrc config
    echo "exec startdde" >> $HOME/.xinitrc

    # Install Plasma (as a backup)
    #echo "Installing Plasma..."
    #sudo pacman -S plasma

    echo "Installing preload..."
    yay -S preload
    systemctl enable --now preload

    echo "Installing fonts..."
    yay -S nerd-fonts-complete otf-san-francisco
}

install_apps()
{
    # chrome
    echo "Installing Chrome, VS Code WPS Office and Gimp..."
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

# git credentials
git config --global credential.helper store

# config files
curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/.Xresources -o $HOME/.Xresources
curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/.bashrc -o $HOME/.bashrc

# setup 'dotfiles'
#git clone --bare https://github.com/prstephens/.dotfiles.git $HOME/.dotfiles
#alias dotfiles='/usr/bin/git --git-dir=/home/paul/.dotfiles/ --work-tree=/home/paul'
#dotfiles config --local status.showUntrackedFiles no
#dotfiles checkout

read -p 'Do you want to install Deepin and Plasma DE? [y/N]: ' installDE
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