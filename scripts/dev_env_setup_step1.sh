#!/bin/bash

# This script automates the Developer Setup described here:
# https://github.com/department-of-veterans-affairs/caseflow/blob/master/README.md#developer-setup

# It is okay to run this script multiple times.
# Only Mac has been tested.

function detectOs(){
	# https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux
	unameOut="$(uname -s)"
	case "${unameOut}" in
	    Linux*)     machine=Linux;;
	    Darwin*)    machine=Mac;;
	    CYGWIN*)    machine=Cygwin;;
	    MINGW*)     machine=MinGw;;
	    *)          machine="UNKNOWN:${unameOut}"
	esac
	echo ${machine}
}

OS=$(detectOs)
echo "==> Detected $OS operating system"

case "$OS" in
	"Mac")
		# Install the Xcode commandline tools
		xcode-select --install
		;;
	*)
		echo "!!! Unsupported OS"
		exit 10
		;;
esac


# === The rest assumes Mac OS, so there are no case statements.

echo "==> Installing Homebrew"
if which brew > /dev/null; then
  echo "Homebrew is already installed. Skipping installation."
else
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "==> Installing the base dependencies"
brew install rbenv nodenv yarn jq
brew tap ouchxp/nodenv
brew install nodenv-nvmrc
brew install postgres
brew install --cask chromedriver
chromedriver --version

echo "==> Setting up rbenv and nodenv"
rbenv init
nodenv init

if ! grep -q rbenv ~/.bash_profile; then
	echo "==> Updating ~/.bash_profile"
	echo '
	eval "$(rbenv init -)"
	eval "$(nodenv init -)"

	export POSTGRES_HOST=localhost
	export POSTGRES_USER=postgres
	export POSTGRES_PASSWORD=postgres
	export NLS_LANG=AMERICAN_AMERICA.UTF8
	' >> ~/.bash_profile
fi

echo "==> Installing PDFtk Server"
if ! [ -f pdftk_server-2.02-mac_osx-10.11-setup.pkg ]; then
	brew install wget
	wget "https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-2.02-mac_osx-10.11-setup.pkg"
fi
echo "==> To install PDFtk, enter your password (i.e., the password to unlock your computer)"
sudo installer -pkg pdftk_server-2.02-mac_osx-10.11-setup.pkg -target /

echo "==> Installing Docker"
if which docker > /dev/null; then
  echo "Docker is already installed. Skipping installation."
else
  brew install --cask docker
fi

echo "==> Installing InstantClient"
brew tap InstantClientTap/instantclient
brew install instantclient-basic
brew install instantclient-sdk

echo "
===================================
You must do the following manually:
"

echo "1. Run Docker and go into advanced preferences to limit Docker's resources
   in order to keep FACOLS from consuming your Macbook.
   Recommended settings are 4 CPUs, 8 GiB of internal memory, and 512 MiB of swap.
   "

echo "2. In a new terminal, run:
      docker login -u dsvaappeals
   The password is in the DSVA 1Password account.
   Note you can use your personal account as well, you'll just have to accept
   the license agreement for the Oracle Database docker image.
   https://store.docker.com/images/oracle-database-enterprise-edition
   To accept the agreement, checkout with the Oracle image on the docker store.
   "

echo "==> Close this terminal, open a new terminal, and run ./dev_env_setup_step2.sh
	in the new terminal."
