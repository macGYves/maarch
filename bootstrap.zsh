#!/usr/bin/zsh

printf 'Installation device (e.g. /dev/sda):'
read -r INSTALL_DEV

# = Variables
export TIMEZONE="Europe/Stockholm"

ESP_LABEL="ESP" # _E_FI _S_ystem _P_artition
EFI_PARTITION="/dev/disk/by-partlabel/${ESP_LABEL}"

LUKS_PARTITION_LABEL="CRYPTROOT"
export LUKS_PARTITION="/dev/disk/by-partlabel/${LUKS_PARTITION_LABEL}"
export LUKS_MAPPING_NAME=archroot


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

script_dir=$(dirname "$0")
cp "${script_dir}/bootstrap_os.sh" /mnt/bootstrap_os.sh
arch-chroot /mnt ./bootstrap_os.sh
