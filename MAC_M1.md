# Mac M1 and M2 (Apple Silicon) Installation #######################################################

[<< Back](README.md)

How to verify that you have an Apple Silicon processor:
1. Click the Apple icon in the top-left of the screen
2. Click 'About This Mac'
3. Look for the 'Chip' section at the top of the list
    1. Apple Silicon processors will begin with 'Apple'; as of 7/2023, these a variant of 'Apple M1' or 'Apple M2'

Frequently Asked Question:

1. Why is this so complicated?

Apple Silicon processors use a different architecture (arm64/aarch64) than Intel processors (x86_64). Oracle, which is used for the VACOLS database, does not have binaries to run any of their database tools natively on arm64 for MacOS. Additionally, the Ruby gems `therubyracer` and `jshint` require the library v8@3.15, which can also only be compiled and installed on x86_64 processors. To work around this we use Rosetta to emulate x86_64 processors in the terminal, installing most of the Caseflow dependencies via the x86_64 version of Homebrew. It is important that while setting up your environment, you ensure you are *in the correct terminal type* and *in the correct directory* so that you do not install or compile a dependency with the wrong architecture.

***Ensure command line tools are installed via Self Service Portal prior to starting***

***Follow these instructions as closely as possible. If a folder is specified for running terminal commands, ensure you are in that directory prior to running the command(s). If you can't complete a step, ask for help in the #bid_appeals_mac_support channel of the Benefits Integrated Delivery (BID) Slack workspace.***

Clone these Repos
---
1. Create a `~/dev/appeals/` directory

2. Clone the following repo using `git clone` into this directory
    * <https://github.com/department-of-veterans-affairs/caseflow.git>

3. Optional for setting up a machine, though you may work with these in the future
    * <https://github.com/department-of-veterans-affairs/caseflow-commons.git>
    * <https://github.com/department-of-veterans-affairs/caseflow-frontend-toolkit.git>
    * <https://github.com/department-of-veterans-affairs/caseflow-efolder.git>
    * <https://github.com/department-of-veterans-affairs/caseflow-facols.git>
    * <https://github.com/department-of-veterans-affairs/appeals-notebook.git>

