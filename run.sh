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
# | /dev/tank/swap        | /dev/tank/root        |
# |_ _ _ _ _ _ _ _ _ _ _ _|_ _ _ _ _ _ _ _ _ _ _ _|
# |                                               |
# |           LUKS2 encrypted partition           |
# |           $CRYPTROOT_PARTITION                |
# +-----------------------------------------------+

DISK=/dev/sda
BOOT_PARTITION="${DISK}1"
CRYPTROOT_PARTITION="${DISK}2"

SWAP_PARTITION=/dev/tank/swap

# == Remove all partitions
sgdisk --zap-all ${DISK}

# == Create partitions
sgdisk --clear \
       --new=1:0:+550MiB --typecode=1:ef00 --change-name:1:EFI \
       --new=2:0:0 --typecode:2:8309 --change-name=2:cryptroot \
       ${DISK}

# == Setup disk encryption following LVM-on-LUKS approach
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
cryptsetup -y -v luksFormat ${CRYPTROOT_PARTITION}
cryptsetup open ${CRYPTROOT_PARTITION} cryptlvm

## == Initialise physical volume for use with LVM
pvcreate /dev/mapper/cryptlvm
## == create volume group called "tank"
vgcreate tank /dev/mapper/cryptlvm
## == create logical volume for [swap]
lvcreate -L 32G tank -n swap
## == create logical volume for /
lvcreate -l 100%FREE tank -n root

# == Format partitions
# == root partition
mkfs.ext4 /dev/tank/root

# == swap partition

mkswap ${SWAP_PARTITION}
swapon ${SWAP_PARTITION}

# == boot partition
mkfs.fat -F32 -n EFI ${BOOT_PARTITION}

# Mount the file systems
mount /dev/tank/root /mnt
mkdir /mnt/boot
mount ${BOOT_PARTITION} /mnt/boot



# Installation
# ============

# install essential packages
# --------------------------
pacstrap /mnt base linux linux-firmware \
          git ansible

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
printf \
"en_GB.UTF-8 UTF-8
de_DE.UTF-8 UTF-8
sv_SE.UTF-8 UTF-8"\
> /etc/locale.gen
locale-gen

echo LANG=en_UK.UTF-8 > /etc/locale.conf
locale-gen

printf \
"echo KEYMAP=sv-latin1
echo FONT=lat9w-16" \
> /etc/vconsole.conf

# == Network configuration
# === hostname
HOSTNAME="Thinkr"
echo $HOSTNAME > /etc/hostname

# === hosts file
echo "127.0.0.1	$HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# == initramfs

# ---- add encrypt for syslinux and bootctl
printf \
"MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block filesystems keyboard encrypt lvm2 fsck)" \
> /etc/mkinitcpio.conf


# == select mirrors
pacman -Sy --noconfirm pacman-contrib
curl -s "https://www.archlinux.org/mirrorlist/?country=DK&country=FI&country=DE&country=IS&country=NO&country=SE&country=GB&protocol=https&ip_version=4&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 10 - > /etc/pacman.d/mirrorlist

