#!/bin/bash

# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
# To silent an error || true
set -euo pipefail
IFS=$'\n\t'

if [ "${1:-}" = "--debug" ] || [ "${1:-}" = "-d" ]; then
	set -x
fi

###############################################################################
# Questions part
###############################################################################

if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "
You're about to install my basic user session.
Require a xf86-video driver, an internet connection, base and base-devel packages.
Please enter 'yes' to confirm:
"
read -r -r yes

# Confirm video driver
if [ "$yes" != "yes" ]; then
    echo "Please install a xf86-video driver"
	pacman -Ss xf86-video
    exit 1
fi

# Check internet connection
if ! [ "$(ping -c 1 8.8.8.8)" ]; then
    echo "Please check your internet connection"
    exit 1
fi

if ! source install.conf; then

	echo "Please enter hostname:"
	read -r hostname

	echo "Please enter username:"
	read -r username

	echo "Please enter root password:"
	read -r -s password

	echo "Please repeat root password:"
	read -r -s password2

	# Check both passwords match
	if [ "$password" != "$password2" ]; then
	    echo "Passwords do not match"
	    exit 1
	fi

	echo "Please enter git username:"
	read -r git_username

	echo "Please enter email:"
	read -r email
fi

# Save current pwd
pwd=$(pwd)

echo "
###############################################################################
# Pacman conf
###############################################################################
"

pacman -Syyu

sed -i 's/^#Color/Color/' /etc/pacman.conf

echo "
###############################################################################
# Install part
###############################################################################
"

pacman_packages=()

# Install core stuff
pacman_packages+=( base-devel grub unzip efibootmgr os-prober amd-ucode )

# Install X essentials
pacman_packages+=( libinput xorg-xinput xorg-xrandr)

# Install font essentials
pacman_packages+=( cairo fontconfig freetype2 )

# Install internet and network
pacman_packages+=( networkmanager gnome-keyring wget )

# Install shell and terminals
pacman_packages+=( fish kitty )

# Install linux fonts
pacman_packages+=( adobe-source-code-pro-fonts otf-cascadia-code )

# Install window manager
pacman_packages+=( qtile htop sddm light feh neofetch )

# Install dev tools
pacman_packages+=( vim code zathura zathura-pdf-mupdf )

# Install work tools
pacman_packages+=( docker git )

# Install browser
pacman_packages+=( qutebrowser )

# Install audio
pacman_packages+=( alsa-utils pulseaudio alsa-lib pavucontrol alsa-plugins )

pacman --noconfirm --needed -S  "${pacman_packages[@]}"

echo "
###############################################################################
# Systemd part
###############################################################################
"
# Generate locales
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

hwclock --systohc

# Set timezone
timedatectl --no-ask-password set-timezone Asia/Kolkata

echo "LANG=en_US.UTF-8" > /etc/locale.conf

hostnamectl --no-ask-password set-hostname "$hostname"

echo "
###############################################################################
# Modules
###############################################################################
"
echo "
###############################################################################
# User part
###############################################################################
"

# Create user with home
if ! id -u "$username"; then
	useradd -m --groups users,wheel,docker,video,input "$username"
	echo "$username:$password" | chpasswd
	chsh -s /bin/bash "$username"
fi

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

echo "
###############################################################################
# Install user
###############################################################################
"

echo "
###############################################################################
# Cleaning
###############################################################################
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Clean orphans pkg
if [[ -z $(pacman -Qdt) ]]; then
	echo "No orphans to remove."
else
	pacman -Rns "$(pacman -Qdtq)"
fi

echo "Configuring GRUB"
mkdir /boot/efi
echo "Enter your Linux main partition (example 'sda2'):"
read -r partition
mount /dev/"$partition" /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
os-prober

# Replace in the same state
cd "$pwd"
echo "Running git configurations"

git config --global user.username "$git_username"
git config --global user.email "$email"

echo "Installing docker-compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

git clone https://github.com/IgnisDa/linux-configs.git /tmp/.config
cp -r /tmp/.config /home/"$username"/.config

mkdir -p /home/"$username"/work/projects/

systemctl enable sddm
systemctl enable NetworkManager
systemctl enable docker

git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay/
makepkg -si

echo "
###############################################################################
# Done, please reboot now
###############################################################################
"
