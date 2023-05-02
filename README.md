# maarch

My Automated ARCH linux Installation

## Usage

1. Create and start an [arch linux installation medium](https://wiki.archlinux.org/title/Installation_guide#Prepare_an_installation_medium)

2. Install archinstall

   pacman -S archinstall

3. archinstall --config https://github.com/macGYves/maarch/blob/main/archinstall/thinx.config.json

Restart the system, login as ordinary user and continue below.

4. Download maarch repo

   git clone https://github.com/macGYves/maarch.git

5. Install ansible roles and collections

   cd maarch/ansible
   ansible-galaxy install -r requirements.yml

6. Run "configure.yml" playbook

   ansible-playbook configure.yml --ask-become-pass
