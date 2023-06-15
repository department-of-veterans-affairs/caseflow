## Mac M1 and M2 #######################################################

[<< Back](README.md)

***Ensure command line tools are installed via Self Service Portal prior to starting***

**Clone these Repos**

1. Create a `~/dev/appeals/` directory

2. Clone the following repos using git clone into this directory \
    a. <https://github.com/department-of-veterans-affairs/caseflow.git> \
    b. <https://github.com/department-of-veterans-affairs/caseflow-commons.git> \
    c. <https://github.com/department-of-veterans-affairs/caseflow-frontend-toolkit.git>

3. Optional for setting up a machine, clone if can \
    a. <https://github.com/department-of-veterans-affairs/caseflow-efolder.git> \
    b. <https://github.com/department-of-veterans-affairs/caseflow-facols.git> \
    c. <https://github.com/department-of-veterans-affairs/appeals-notebook.git>

4. If cannot clone the above might need to do <https://docs.github.com/en/enterprise-server@3.4/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token>

**Homebrew Installation**

1. Install homebrew from self-service portal

**Docker Installation**

1. Navigate to [docker website](https://docs.docker.com/desktop/install/mac-install/)

2. Install “Docker Desktop for Mac Apple silicon”

3. Pop up of app will come up to transfer to application folder

4. Right click on the Docker app and select “install with privilege management”

5. Open terminal and run
    * a. `arch –arm64 brew install docker docker-compose colima`
    * b. `mkdir -p ~/.docker/cli-plugins`
    * c. `ln -sfn /opt/homebrew/opt/docker-compose/bin/docker-compose~/.docker/cli-plugins/docker-compose`
    * d. `sudo mv homebrew /usr/local/homebrew`
        * i. (moves homebrew from /opt to /usr/local)
    * e. `eval $(/usr/local/homebrew/bin/brew shellenv)`

**UTM and Vacols VM**

1. Download UTM from this [link](https://github.com/utmapp/UTM/releases/latest/download/UTM.dmg)

2. Right click UTM.app and select “install with privilege management” then open the UTM.app

3. Download the Vacols VM from this [link](https://boozallen-my.sharepoint.com/:u:/r/personal/622659_bah_com/Documents/Appeals%20Vacols%20VM%20May%202023.utm.zip?csf=1&web=1&e=TnDe7c)

4. After the file downloads, right click on it in “Finder” and select “Show Package Contents” and delete the view.plist file if it exists

5. Right click on the application and select “Open With > UTM.app (default)”

6. Select the “Play” button when it pops up in UTM

7. The virtual machine will open. To login, the password is “password” \
**Booz Allen Hamilton Internal**

8. Leave this running in the background. If you close the window, you can open it back up by repeating steps 5-7

**Chromedriver Installation**

1. Open terminal and run \
    a. `brew install --cask chromedriver`

2. Once it successfully installs, run command \
    a. `chromedriver –version`

3. There will be a pop up. Before clicking “OK,” navigate to System Settings > Privacy & Security

4. Scroll down and it will say “chromedriver was blocked form use because it is not from an identified
developer”

5. Select “Allow Anyway”

6. Select “Yes” from pop up

7. Open terminal and once again run `chromedriver –version`

8. Select “Open”

**PDFtk Server**

1. Download from this [link](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-2.02-mac_osx-10.11-setup.pkg)

**Configure x86_64 Homebrew**

1. Create a homebrew directory under your home directory \
    a. ```mkdir homebrew```

2. Open terminal and run \
    a. ```curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew```

3. If chdir error run \
    a. ``mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew``

4. Using sudo, move the homebrew directory to /usr/local/ \
    a. ```sudo mv homebrew /usr/local/homebrew```

**Rosetta**

1. Open standard terminal and run: \
    a. ```softwareupdate –install-rosetta –agree-to-license```
2. Once Rosetta is installed, find the default terminal in “Finder” > Applications

3. Right click and select “Get Info”

4. Select “Open using Rosetta”
    * Note: you can copy the standard terminal executable to your desktop and enable Rosetta on that, so that you don’t need to disable rosetta on the default terminal once Caseflow setup is complete

**Booz Allen Hamilton Internal**

**Oracle “instantclient” Files**

1. Download these DMG files \
    a. [instantclient-basic-macos.x64-19.8.0.0.0dbru.dmg](https://download.oracle.com/otn_software/mac/instantclient/198000/instantclient-basic-macos.x64-19.8.0.0.0dbru.dmg) \
    b. [instantclient-sqlplus-macos.x64-19.8.0.0.0dbru.dmg](https://download.oracle.com/otn_software/mac/instantclient/198000/instantclient-sqlplus-macos.x64-19.8.0.0.0dbru.dmg) \
    c. [Instantclient-sdk-macos.x64-19.8.0.0.0dbru.dmg](https://download.oracle.com/otn_software/mac/instantclient/198000/instantclient-sdk-macos.x64-19.8.0.0.0dbru.dmg)

2. After downloading, click on one of the folders and follow the instructions in INSTALL_IC_README.txt

**Postgres Download**

1. Download from this [link](https://github.com/PostgresApp/PostgresApp/releases/download/v2.5.8/Postgres-2.5.8-14.dmg)

**OpenSSL**

1. Download openssl@1.1 and openssl@3 from this [link](https://boozallen.sharepoint.com/teams/VABID/appeals/Documents/Forms/AllItems.aspx?viewid=8a8eaf3e%2D2c12%2D4c87%2Db95f%2D4eab3428febd&view=7&q=openssl)

2. Open “Finder” and find the two folders under “Downloads”

3. Open openssl@1.1 and find the child folder 1.1.1s

4. Click 1.1.1s, duplicate it, and rename the duplicate folder 1.1.1t

5. Open openssl@3 and find the child folder 3.0.7

6. Click 3.0.7, duplicate it, and rename the duplicate folder 3.1.0

7. Open a second “Finder” window and navigate to /usr/local/homebrew/Cellar

8. Move openssl@1.1 and openssl@3 to the Cellar folder

9. Run command (from a rosetta terminal) \
    a. brew link --force openssl@1.1 \
    b. If the one above doesn’t work run: `brew link openssl@1.1 --force`

**.zshrc File**

1. Run command `open ~/.zshrc`

2. Add the following lines, if any of these are already set make sure to comment previous settings:

```
export PATH=/usr/local/homebrew/bin:/opt/homebrew/bin:${PATH} eval "$(/usr/local/homebrew/bin/rbenv init -)"
eval "$(/usr/local/homebrew/bin/nodenv init -)"
# Add Postgres environment variables for CaseFlow
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export NLS_LANG=AMERICAN_AMERICA.UTF8
export FREEDESKTOP_MIME_TYPES_PATH=/usr/local/homebrew/share/mime/packages/freedesktop.org.xml export OCI_DIR=~/Downloads/instantclient_19_8
```

3. Save file

4. Go to your active terminal and enter source ~/.zshrc or create a new terminal

**Booz Allen Hamilton Internal**

**Configure shell env for Rosetta and x86_64 homebrew**

1. Open the terminal that was set up for “Open using Rosetta” above

2. Run the following command: `eval $(/usr/local/homebrew/bin/brew shellenv)`

**Run dev setup scripts in Caseflow repo**

*Script 1*

1. Enter a rosetta terminal and ensure you are in the directory you cloned Caseflow repo into
(~/dev/appeals/caseflow), run commands \
    a. ```git checkout grant/setup-m1``` \
    b. ```./scripts/dev_env_setup_step1.sh``` \
    **If this fails, double check the “OpenSSL” section as well as your .zshrc file

*Script 2*

1. Open a rosetta terminal and navigate to /usr/local, run commands \
    a. ```sudo ln -s /usr/local/homebrew/opt optsource``` \
    b. ```sudo ln -s /usr/local/homebrew/Cellar Cellar``` \
    c. ```sudo spctl --global-disable```

2. Navigate to caseflow/scripts/dev_env_setup_step2.sh and open in VSCode

3. Make sure you are on the branch grant/setup-m1

4. Comment out line 12 (should be like the line in #5a)

5. In terminal navigate to caseflow folder, run
    * a. ```RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr/local/opt/openssl@1.1" rbenv install 2.7.3```
    * b. `gem install pg:1.1.4 -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config`
    * c. ```gem install therubyracer -- --with-v8-dir=/usr/local/homebrew/opt/v8@3.15```
        * i. If step c. fails try running these commands first

    ``` zsh
    brew install v8@3.15
    bundle config build.libv8 --with-system-v8
    bundle config build.therubyracer --with-v8-dir=$(brew --prefix v8@3.15)
    bundle install
    ```

    * d. ```./scripts/dev_env_setup_step2.sh```
    * If you get  a permission error while running gem install or bundle install, do not run using sudo.
    Set the permissions back to you for every directory under /.rbenv
        * Enter command: `sudo chown -R <your name under /Users> /Users/<your name>/.rbenv`
            * For example, if my name is Eli Brown, the command will be:
            `sudo chown –R elibrown /Users/elibrown/.rbenv`

6. If there are no obvious errors messages, run `bundle install` to ensure all gems are, in fact, installed

**Running Caseflow**

1. Open caseflow in VSCode (optional)

2. Ensure you are on master branch and up to date by running \
    a. ```git checkout master```\
    b. ```git fetch```\
    c. ```git pull origin master``` \
**Booz Allen Hamilton Internal**
3. Start Vacols UTM VM and log into it. Open the Docker and Postgres applications. Leave all running in background

4. In caseflow, run
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
            * b. Download caseflow-db-backup.gz (not able to share this download via policy, message me)
            * c. Enter terminal, navigate to ~/Downloads
            * e. Run command
                * i. `gzip -dck caseflow-db-backup.gz | docker exec -i appeals-db psql -U postgres`
                * ii. (this command will link the caseflow_certification_database to docker)
            * f. Download this [file](https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-2/wkhtmltox-0.12.6-2.macos-cocoa.pkg) and move through the prompts (wkhtmltopdf => unrelated?)
            * g. Enter terminal, navigate to caseflow, and run \
            **Booz Allen Hamilton Internal**
                * i. `make up-m1`
                * ii. `make reset` (this will take a while)
                * iii. **Alternative fix for db not found error?
                    * a. ```bundle exec rake db:drop db:create db:schema:load```
                    * b. `bundle exec rake db:seed`
                    * c. `make install`
                    * d. Complete the Vacols VM Trigger Fix below
                    * e. `make test`
                        * i. This will time out before the command is finished executing. Have been told this is normal behavior if you have completed the VM Trigger Fix
                    * f. `make run-m1`
                        * i. Click <http://127.0.0.1:3000> to open caseflow in browser

5. Download VACOLS VM Trigger fix from this [link](https://boozallen.sharepoint.com/:u:/r/teams/VABID/appeals/Documents/Development/Developer%20Setup%20Resources/M1%20Mac%20Developer%20Setup/VACOLS_VM_trigger_fix_M1.zip?csf=1&web=1&e=pIhvuj) \
    a. Follow the instructions file, you will need to download SQLDeveloper on your local

6. After you are finished, go back to caseflow in VSCode, enter terminal, and run
    * a. `make install`
    * b. `make test`
        * i. This will time out before the command is finished executing. Have been told this is normal behavior if you have finished step 5
    * c. `make run-m1`
        * i. Click <http://127.0.0.1:3000> to open caseflow in browser
        * ii. If make run returns a message that the port is already running. Do the following:
            1. Find the port the error message is referring to. It should say close to the top of the error message
            2. Run command `lsof -i TCP:<port number here>`
            3. Run command `kill -9 <PID number here>`
            4. Run command `make run-m1 again`

After this, anytime I want to run Caseflow follow these steps:

1. Open the Docker app, Postgres app, and Vacols UTM, log in and leave running in background
2. Go to ~/Downloads and run `gzip -dck caseflow-db-backup.gz | docker exec -i appeals-db psql -U postgres`
3. `make up-m1`
4. `make run-m1` (if bootsnap errors, run this again and you should see a port is already running)
5. Run `lsof -i TCP:<port>`, then `kill –9 <pid>`
6. Run `make run-m1` again

[<< Back](README.md)
