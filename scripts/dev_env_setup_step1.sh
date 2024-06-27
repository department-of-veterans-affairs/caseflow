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

echo "==> Installing the base dependencies"
brew install rbenv nodenv yarn jq shared-mime-info
brew tap ouchxp/nodenv
brew install nodenv-nvmrc
#brew install --cask chromedriver
#chromedriver --version

echo "==> Setting up rbenv and nodenv"
rbenv init
nodenv init

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

echo "2. To install the latest and enterprise Oracle Database version follow (https://seanstacey.org/deploying-an-oracle-database-19c-as-a-docker-container/2020/09/) guide.
    1. Go to http://container-registry.oracle.com/ (Here log in and opt for Database)
    2. On command line docker login container-registry.oracle.com
    3. On command line docker pull container-registry.oracle.com/database/enterprise:latest
   "

echo "==> Close this terminal, open a new terminal, and run ./dev_env_setup_step2.sh
	in the new terminal."
