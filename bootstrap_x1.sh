#!/usr/bin/env zsh

# = set keyboard layout
loadkeys sv-latin1

# = Update the system clock
timedatectl set-timezone Europe/Stockholm
timedatectl set-ntp true


###################################################
# = Partition the disks
#
# +-----------------------------------------------+
# | Logical volume 1      | Logical volume 2      |
# |                       |                       |
# | [SWAP]                | /                     |
# |                       |                       |
# | /dev/vg.main/swap        | /dev/tank/root        |
# |_ _ _ _ _ _ _ _ _ _ _ _|_ _ _ _ _ _ _ _ _ _ _ _|
# |                                               |
# |           LUKS2 encrypted partition           |
# |           $CRYPTROOT_PARTITION                |
# +-----------------------------------------------+

DISK=/dev/nvme0n1
BOOT_PARTITION="${DISK}p1"
CRYPTROOT_PARTITION="${DISK}p2"

SWAP_VOLUME=/dev/vg.main/swap

# == Remove all partitions
sgdisk --zap-all ${DISK}

# == Create partitions
sgdisk --clear \
       --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI \
       --new=2:0:0 --typecode=2:8309 --change-name=2:cryptroot \
       ${DISK}

# == Setup disk encryption following LVM-on-LUKS approach
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
cryptsetup -y -v luksFormat ${CRYPTROOT_PARTITION}
cryptsetup open ${CRYPTROOT_PARTITION} cryptlvm

## == Initialise physical volume for use with LVM
pvcreate /dev/mapper/cryptlvm
## == create volume group called "vg.main"
vgcreate vg.main /dev/mapper/cryptlvm
## == create logical volume for [swap]
lvcreate -L 35G vg.main -n swap
## == create logical volume for /
lvcreate -l 100%FREE vg.main -n root

# Format partitions
## root partition
mkfs.btrfs /dev/vg.main/root
mount /dev/vg.main/root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log

## swap partition
mkswap ${SWAP_VOLUME}
swapon ${SWAP_VOLUME}

## boot partition
mkfs.fat -F32 -n EFI ${BOOT_PARTITION}

# Mount file systems
mount -o subvol=@ /dev/vg.main/root /mnt
mkdir -p /mnt/{boot,home}
mount -o subvol=@home /dev/vg.main/root /mnt/home
mount ${BOOT_PARTITION} /mnt/boot


# == select mirrors
reflector --country Sweden --country Norway --country Danmark --country Germany --country Finland --age 12 --protocol https --sort rate -n 5 --save /etc/pacman.d/mirrorlist

# Installation
# ============

# install essential packages
# --------------------------
pacstrap /mnt base linux linux-firmware lvm2 neovim zsh git ansible

# = Configure the system

# == Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# == chroot
arch-chroot /mnt


# configure system with ansible from here?

# == Time zone
# === timedatectl does not work in chroot
ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
hwclock --systohc --utc

# == Localisation
echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

echo "LANG=en_GB.UTF-8" > /etc/locale.conf

printf \
"KEYMAP=sv-latin1
FONT=lat9w-16" \
> /etc/vconsole.conf

# == Network configuration
# === hostname
HOSTNAME="Thinx"
echo $HOSTNAME > /etc/hostname

# === hosts file
printf \
"127.0.0.1    localhost
 ::1          localhost
 127.0.1.1    ${HOSTNAME}.localdomain  ${HOSTNAME}" \
> /etc/hosts

# == initramfs

# ---- add encrypt for syslinux and bootctl
printf \
"MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block filesystems keyboard encrypt lvm2 fsck)" \
> /etc/mkinitcpio.conf

# Set root password
passwd


# Install systemd-boot
CRYPTROOT_UUID=`blkid -s UUID -o value ${CRYPTROOT_PARTITION}`

printf \
"title          Arch Linux
linux          /vmlinuz-linux
initrd         /intel-ucode.img
initrd         /initramfs-linux.img
options        cryptdevice=UUID=${CRYPTROOT_UUID}:cryptlvm root=/dev/vg.main/root resume=/dev/vg.main/swap rw" \
> /boot/loader/entries/arch.conf

printf \
"default       arch.conf
 timeout       1
 editor        no
 console-mode  max" \
> /boot/loader/loader.conf


# Microcode
pacman -S intel-ucode


# Network
pacman -S iwd
systemctl enable iwd.service

systemctl enable systemd-networkd.service

printf \
"[Match]
 Name=wlan0

 [Network]
 DHCP=yes

 [DHCP]
 RouteMetric=20"\
> /etc/systemd/network/25-wireless.network

systemctl enable systemd-resolved.service


# users
