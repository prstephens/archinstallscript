#! /bin/bash

echo "Paul's Arch Configurator - Post Installer"

# Update pacman mirroe list
reflector -c GB --latest 25 --age 24 --protocol https --completion-percent 100 --sort rate --save /etc/pacman.d/mirrorlist

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

sed -i 's/Windows 10 (on /dev/md126p1)/Windows 10/' /etc/default/grub

# Create new user
useradd -m -G wheel paul
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo "Set password for new user paul"
passwd paul

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
cp /etc/X11/xinit/xinitrc /home/paul/.xinitrc
head -n -5 /home/paul/.xinitrc >> /home/paul/.xinitrc

# Enable services
echo "Enabling services..."
systemctl enable NetworkManager.service
systemctl enable systemd-swap

echo "Configuration done. You can now exit chroot."