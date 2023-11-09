## Setup WSL for Windows

1. Open PowerShell as Administrator (Start menu > PowerShell > right-click > Run as Administrator) and enter these commands:
    * dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    * dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

2. Download and install: https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi

3. After installing VS Code, install the Remote - [WSL extension:](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)

4. Download Ubuntu 20.04.5 LTS from [Windows Store](https://apps.microsoft.com/store/search/Ubuntu)

5. A. Launch Ubuntu 20.04.5 LTS (hit WinKey, type Ubuntu, hit enter) Set a username and password for yourself.

## Install rbenv

Within your WSL Ubuntu terminal:

```bash
	sudo apt update
    sudo apt install -y libssl-dev libreadline-dev zlib1g-dev autoconf bison build-essential libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"' >> ~/.bashrc
    source ~/.bashrc
```

## Use rbenv to install Ruby 3.2.2

Within your WSL Ubuntu terminal:

```bash
rbenv install 3.2.2
rbenv rehash
rbenv global 3.2.2
```

## Install Postgresql

Within your WSL Ubuntu terminal:

```bash
	sudo apt install -y postgresql-client-12 postgresql-contrib libpq-dev
	echo 'export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export NLS_LANG=AMERICAN_AMERICA.UTF8' >> ~/.bashrc
    source ~/.bashrc
```

## Clone down the project repo

Within your WSL Ubuntu terminal, make a `appeals/` directory. Clone the project into this directory.

 - `< REPLACE WITH LINK TO REPO >`

> If you cannot clone the above, you might need to do [this setup](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)

##  Project dependencies and setup DB

Within your WSL Ubuntu terminal from the project directory, run:

```bash
bundle
rails db:setup
```
