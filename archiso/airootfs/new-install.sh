#!/bin/bash

# INSTRUCTIONS
# Follow the installation instructions up-to "Configure the system"
# https://wiki.archlinux.org/index.php/installation_guide#Configure_the_system,
# then copy this file to /mnt using `cp /Arch-Linux_installer.sh /mnt` and
# `arch-chroot /mnt` and then `./Arch-Linux_installer.sh` to configure the
# system according to your needs.

# Setting color variables

colored_echo(){
    Red='\033[0;31m'
    Green='\033[0;32m'
    Yellow='\033[0;33m'
    Blue='\033[0;34m'
    NC="\033[0m" # No Color
    printf "%b%b%b\n" "${!1}" "${2}" "${NC}"
}


# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
# To silent an error || true
set -euo pipefail
IFS=$'\n\t'

if [ "${1:-}" = "--debug" ] || [ "${1:-}" = "-d" ]; then
	set -x
fi

colored_echo "Green" "
###############################################################################
# Questions part
###############################################################################
"

if [ $EUID -ne 0 ]; then
   colored_echo "Red" "This script must be run as root" 1>&2
   exit 1
fi

colored_echo "Yellow" "
You're about to install my basic user session.
Require a xf86-video driver, an internet connection, base and base-devel packages.
Please enter 'yes' to confirm:
"
read -r yes

# Confirm video driver
if [ "$yes" != "yes" ]; then
    colored_echo "Yellow" "Please install a xf86-video driver"
	pacman -Ss xf86-video
    exit 1
fi

# Check internet connection
if ! [ "$(ping -c 1 8.8.8.8)" ]; then
    colored_echo "Yellow" "Please check your internet connection"
    exit 1
fi

if ! source install.conf; then

	colored_echo "Yellow" "Please enter hostname:"
	read -r hostname

	colored_echo "Yellow" "Please enter username:"
	read -r username

	colored_echo "Yellow" "Please enter root password:"
	read -r -s password

	colored_echo "Yellow" "Please repeat root password:"
	read -r -s password2

	# Check both passwords match
	if [ "$password" != "$password2" ]; then
	    colored_echo "Yellow" "Passwords do not match"
	    exit 1
	fi

	colored_echo "Yellow" "Please enter git username:"
	read -r git_username

	colored_echo "Yellow" "Please enter git email:"
	read -r email
fi

# Save current pwd
pwd=$(pwd)

colored_echo "Green" "
###############################################################################
# Pacman conf
###############################################################################
"

pacman -Syyu

sed -i 's/^#Color/Color/' /etc/pacman.conf

colored_echo "Green" "
###############################################################################
# Install part
###############################################################################
"

pacman_packages=()

# Install core stuff
pacman_packages+=( base-devel grub unzip efibootmgr os-prober amd-ucode )

# Install X essentials
pacman_packages+=( libinput xorg-xinput xorg-xrandr xf86-input-libinput)

# Install font essentials
pacman_packages+=( cairo fontconfig freetype2 )

# Install internet and network
pacman_packages+=( networkmanager gnome-keyring wget iw )

# Install shell and terminals
pacman_packages+=( fish alacritty ranger )

# Install linux fonts
pacman_packages+=( adobe-source-code-pro-fonts otf-cascadia-code )

# Install window manager
pacman_packages+=( awesome htop sddm light feh neofetch bat exa )

# Install dev tools
pacman_packages+=( vim flameshot )

# Install work tools
pacman_packages+=( git virtualbox virtualbox-host-modules-arch vagrant python-pip )

# Install audio
pacman_packages+=( alsa-utils pulseaudio alsa-lib pavucontrol alsa-plugins )

# Install music stuff
pacman_packages+=( mpd )

pacman --noconfirm --needed -S  "${pacman_packages[@]}"

colored_echo "Green" "Setting up touch-pad controls"

mkdir -p "/etc/X11/xorg.conf.d/"

tee -a /etc/X11/xorg.conf.d/30-touchpad.conf << END
Section "InputClass"
        Identifier "MyTouchpad"
        MatchIsTouchpad "on"
        Driver "libinput"
        Option "Tapping" "on"
EndSection
END

colored_echo "Green" "Setting up emoji fonts"

curl -sSL https://raw.githubusercontent.com/IgnisDa/linux-configs/master/scripts/setup-emojifonts.sh -o ./setup-emojifonts.sh
chmod +x setup-emojifonts.sh
./setup-emojifonts.sh

colored_echo "Green" "
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

colored_echo "Green" "
###############################################################################
# Modules
###############################################################################
"
colored_echo "Green" "
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

colored_echo "Green" "
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
	colored_echo "Red" "No orphans to remove."
else
	pacman -Rns "$(pacman -Qdtq)"
fi

# Replace in the same state
cd "$pwd"

colored_echo "Green" "
###############################################################################
# Install user
###############################################################################
"

colored_echo "Green" "Installing docker-compose"
curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

git clone https://github.com/IgnisDa/linux-configs.git /tmp/.config
cp -r /tmp/.config /home/"$username"/.config
chown -R $username:$username -R /home/$username/.config/

mkdir -p /home/"$username"/work/projects/
mkdir -p /home/"$username"/work/tutorials/
mkdir -p /home/"$username"/work/learning/
chown -R $username:$username -R /home/$username/work/

systemctl enable sddm
systemctl enable NetworkManager
systemctl enable docker
pip install commitizen cookiecutter

bashRC=/home/"$username"/.bashrc

echo "" >> $bashRC
echo "# if [[ \$(ps --no-header --pid=\$PPID --format=cmd) != \"fish\" ]]" >> $bashRC
echo "# then" >> $bashRC
echo "# 	exec fish" >> $bashRC
echo "# fi" >> $bashRC

colored_echo "Yellow" "Would you like to add a new password for $username? (yes/no)"
read -r yes
if [ "$yes" != "yes" ]; then
    colored_echo "Yellow" "Skipping this step"
else
	colored_echo "Yellow" "Please enter $username's new password:"
	read -r -s password
	colored_echo "Yellow" "Please repeat $username's new password:"
	read -r -s password2
	if [ "$password" != "$password2" ]; then
	    colored_echo "Yellow" "Passwords do not match"
	    exit 1
	fi
	echo "$username:$password" | chpasswd
	git clone https://aur.archlinux.org/yay.git /home/$username/yay
	cd /home/$username/yay/
	colored_echo "Green" "Running git configurations"
	sudo -u git config --global user.username "$git_username"
	sudo -u git config --global user.email "$email"
	sudo -u git config --global pull.rebase "true"
	sudo -u git config --global core.editor "vim"
	sudo -u $username makepkg -si --noconfirm
	sudo -u $username yay -S --answerdiff=None --noconfirm visual-studio-code-bin google-chrome picom-tryone-git neovim-nightly-bin
fi


colored_echo "Red" "
###############################################################################
# Please run these commands accordingly to configure grub
###############################################################################
# mkdir /boot/efi
# mount /dev/main-partition /boot/efi
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
# grub-mkconfig -o /boot/grub/grub.cfg
# os-prober
###############################################################################
"

colored_echo "Red" "
###############################################################################
# Done, please reboot now!
###############################################################################
"
