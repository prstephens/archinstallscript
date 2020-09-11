#! /bin/bash

echo "Paul's Arch Configurator - Post Installer"

echo "Updating pacman mirrors to awesomeness..."
# Update pacman mirror list
reflector --verbose -c GB -l 25 --age 12 -p http -p https --sort rate --save /etc/pacman.d/mirrorlist

echo "Setting up spacetime continuum..."
# Set date time
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

# Set locale to en_US.UTF-8 UTF-8
sed -i '/en_GB.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" >> /etc/locale.conf

# Set the console keymap
echo "KEYMAP=uk" >> /etc/vconsole.conf

# Set hostname
echo "archpc" >> /etc/hostname
echo "127.0.1.1 archpc.localdomain  archpc" >> /etc/hosts

# Generate initramfs
echo "HOOKS in mkinitcpio.conf need mdadm_udev added for RAID detection..."
HOOKS="base udev autodetect modconf block mdadm_udev filesystems keyboard fsck"
sed -i "s/^HOOKS=(.*)$/HOOKS=($HOOKS)/" /etc/mkinitcpio.conf
mkinitcpio -P

# Set root password
echo "Set root password"
passwd

# Install bootloader
echo "Installing grub..."
grub-install --target=i386-pc --recheck /dev/md/RAIDVOL1_0
sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT="Windows 10"/' /etc/default/grub
sed -i 's/GRUB_GFXMODE=auto/GRUB_GFXMODE=1920x1080/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# make grub look pretty
curl -LO https://github.com/mateosss/matter/releases/latest/download/matter.zip
unzip matter.zip
rm matter.zip
cd matter
./matter.py -i arch folder _ _ microsoft-windows -hl white -fg f0f0f0 -bg ff0d7b
sed -i 's/Windows 10 (on \/dev\/md126p1)/Windows 10/' /boot/grub/grub.cfg

# Create new user
useradd -m -G wheel paul
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo "Set password for new user paul"
passwd paul

# config files
echo "Getting some sweet config files..."
mkdir /home/paul/.config
curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/.Xresources -o /home/paul/.Xresources
curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/.bashrc -o /home/paul/.bashrc
curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/issue -o /etc/issue
curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/reflector.service -o /etc/systemd/system/reflector.service
curl https://raw.githubusercontent.com/prstephens/archinstallscript/master/sweet/kwinrc -o /home/paul/.config/kwinrc

# Set keyboard FN keys to act normal!
echo "options hid_apple fnmode=2" > /etc/modprobe.d/hid_apple.conf

# Get yay ready 
echo "Getting yay all ready for paul..."
git clone https://aur.archlinux.org/yay.git /home/paul/yay
chown -R paul /home/paul/yay/

# Copy post-install file to /home/paul
echo "Copy post-install file to /home/paul..."
cp -rfv /root/post-install.sh /home/paul/
chmod a+x /home/paul/post-install.sh

# Create user xinit config file 
echo "Creating .xinitrc file..."
head -n -5 /etc/X11/xinit/xinitrc >> /home/paul/.xinitrc
chown paul:paul /home/paul/.xinitrc

# Create swapfile
echo "Creating swap file..."
dd if=/dev/zero of=/swapfile bs=1M count=512 status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

# Set correct sound card for PulseAudio
sudo echo "set-default-sink output alsa_output.pci-0000_00_1f.3.analog-stereo" >> /etc/pulse/default.pa

# Copy Windows fonts over
echo "Copying Windows fonts..."
mkdir /usr/share/fonts/windowsfonts
mkdir /windows10
mount /dev/md/RAIDVOL1_0p2 /windows10
cp /windows10/Windows/Fonts/* /usr/share/fonts/windowsfonts
fc-cache -f
umount /windows10

# Enable services
echo "Enabling services..."
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable org.cups.cupsd.service
systemctl enable reflector
systemctl enable reflector.timer
#systemctl enable fstrim.timer

echo "Configuration done. You can now exit chroot."