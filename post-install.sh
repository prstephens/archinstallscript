#! /bin/bash

clear
echo "Paul's Arch Configurator - Post Installer"

install_DE()
{
    # Deepin
    echo "Installing Deepin..."
    read -p 'NOTE: Please select deepin-anything-dkms when prompted. Press any key to continue...' installDE
    sudo pacman -S deepin deepin-extra redshift systemsettings

    # Deepin Arch update notifier
    echo "Installing Deepin update notifier plugin..."
    yay -S deepin-dock-plugin-arch-update

    # xinit config
    echo "exec startdde" >> $HOME/.xinitrc
    echo '[[ ! $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> $HOME/.bash_profile

    echo "Installing fonts..."
    yay -S nerd-fonts-complete otf-san-francisco

    echo "Installing glorious lightdm theme..."
    yay -S lightdm-webkit2-theme-glorious
    sudo sed -i 's/^#greeter-session=.*$/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf
    sudo sed -i 's/^debug_mode.*$/debug_mode=true/' /etc/lightdm/lightdm-webkit2-greeter.conf
    sudo sed -i 's/^webkit_theme.*$/webkit_theme=glorious/' /etc/lightdm/lightdm-webkit2-greeter.conf
    sudo systemctl enable lightdm
}

install_apps()
{
    echo "Installing Chrome, VS Code, WPS Office, Gimp..."
    yay -S google-chrome firefox code wps-office gimp

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
sudo systemctl enable --now preload

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