4. If you cannot clone the above, you might need to do [this setup](https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

Homebrew Installation
---
1. Install homebrew from self-service portal

Docker Installation
---
Note: We do not use Docker Desktop due to licensing. We recommend using Colima to run the docker service.

1. Open terminal and run:
    1. `brew install docker docker-compose colima`
    2. `mkdir -p ~/.docker/cli-plugins`
    3. `ln -sfn /opt/homebrew/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose`

Install UTM and VACOLS VM
---
1. Download UTM from this [link](https://github.com/utmapp/UTM/releases/latest/download/UTM.dmg)
2. Right click UTM.app and select “install with privilege management” then open the UTM.app
3. Download the Vacols VM from this [link](https://boozallen-my.sharepoint.com/:u:/r/personal/622659_bah_com/Documents/Appeals%20Vacols%20VM%20May%202023.utm.zip?csf=1&web=1&e=TnDe7c)
4. After the file downloads, right click on it in “Finder” and select “Show Package Contents” and delete the view.plist file if it exists
5. Right click on the application and select “Open With > UTM.app (default)”
6. Select the “Play” button when it pops up in UTM
7. Leave this running in the background. If you close the window, you can open it back up by repeating steps 5-7

Chromedriver Installation
---
1. Open terminal and run
    * `brew install --cask chromedriver`
2. Once it successfully installs, run command
    * `chromedriver –version`
3. There will be a pop up. Before clicking “OK,” navigate to System Settings > Privacy & Security
4. Scroll down to the security section and it will say “chromedriver was blocked from use because it is not from an identified
developer”
5. Select “Allow Anyway”
6. Select “Yes” from pop up
7. Reopen terminal and once again run `chromedriver –version`
8. Select “Open”

Note: you may need to run ```sudo spctl --global-disable``` in the terminal if you have issues with security

Install PDFtk Server and wkhtmltox
---
1. Download and install from this [link](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-2.02-mac_osx-10.11-setup.pkg)
2. Download this [file](https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-2/wkhtmltox-0.12.6-2.macos-cocoa.pkg) and move through the prompts

Note: you may need to run ```sudo spctl --global-disable``` in the terminal if you have issues with security

Configure x86_64 Homebrew
---
Run the below commands **from your home directory**

1. In a terminal, create a homebrew directory under your home directory
    * ```mkdir homebrew```
2. In a terminal, run
    * ```curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew```
3. If you get a chdir error, run
    * ``mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew``
4. Using sudo, move the homebrew directory to /usr/local/
    * ```sudo mv homebrew /usr/local/homebrew```

Rosetta
---
1. Open standard terminal and run:
    * ```softwareupdate -–install-rosetta –-agree-to-license```
2. Once Rosetta is installed, find the default terminal in “Finder” > Applications
3. Right click and select “Get Info”
4. Select “Open using Rosetta”
    * Note: you can copy the standard terminal executable to your desktop and enable Rosetta on that, so that you don’t need to disable rosetta on the default terminal once Caseflow setup is complete

Oracle “instantclient” Files
---
1. Download these DMG files
    * [instantclient-basic-macos.x64-19.8.0.0.0dbru.dmg](https://download.oracle.com/otn_software/mac/instantclient/198000/instantclient-basic-macos.x64-19.8.0.0.0dbru.dmg)
    * [instantclient-sqlplus-macos.x64-19.8.0.0.0dbru.dmg](https://download.oracle.com/otn_software/mac/instantclient/198000/instantclient-sqlplus-macos.x64-19.8.0.0.0dbru.dmg)
    * [Instantclient-sdk-macos.x64-19.8.0.0.0dbru.dmg](https://download.oracle.com/otn_software/mac/instantclient/198000/instantclient-sdk-macos.x64-19.8.0.0.0dbru.dmg)
2. After downloading, double click on one of the folders and follow the instructions in INSTALL_IC_README.txt to copy the libraries

Postgres Download
---
1. Download and install from this [link](https://github.com/PostgresApp/PostgresApp/releases/download/v2.5.8/Postgres-2.5.8-14.dmg)

OpenSSL
---
1. Download openssl@1.1 and openssl@3 from this [link](https://boozallen.sharepoint.com/teams/VABID/appeals/Documents/Forms/AllItems.aspx?id=%2Fteams%2FVABID%2Fappeals%2FDocuments%2FDevelopment%2FDeveloper%20Setup%20Resources%2FM1%20Mac%20Developer%20Setup&viewid=8a8eaf3e%2D2c12%2D4c87%2Db95f%2D4eab3428febd)
2. Open “Finder” and find the two folders under “Downloads”
3. Extract the `.tar.gz` or `.zip` archives
4. In each of the extracted folders:
    1. Navigate to the `/usr/local/homebrew/Cellar` subfolder
    2. Copy the openssl folder to your local machine's `/usr/local/homebrew/Cellar` folder
    3. If the folder `Cellar` in `/usr/local/homebrew` does not exist, create it with `mkdir /usr/local/homebrew/Cellar`
    * Note: moving these folders can be done using finder or a terminal
5. Run command (from a rosetta terminal)
    1. `brew link --force openssl@1.1`
    2. If the one above doesn’t work run: `brew link openssl@1.1 --force`
    * Note: don't link openssl@3 unless you run into issues farther in the setup

Modify your .zshrc File
---
1. Run command `open ~/.zshrc`
2. Add the following lines, if any of these are already set make sure to comment previous settings:

```
export PATH=/usr/local/homebrew/bin:${PATH}
eval "$(/usr/local/homebrew/bin/rbenv init -)"
eval "$(/usr/local/homebrew/bin/nodenv init -)"
eval "$(/usr/local/homebrew/bin/pyenv init --path)"

# Add Postgres environment variables for CaseFlow
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export NLS_LANG=AMERICAN_AMERICA.UTF8
export FREEDESKTOP_MIME_TYPES_PATH=/usr/local/homebrew/share/mime/packages/freedesktop.org.xml export OCI_DIR=~/Downloads/instantclient_19_8
```

3. Save file
4. Go to your active terminal and enter source ~/.zshrc or create a new terminal
Note: until rbenv, nodenv, and pyenv are installed, the `eval` commands will display a 'command not found' error when launching a terminal

Run dev setup scripts in Caseflow repo
---
**VERY IMPORTANT NOTE: The below commands must be run *in a Rosetta terminal* until you reach the 'Running Caseflow' section**

*Script 1*

1. Enter a **Rosetta** terminal and ensure you are in the directory you cloned Caseflow repo into (~/dev/appeals/caseflow) and run commands:
    1. ```git checkout grant/setup-m1```
    2. ```./scripts/dev_env_setup_step1.sh```
    * If this fails, double check your .zshrc file to ensure your PATH has only the x86_64 brew

*Script 2*

1. Open a **Rosetta** terminal and navigate to /usr/local, run the command ```sudo spctl --global-disable```
2. In the **Rosetta** terminal, install pyenv and the required python2 version:
    1. `brew install pyenv`
    2. `pyenv rehash`
    3. `pyenv install 2.7.18`
    4. In the caseflow directory, run `pyenv local 2.7.18` to set the version
3. In the **Rosetta** terminal navigate to caseflow folder:
    1. set ```export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr/local/homebrew/Cellar/openssl@1.1"```
    2. run `rbenv install $(cat .ruby-version)`
    3. run `rbenv rehash`
    4. run `gem install bundler -v $(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)`
    5. run `gem install pg:1.1.4 -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config`
    6. Install v8@3.15 by doing the following (these steps assume that vi/vim is the default editor):
        1. run `brew edit v8@3.15`
        2. go to line 21 in the editor by typing `:21`
      Note: the line being removed is `disable! date: "2023-06-19", because: "depends on Python 2 to build"`
        3. delete the line by pressing `d` twice
        4. save and quit by typing `:x`
        5. run `HOMEBREW_NO_INSTALL_FROM_API=1 brew install v8@3.15`
    7. Configure build opts for gem `therubyracer`:
        1. `bundle config build.libv8 --with-system-v8`
        2. `bundle config build.therubyracer --with-v8-dir=$(brew --prefix v8@3.15)`
    8. run ```./scripts/dev_env_setup_step2.sh```
  If you get a permission error while running gem install or bundle install, **do not run using sudo.**
  Set the permissions back to you for every directory under /.rbenv
      * Enter command: `sudo chown -R <your name under /Users> /Users/<your name>/.rbenv`
          * For example, if my name is Eli Brown, the command will be:
          `sudo chown –R elibrown /Users/elibrown/.rbenv`
4. Optional: If there are no errors messages, run `bundle install` to ensure all gems are installed

Running Caseflow
---
**VERY IMPORTANT NOTE TWO: This is where you switch back to a *standard* (non-Rosetta) terminal**

1. Once your installation of all gems is complete, switch back to a standard MacOS terminal:
    1. open your ~/.zshrc file
    2. comment the line `export PATH=/usr/local/homebrew/bin:$PATH`
    3. uncomment the line `export PATH=/opt/homebrew/bin:$PATH`
    4. add the line `export PATH=$HOME/.nodenv/shims:$HOME/.rbenv/shims:$HOME/.pyenv/shims:$PATH`
    5. comment the lines `eval "$({binary} init -)"` for rbenv, pyenv, and nodenv if applicable
    6. if you added the line `eval $(/usr/local/homebrew/bin/brew shellenv)` after installing x86_64 homebrew, comment it out
2. Open a terminal verify:
	  1. that you are on arm64 by doing `arch` and checking the output
	  2. that you are using arm64 brew by doing `which brew` and ensuring the output is `/opt/homebrew/bin/brew`
3. Open caseflow in VSCode (optional), or navigate to the caseflow directory in your terminal and:
	  1. `brew install yarn`
4. Ensure you are on master branch and up to date by running
    1. ```git checkout master```
    2. ```git fetch```
    3. ```git pull origin master```
5. Start Vacols UTM VM (if not already running)
6. run `make up-m1` to create the docker containers and volumes
7. run `make reset` to (re)create and seed the database; this takes a while (~45 minutes)
	  1. if you get a database not found error, run `bundle exec rake db:drop db:create db:schema:load`, and then run `make reset` again
8. open a second terminal tab/window
9. run `make run-backend-m1` in one tab, and `make run-frontend` in the other
	  1. the backend should launch on `localhost:3000`. go there in your browser to access Caseflow
	  2. the frontend launches on `localhost:3500`; this is a server that enables hot-reloading of modules during development. going to this address in a browser will not work
	  3. optionally, you can do `make run-m1` to launch both at the same time with Foreman, but if one server errors the other can remain running and lead to headache trying to get them back up

To launch caseflow after a machine restart:
---
1. Start the VACOLS VM via UTM; login is not required
2. In terminal, run `colima start` to start the docker daemon
3. In terminal, go to the caseflow directory and run:
	  * `make up-m1` to start the docker containers
4. Open a second terminal window/tab, and from the caseflow directory run:
	  * `make run-backend-m1` in one tab
	  * `make run-frontend` in the other tab

Note: It takes several minutes for the VACOLS VM to go through its startup and launch the Oracle DB service, and about a minute for the Postgres DB to initialize after running `make up-m1`.

---

The following steps are an alternative to step 7 of the Running Caseflow section in the event that you absolutely cannot get those commands to work:
1. In caseflow, run
    * a. `make down`
        * i.  Removes appeals-db, appeals-redis, and localstack docker containers
    * b. `docker-compose down –v`
        * i. Removes caseflow_postgresdata docker volume
    * c. `make up-m1`
        * i. Starts docker containers, volume, and network
    * d. `make reset`
        * i. Resets caseflow and ETL database schemas, seeds databases, and enables feature flags
        * **If `make reset` returns database not found error:
            * a. Run command `bundle exec rake db:drop`
            * b. Download caseflow-db-backup.gz (not able to share this download via policy, ask in the slack channel)
            * c. Enter terminal, navigate to ~/Downloads
            * e. Run command
                * i. `gzip -dck caseflow-db-backup.gz | docker exec -i appeals-db psql -U postgres`
                * ii. (this command will link the caseflow_certification_database to docker)
            * f. Enter terminal, navigate to caseflow, and run
                * i. `make up-m1`
                * ii. `make reset` (this will take a while)

[<< Back](README.md)
