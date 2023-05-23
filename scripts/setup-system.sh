#!/usr/bin/sh

tmpdir=$(mktemp -d)
git clone https://github.com/macGYves/maarch.git "${tmpdir}/maarch"
cd "${tmpdir}/maarch/ansible" || exit
ansible-galaxy install -r requirements.yml
ansible-playbook configure_system.yml

