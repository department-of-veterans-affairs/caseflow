#!/bin/bash

# This script automates the Caseflow Developer Setup for Ubuntu (can run in WSL for Windows)

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
C="\033[0;35m"
NC="\033[0m"

cd "${SCRIPT_DIR}/.."
echo -e "\n\n${C}==> Ubuntu setup${NC}\n\n"
sudo apt-get update
sudo apt-get install -y curl unzip wget ca-certificates gnupg lsb-release libv8-dev libaio1

# install nodejs
echo -e "\n\n${C}==> Installing nodejs${NC}\n\n"
if which nvm > /dev/null; then
  echo "nvm is already installed. Skipping installation."
else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ~/.bashrc
    source ~/.bashrc
fi
nvm install $(cat .nvmrc)
# nvm install --lts

# Install rbenv
echo -e "\n\n${C}==> Installing rbenv${NC}\n\n"
if which rbenv > /dev/null; then
    echo "rbenv is already installed. Skipping installation."
else
    sudo apt update
    sudo apt install -y libssl-dev libreadline-dev zlib1g-dev autoconf bison build-essential libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"' >> ~/.bashrc
    source ~/.bashrc
fi

# Install yarn
echo -e "\n\n${C}==> Installing yarn${NC}\n\n"
if which yarn > /dev/null; then
  echo "yarn is already installed. Skipping installation."
else
    source ~/.bashrc
    npm install --global yarn
fi

# Install PDFtk
echo -e "\n\n${C}==> Installing PDFtk${NC}\n\n"
if which pdftk > /dev/null; then
  echo "PDFtk is already installed. Skipping installation."
else
    sudo add-apt-repository -y ppa:malteworld/ppa
    sudo apt update
    sudo apt install -y pdftk
fi

# Install PostgreSQL
echo -e "\n\n${C}==> Installing PostgreSQL${NC}\n\n"
sudo apt install -y postgresql-client-12 postgresql-contrib libpq-dev
if ! grep -q POSTGRES ~/.bashrc; then
	echo 'export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export NLS_LANG=AMERICAN_AMERICA.UTF8' >> ~/.bashrc
    source ~/.bashrc
fi

# Install Docker
echo -e "\n\n${C}==> Installing Docker${NC}\n\n"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
sudo usermod -aG docker $USER
if ! grep -q HOME/.local/bin ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
fi 
if ! grep -q "Start Docker daemon automatically" ~/.bashrc; then
    echo '# Start Docker daemon automatically when logging in if not running.' >> ~/.bashrc
    echo 'RUNNING=`ps aux | grep dockerd | grep -v grep`' >> ~/.bashrc
    echo 'if [ -z "$RUNNING" ]; then' >> ~/.bashrc
    echo '    sudo dockerd > /dev/null 2>&1 &' >> ~/.bashrc
    echo '    disown' >> ~/.bashrc
    echo 'fi' >> ~/.bashrc
    source ~/.bashrc
fi

# Install chromedriver
echo -e "\n\n${C}==> Installing chromedriver${NC}\n\n"
if which chromedriver > /dev/null; then
    echo "chromedriver is already installed. Skipping installation."
else
    sudo apt-get update
    sudo apt-get install -y xvfb libxi6 libgconf-2-4
    sudo curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add
    sudo su -c "echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list.d/google-chrome.list"
    sudo apt-get -y update
    sudo apt-get -y install google-chrome-stable
    wget https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip
    unzip chromedriver_linux64.zip
    sudo mv chromedriver /usr/bin/chromedriver
    sudo chown root:root /usr/bin/chromedriver
    sudo chmod +x /usr/bin/chromedriver
    rm chromedriver_linux64.zip
    chromedriver --version
fi

# Install Ruby dependencies
echo -e "\n\n${C}==> Installing Ruby dependencies${NC}\n\n"
RUBY_VERSION=$(cat .ruby-version)
if [[ ! `rbenv version | grep $RUBY_VERSION` ]]; then
    rbenv install $RUBY_VERSION
fi
rbenv rehash
gem install bundler -v 2.2.25
bundle install

# Install javascript dependencies
echo -e "\n\n${C}==> Installing javascript dependencies${NC}\n\n"
sudo apt install -y python2
yarn --cwd ./client/ install

# Check for build_facols files (oracle files that aren't in git)
if [ ! -d "local/vacols/build_facols/" ]; then
    echo -e "
\033[0;31m====================================================
This setup script assumes you have the 
appropriate oracle files downloaded and copied to
caseflow/local/vacols/build_facols/

Either ./build_push.sh has already run or Oracle has 
not been installed and FACOLS has not been set up, 
those will need to be done before running the app. 
====================================================${NC}
"
else 
    # Install oracle instantclient
    if ! grep -q instantclient ~/.bashrc; then
        echo -e "\n\n${C}==> Installing oracle instantclient${NC}\n\n"
        sudo mkdir /opt/oracle
        sudo chown $USER /opt/oracle
        unzip local/vacols/build_facols/instantclient-basic-linux.x64-12.2.0.1.0.zip -d /opt/oracle
        unzip local/vacols/build_facols/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /opt/oracle
        unzip local/vacols/build_facols/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip -d /opt/oracle
        ln -s /opt/oracle/instantclient_12_2/libclntsh.so.12.1 /opt/oracle/instantclient_12_2/libclntsh.so
        echo 'export PATH="/opt/oracle/instantclient_12_2:$PATH"
export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_2' >> ~/.bashrc
        source ~/.bashrc
    fi

    # Setup FACOLS
    echo -e "\n\n${C}==> Setting up FACOLS${NC}\n\n"
    ln -s Makefile.example Makefile
    cd local/vacols
    ./build_push.sh local
    cd ../..

    #Seed DBs
    docker-compose up -d
    h=`docker-compose ps | grep -i starting`; while [ "$h" != "" ]; do h=`docker-compose ps | grep -i starting`; echo $h; sleep 1; done
    bundle install
    bundle exec rake db:create
    bundle exec rake local:vacols:seed
    bundle exec rake db:schema:load db:seed

    echo -e "
${C}==============================================
If everything ran successfully, you're ready
to go to the caseflow directory and run:

$ make run

==============================================${NC}"
fi
