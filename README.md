# maarch

My Automated ARCH linux Installation

## Usage

1. Create and start an [arch linux installation medium](https://wiki.archlinux.org/title/Installation_guide#Prepare_an_installation_medium)

2. Install ansible

   mount -o remount,size=1G /run/archiso/cowspace
   pacman -Sy ansible git

3. Download maarch repo

   git clone https://github.com/macGYves/maarch.git

4. Run ansible playbook "install-os.yml"

   cd maarch/ansible
   ansible-playbook install-os.yml

After the system restart, login as ordinary user and run

    cd /opt/maarch/ansible
    ansible-playbook configure.yml --ask-become-pass
