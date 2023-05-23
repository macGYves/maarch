#!/usr/bin/sh
set -x
set -v



# = Variables
printf 'Installation device (e.g. /dev/sda):'
read -r INSTALL_DEV

TIMEZONE="Europe/Stockholm"

ESP_LABEL="ESP" # _E_FI _S_ystem _P_artition
EFI_PARTITION="/dev/disk/by-partlabel/${ESP_LABEL}"

LUKS_PARTITION_LABEL="CRYPTROOT"
LUKS_PARTITION="/dev/disk/by-partlabel/${LUKS_PARTITION_LABEL}"
LUKS_MAPPING_NAME=archroot


# = Set keyboard layout during live session
loadkeys uk

# Update the system clock
timedatectl set-timezone  ${TIMEZONE}
timedatectl set-ntp true


###################################################
# = Partition the disks
#
# +---------------------------------------------------+
# |  EFI System Partition (ESP)  |  LUKS Partition    |
# |                              |                    |
# |  /boot                       |  /                 |
# |______________________________|____________________|
# |  ${EFI_PARTITION}            |  ${LUKS_PARTITION} |
# +---------------------------------------------------+


# == Remove all partitions
echo "Removing all partitions on ${INSTALL_DEV}"
wipefs --all "${INSTALL_DEV}"
sgdisk --zap-all "${INSTALL_DEV}"

# == Create partitions
echo "Creating partitions..."
TYPECODE_ESP=ef00
TYPECODE_LUKS=8309
# change-name does not set a label for luks container, hence setting luks label in cryptsetup step below.
sgdisk --clear \
       --new=1:0:+550MiB --typecode=1:${TYPECODE_ESP} --change-name=1:${ESP_LABEL} \
       --new=2:0:0 --typecode=2:${TYPECODE_LUKS} --change-name=2:${LUKS_PARTITION_LABEL}\
       "${INSTALL_DEV}"



# = Setup disk encryption following LUKS_on_a_partition approach
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition
echo "Encrypting ${LUKS_PARTITION_LABEL}"
cryptsetup -y -v --label "${LUKS_PARTITION_LABEL}" luksFormat "${LUKS_PARTITION}"
echo "Opening encrypted disk..."
cryptsetup open "${LUKS_PARTITION}" "${LUKS_MAPPING_NAME}"


# = Create file systems
echo "Creating file systems..."
# == ESP
mkfs.fat -F 32 -n ESP ${EFI_PARTITION}

# == root partition
mkfs.btrfs "/dev/mapper/${LUKS_MAPPING_NAME}"

mount -o noatime,compress=zstd:1 "/dev/mapper/${LUKS_MAPPING_NAME}" /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log

umount /mnt


# = Mount file systems
echo "mounting file systems"
mount -o noatime,compress=zstd:1,subvol=@ "/dev/mapper/${LUKS_MAPPING_NAME}" /mnt
mount --mkdir "${EFI_PARTITION}" /mnt/boot
mount --mkdir -o compress=zstd:1,subvol=@home "/dev/mapper/${LUKS_MAPPING_NAME}" /mnt/home
mount --mkdir -o noatime,compress=zstd:1,subvol=@snapshots "/dev/mapper/${LUKS_MAPPING_NAME}" /mnt/.snapshots
mount --mkdir -o noatime,compress=zstd:1,subvol=@var_log "/dev/mapper/${LUKS_MAPPING_NAME}" /mnt/var/log


# = select mirrors
echo "Selecting mirrors..."
reflector --country Sweden --age 12 --protocol https --sort rate -n 5 --save /etc/pacman.d/mirrorlist

# Installation
# ============
pacstrap /mnt base linux linux-firmware neovim zsh git ansible btrfs-progs networkmanager man-db man-pages intel-ucode \
  python-passlib # required by ansible to hash variables

genfstab -U /mnt > /mnt/etc/fstab


CRYPTROOT_UUID=$(blkid -s UUID -o value "${LUKS_PARTITION}")
echo "cryptroot uuid: ${CRYPTROOT_UUID}"
HOSTNAME="archlinux"

install_script=bootstrap_os.sh
cat << EOF > "/mnt/${install_script}"
#!/bin/sh
# == Time zone
# === timedatectl does not work in chroot
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc --utc

# == Localisation
echo "de_DE.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

echo "LANG=de_DE.UTF-8" > /etc/locale.conf

printf "KEYMAP=uk" > /etc/vconsole.conf

# == Network configuration
# === hostname
echo "$HOSTNAME" > /etc/hostname

# === hosts file
printf \
"127.0.0.1   localhost
::1          localhost
127.0.1.1    ${HOSTNAME}.localdomain  ${HOSTNAME}" \
> /etc/hosts

# === Enable NetworkManager systemd service
systemctl enable NetworkManager.service

# == initramfs
# ---- add sd-encrypt bootctl
printf \
"MODULES=()
BINARIES=()
FILES=()
HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)" \
> /etc/mkinitcpio.conf

echo "Setting root password..."
passwd


# Install systemd-boot
bootctl install

echo \
"title          Arch Linux
linux          /vmlinuz-linux
initrd         /intel-ucode.img
initrd         /initramfs-linux.img
options        rd.luks.name=${CRYPTROOT_UUID}=${LUKS_MAPPING_NAME} root=/dev/mapper/${LUKS_MAPPING_NAME} rootflags=subvol=@ rw rootfstype=btrfs" \
> /boot/loader/entries/arch.conf

echo \
"default       arch.conf
 timeout       1
 editor        no
 console-mode  max" \
> /boot/loader/loader.conf

mkinitcpio -P
EOF
chmod +x "/mnt/${install_script}"

arch-chroot /mnt "./${install_script}"
