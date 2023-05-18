# maarch

My Automated ARCH linux Installation

## Usage

1. Boot from [arch linux installation medium](https://wiki.archlinux.org/title/Installation_guide#Prepare_an_installation_medium)
2. Run the bootstrapping script:

   sh -c "$(curl -s https://raw.githubusercontent.com/macGYves/maarch/scripts/bootstrap.sh)"

3. Restart the system, login as root
4. Run the system setup script:

   sh -c "$(curl -s https://raw.githubusercontent.com/macGYves/maarch/scripts/setup-system.sh)"

5. Restart the system, login as user
6. Run the setup-user script:

   sh -c "$(curl -s https://raw.githubusercontent.com/macGYves/maarch/scripts/setup-user.sh)"
