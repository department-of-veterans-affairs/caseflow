#!/bin/bash
# 
# This script installs all necessary dependencies required to run the test suite.
# 

function install {
    color_echo "Installing $1..."
    shift
    apt-get -y install "$@"
}

function color_echo {
  echo -e '\E[37;44m'"\033[1m ==> $1 \033[0m"
}

app_path="/vagrant/connect_vbms"

color_echo 'Updating package information...'
apt-get -y update
color_echo 'Upgrading packages...'
apt-get -y full-upgrade
color_echo 'Removing packages that are no longer needed...'
apt-get -y autoremove
color_echo 'Cleaning package information cache...'
apt-get -y autoclean

color_echo 'Installing Java7...'
wget --no-check-certificate https://github.com/aglover/ubuntu-equip/raw/master/equip_java7_64.sh
bash equip_java7_64.sh

# => Uncomment to install Java8 instead
# color_echo 'Installing Java8...'
# wget --no-check-certificate https://github.com/aglover/ubuntu-equip/raw/master/equip_java8.sh
# bash equip_java8.sh

install 'Python and dependencies' python python-dev libjs-jquery libjs-jquery-ui iso-codes gettext python-pip bzr

color_echo 'Installing Sphinx'
pip install sphinx

install 'development tools' build-essential curl

install 'Git' git

# store fingerprint of hosts for github.com (avoids the interactive prompt
# when first connecting to github)
sudo ssh-keyscan -H github.com > /etc/ssh/ssh_known_hosts

color_echo 'Installing RVM...'
sudo -u vagrant -H bash -l -c 'gpg --keyserver hkp://keys.gnupg.net \
  --recv-keys D39DC0E3 && curl --silent -L https://get.rvm.io | bash -s stable --autolibs=enabled'

source /home/vagrant/.rvm/scripts/rvm

color_echo 'Installing Ruby 2.2.2...'
sudo -u vagrant -H bash -l -c '/home/vagrant/.rvm/bin/rvm install ruby-2.2.2 \
  --quiet-curl --autolibs=enabled --auto-dotfiles --binary --max-time 30 \
  && rvm alias create default 2.2.2'

cd $app_path && rvm use 2.2.2@default
color_echo 'Upgrading Rubygems...'
sudo -u vagrant -H bash -l -c 'rvm rubygems latest'

color_echo 'Installing Bundler...'
cd $app_path && gem install bundler --no-ri --no-rdoc

color_echo 'Bundling...'
cd $app_path && bundle

color_echo 'Building...'
cd $app_path && bundle exec rake build

color_echo 'Running specs...'
cd $app_path && bundle exec rspec

color_echo 'All done, carry on!'
