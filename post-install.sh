#! /bin/bash

echo "Paul's Arch Configurator"

# Update pacman mirroe list
reflector -c GB --latest 25 --age 24 --protocol https --completion-percent 100 --sort rate --save /etc/pacman.d/mirrorlist

# Set date time
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

# Set locale to en_US.UTF-8 UTF-8
sed -i '/en_GB.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" >> /etc/locale.conf

# Set hostname
echo "archpc" >> /etc/hostname
echo "127.0.1.1 archpc.localdomain  archpc" >> /etc/hosts

# Generate initramfs
echo "HOOKS in mkinitcpio.conf need mdadm_udev added"
mkinitcpio -p

# Set root password
echo "Set root password"
passwd

# Install bootloader
grub-install --target=i386-pc /dev/md/RAIDVOL1_0
grub-mkconfig -o /boot/grub/grub.cfg

# Create new user
useradd -m -G wheel paul
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo "Set password for new user paul"
passwd paul

# Install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Enable services
systemctl enable NetworkManager.service

echo "Configuration done. You can now exit chroot."