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

if ! grep -q rbenv ~/.zshrc; then
	echo "==> Updating ~/.zshrc"
	cat <<-EOF >> ~/.zshrc

		# Caseflow Environment Setup
		eval "$(rbenv init -)"
		eval "$(nodenv init -)"
		export POSTGRES_HOST=localhost
		export POSTGRES_USER=postgres
		export POSTGRES_PASSWORD=postgres
		export NLS_LANG=AMERICAN_AMERICA.UTF8
	EOF
fi

echo "==> Installing InstantClient"
brew tap InstantClientTap/instantclient
brew install instantclient-basic
brew install instantclient-sdk
