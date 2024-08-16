# maarch

My Automated ARCH linux Installation

## Usage

1. Boot from [arch linux installation medium](https://wiki.archlinux.org/title/Installation_guide#Prepare_an_installation_medium)
2. Run the bootstrapping script:

   sh -c "$(curl -sL https://bit.ly/maarch-bootstrap)"

3. Restart the system, login as root
4. Run the system setup script:

   sh -c "$(curl -sL https://bit.ly/maarch-system)"

5. Restart the system, login as user
6. Run the setup-user script:

   sh -c "$(curl -sL https://bit.ly/maarch-user)"
