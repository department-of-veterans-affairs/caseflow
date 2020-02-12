#!/bin/bash

# Continuation of Developer Setup at
# https://github.com/department-of-veterans-affairs/caseflow/blob/master/README.md#clone-this-repo

echo "==> Cloning Caseflow from GitHub"
git clone https://github.com/department-of-veterans-affairs/caseflow.git
cd caseflow

echo "==> Installing Ruby dependencies"
rbenv install $(cat .ruby-version)
rbenv rehash
# BUNDLED_WITH<VERSION> is at the bottom Gemfile.lock
BUNDLED_WITH=$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)

echo "===> Installing bundler version ${BUNDLED_WITH}"
gem install bundler -v ${BUNDLED_WITH}
if [ $? == 0 ]; then
	# If when running gem install bundler above you get a permissions error,
	# this means you have not propertly configured your rbenv.
	# Debug.
	# !! Do *not* proceed by running sudo gem install bundler. !!

	bundle install
fi

echo "==> Installing JavaScript dependencies"
nodenv install $(cat .nvmrc)
nodenv rehash
cd client
yarn install
cd ..

echo "==> Setting up Makefile"
ln -s Makefile.example Makefile

echo "
===================================
You must do the following manually:

AWS access is needed starting at this point.
If you need to get AWS access, follow these instructions:
   https://github.com/department-of-veterans-affairs/appeals-deployment/wiki/Engineers-New-Hire-and-On-boarding#first-days
"

echo '1. Configure issue_mfa.sh by following instructions at:
   https://github.com/department-of-veterans-affairs/appeals-deployment/wiki/Utility-Applications
'

echo '2. Continue the set up manually from "Database environment setup":
   https://github.com/department-of-veterans-affairs/caseflow/blob/master/README.md#database-environment-setup
'