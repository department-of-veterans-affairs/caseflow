# Caseflow
[![CircleCI](https://circleci.com/gh/department-of-veterans-affairs/caseflow/tree/master.svg?style=svg)](https://circleci.com/gh/department-of-veterans-affairs/caseflow/tree/master) [![Knapsack Pro Parallel CI builds for Caseflow RSpec Tests](https://img.shields.io/badge/Knapsack%20Pro-Parallel%20%2F%20Caseflow%20RSpec%20Tests-%230074ff)](https://knapsackpro.com/dashboard/organizations/1654/projects/1260/test_suites/1783/builds?utm_campaign=organization-id-1654&utm_content=test-suite-id-1783&utm_medium=readme&utm_source=knapsack-pro-badge&utm_term=project-id-1260)

Caseflow is a suite of web-based tools to manage VA appeals. It's currently in development by the Appeals Modernization team (est. 2016). It will replace the current system of record for appeals, the Veterans Appeals Control and Location System (VACOLS), which was created in 1979 on now-outdated infrastructure. Additionally, Caseflow will allow the Board of Veterans' Appeals to process appeals under the new guidelines created by the Veterans Appeals Improvement and Modernization Act of 2017, which goes into effect February 14th, 2019.

The Appeals Modernization team's mission is to empower employees with technology to increase timely, accurate appeals decisions and improve the Veteran experience. Most of the team's products live here, in the main Caseflow repository.

# Table of Contents

   * [Caseflow](#caseflow)
      * [Caseflow products in heavy development](#caseflow-products-in-heavy-development)
         * [Intake](#intake)
         * [Queue](#queue)
         * [Reader](#reader)
         * [Hearings](#hearings)
      * [Caseflow products in a mature state](#caseflow-products-in-a-mature-state)
         * [Dispatch](#dispatch)
         * [API](#api)
         * [Certification](#certification)
      * [Other Caseflow Products](#other-caseflow-products)
      * [Developer Setup](#developer-setup)
         * [Github](#github)
         * [Machine setup](#machine-setup)
            * [Windows 10 + WSL](#windows-10-with-wsl)
            * [Windows 11 + WSL](#windows-11-with-wsl)
            * [Mac M1/M2](#mac-m1-and-m2)
            * [Mac Intel](#mac-intel)
      * [Test Coverage](#test-coverage)
      * [Debugging FACOLS setup](#debugging-facols-setup)
      * [Monitoring](#monitoring)
      * [Roles](#roles)
      * [Running Caseflow connected to external depedencies](#running-caseflow-connected-to-external-depedencies)
      * [Dev Caseflow Usage Tweaks](#dev-caseflow-usage-tweaks)
         * [Changing between test users](#changing-between-test-users)
         * [Feature Toggle and Functions](#feature-toggle-and-functions)
         * [Out of Service](#out-of-service)
         * [Degraded Service](#degraded-service)
      * [Documentation](#documentation)

## Caseflow products in heavy development

### Intake

Tracking Appeals Modernization Act reviews in a single system.

### Queue

Workflow management at the Board of Veterans' Appeals.

### Reader

Increases the speed with which attorneys and Veterans Law Judges (VLJs)
review and annotate electronic case files.

### Hearings

Scheduling and supporting Board of Veterans' Appeals hearings.

## Caseflow products in a mature state

### Dispatch

Facilitates the transfer of cases from the Agency of Original Jurisdiction (AOJ) to
the Board of Veterans' Appeals (the Board).

### Hearing Prep

Improving the timeliness and Veteran experience of Board hearings.

### API

Providing Veterans transparent information about the status of their appeal

### Certification

Facilitates the transfer of cases from the Agency of Original Jurisdiction (AOJ) to the Board of Veterans' Appeals (the Board).

## Other Caseflow Products
| Product | GitHub Repository | Contiuous Integration Tests |
| --- | --- | ---|
| Caseflow | [caseflow](https://github.com/department-of-veterans-affairs/caseflow) | [CircleCI - Caseflow](https://circleci.com/gh/department-of-veterans-affairs/caseflow) |
| eFolder Express | [caseflow-efolder](https://github.com/department-of-veterans-affairs/caseflow-efolder) | [Circle CI - eFolder](https://circleci.com/gh/department-of-veterans-affairs/caseflow-efolder) |
| Commons | [caseflow-commons](https://github.com/department-of-veterans-affairs/caseflow-commons) | [Travis CI - Commons](https://travis-ci.org/department-of-veterans-affairs/caseflow-commons) |

## Developer Setup ####################################

### Github ############################################################

#### Organization ############################################################

Request an invite to the [department-of-veterans-affairs](https://github.com/department-of-veterans-affairs) organization

#### Git 2-factor authentication ##########################################################

We are using 2-factor authentication with Github so, for example, when you access a repository using Git on the command line using commands like git clone, git fetch, git pull or git push with HTTPS URLs, you must provide your GitHub username and your personal access token when prompted for a username and password. Follow directions [here](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) on how to do that.


## Machine setup #######################################################

You can manually go through the following steps.
Alternatively, if you have a Mac, you can clone this repo and run the following scripts:

  - `git clone https://github.com/department-of-veterans-affairs/caseflow`
  - `git checkout grant/setup-m1`
  - [dev_env_setup_step1.sh](scripts/dev_env_setup_step1.sh)
  - [dev_env_setup_step2.sh](scripts/dev_env_setup_step2.sh)

If an error occurs, it is okay to run the scripts multiple times after the error is corrected.

---

## Windows 10 with WSL ######################################################

***Pre-requisites for setup:***

1. Create GitHub user account (https://github.com)

***Setup steps:***

1. Open PowerShell as Administrator (Start menu > PowerShell > right-click > Run as Administrator) and enter these commands:
    * dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    * dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
2. Install Docker Desktop: https://hub.docker.com/editions/community/docker-ce-desktop-windows
    * After install and Windows restart, open Docker Desktop, go to Settings > General and enable "Expose daemon on tcp://localhost:2357 without TLS" and Apply & Restart

3. Download and install: https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi

4. In PowerShell (NOT as Administrator if on a BAH machine) run this command:
    * `wsl --set-default-version 1`

5. Install VS Code: https://code.visualstudio.com/
    * After installing VS Code, install the Remote - WSL extension:
    https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl

6. Download Ubuntu 20.04 LTS from Windows Store: https://www.microsoft.com/store/apps/9n6svws3rx71

7. Generate a personal access token in github: https://github.com/settings/tokens with the following scopes:
    * repo
    * workflow
    * gist write:discussion

8. Download caseflow-setup.zip

9. Launch Ubuntu 20.04 LTS (hit WinKey, type Ubuntu, hit enter)
    * Set a username and password for yourself
    * Type `explorer.exe .` and hit enter (note the trailing period)
    * Copy the caseflow-setup.zip file from Step 8 into the explorer window that opens (if you get a warning about copying "without its properties" just click Yes).
    * Run the following commands in the Ubuntu terminal:
        * Each line is a separate command, run them one at a time
        * If you are on a Booz Allen laptop, connect to Cisco VPN before continuing
        * Replace <yourtoken> with your github personal access token from step 7 (if you didn't copy it down, just regenerate it)
            * `sudo apt-get update && sudo apt-get install -y curl unzip wget`
            * `unzip caseflow-setup.zip`
            * `mkdir appeals && cd appeals`
            * `git clone https://<yourtoken>@github.com/department-of-veterans-affairs/caseflow`
            * `cd caseflow`
            * `git checkout kevin/setup-ubuntu`
            * `cp -r ~/caseflow-setup/caseflow-facols/build_facolslocal/vacols/build_facols `
            * `cp ~/caseflow-setup/*.zip local/vacols/build_facols/`
            * `rm -rf ~/__MACOSX && rm -rf ~/caseflow-setup && rm -f ~/caseflow-setup.zip`
            * `source scripts/ubuntu_setup.sh`
    * This may take a few hours to run. If you run into issues, try to keep your Ubuntu terminal window open and reach out for help if you're stuck
    * Once it finishes successfully, Caseflow can be started by opening Ubuntu and executing make run in the caseflow directory:
        * `cd ~/appeals/caseflow`
        * `make run`
    * To get the codebase into VSCode, open Ubuntu and (note the trailing period):
        * `cd ~/appeals/caseflow`
        * `code .`

---

## Windows 11 with WSL #######################################################

***Pre-requisites for setup:***

* If you have Docker Desktop installed, please follow the steps here in order to
remove it. We are unable to utilize Docker Desktop on this project due to licensing
requirements.

* Create GitHub user account (https://github.com)
    * Use a VA.gov account. Must follow the provisioning process. Use your VA email to
sign up
    * Click the link (https://vaww.oit.va.gov/services/github/), scroll to bottom for new
account submission form and for the request: add items i. department-of-veterans-affairs/appeals-team
        * department-of-veterans-affairs/Caseflow-team
    * Once you have access you must generate a personal access token for step 11
& token must be remembered & not shared or pushed visually to the repo. Generate a personal access token in github: (Located in developer settings)
https://github.com/settings/tokens with the following scopes and remember for step 11:
        * repo
        * workflow
        * gist write:discussion

***Setup Steps:***

1. Open PowerShell as Administrator (Start menu > PowerShell > right-click > Run as Administrator) and enter these commands:
    * dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    * dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

2. Download and install: https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi

3. After installing VS Code, install the Remote - WSL extension:

4. Download Ubuntu 20.04.5 LTS from Windows Store: apps.microsoft.com/store/search/Ubuntu

5. Download and install .Net Runtime 6.0.0: https://dotnet.microsoft.com/en-us/download/dotnet/6.0

6. Ensure latest Windows Drivers are installed if on Dell: Download Link to install Dell Support Assistant: Run Across System scan and perform updates as needed: https://www.bing.com/ck/a?!&&p=68372682615bcb3b28a9be38b964a8355fa7e11fe27c48edb22eeecd72 13b669JmltdHM9MTY1ODE3MzcyMiZpZ3VpZD04MmY1YTkwMC0xMGJiL TQ1Y2MtODMzMS05YWEzM DQ3MzBjM2MmaW5zaWQ9NTUwOA&ptn=3&fclid=a02f7d97-06d2-11ed-a996- 7109a4f44a36&u=a1aHR0cHM6Ly93d3cuZGVsbC5jb20vc3VwcG9ydC9jb250ZW50cy9lbi1pbi9hcnRpY2x lL3Byb2R1Y3Qtc3VwcG9ydC9zZWxmLXN1cHBvcnQta25vd2xlZGdlYmFzZS9zb2Z0d2FyZS1hbmQtZG9 3bmxvYWRzL3N1cHBvcnRhc3Npc3Q&ntb=1

7. Download caseflow-setup.zip (Request from Dev. Team: BAH LFS Transfer)

8. Copy the caseflow-setup.zip file from Step 8 into the explorer window that opens (if you get a warning about copying "without its properties" just click Yes). Warning: Cloud Syncing Interference: Can occur on Desktop, Docs, Pics paths. It is recommended to temporary turn off during this process (See removal of identifier shown below to fix if this occurs).

9. A. Launch Ubuntu 20.04.5 LTS (hit WinKey, type Ubuntu, hit enter) Set a username and password for yourself
Type explorer.exe . and hit enter (note the trailing period)
In the Ubuntu terminal perform the ls command to list the files. You will notice if Zone.Identifier files populate that will eventually have to be removed due to tracking.
Run each line is a separate command, run them one at a time
* ```sudo apt-get update && sudo apt-get install -y curl unzip wget```
* ```sudo apt upgrade``` enter 'Y' to continue
(Restart PC maybe required)

10. Launch Ubuntu 20.04.5 LTS (hit WinKey, type Ubuntu, hit enter)
Run each line is a separate command, run them one at a time
    * ```unzip caseflow-setup.zip```
    * ```mkdir appeals && cd appeals```

11. Enter your git token where <yourtoken> is below:
    * ```git clone https://<yourtoken>@github.com/department-of-veterans-affairs/caseflow```
    * ```cd caseflow```
    * ```git checkout kevin/setup-ubuntu```
    * ```cp -r ~/caseflow-setup/caseflow-facols/build_facols local/vacols/build_facols```
    * ```cp ~/caseflow-setup/*.zip local/vacols/build_facols/```
    * ```rm -rf ~/__MACOSX && rm -rf ~/caseflow-setup && rm -f ~/caseflow-setup.zip```
    * ```source scripts/ubuntu_setup.sh```
    * ```source scripts/ubuntu_setup.sh (Run twice to review log)```
    * Restart PC

12. Launch Ubuntu 20.04.5 LTS (hit WinKey, type Ubuntu, hit enter)

13. In the terminal run
    * ```ls```
    * If “Zone.Identifier” is found. Cd into the directory and remove. This is caused by cloud tracking. For example: caseflow-setup zip was on desktop before being moved into its new directory.
    * i.e. ```rm caseflow-setup.zipZone.Identifier```
14. ```cd ~/appeals/caseflow```

15. ```code .```

16. Open new terminal in VS Code. Trash old terminal.

17. In new terminal run: ```git checkout kevin/setup-ubuntu```

18. ```cd ~/appeals/caseflow```

19. Run source scripts/ubuntu_setup.sh
    a. This built out Facols 2nd time and removes a intermediate container.
    b. Run the source scripts/ubuntu_setup.sh a third time. This should do a final check for missing dependancies.

20. (In directory: cd ~/appeals/caseflow): In terminal: perform run commands:
    a. make run-backend
        i. Create a new terminal window
    b. Ensure in the ```cd ~/appeals/caseflow``` directory and run
        i. ```make run-frontend```
    c. Ctrl + C both servers to turn them off
    d. ```cd ..```
    e. ```cd ..```
    f. You can close terminal window.

21. Install all recommended extensions located in the visual studio code marketplace
    a. ES7+ React/Redux/React-Native snippets
    b. JavaScript (ES6) code snippets
    c. Remote - WSL
    d. VSCode Ruby
    e. Vscode-icons f. Docker
    g. ESLint
    h. React PropTypes Generate
    i. Ruby Solargraph
    j. VSCode Byebug Debugger k. Vscode-run-rspec-file
    l. Code Runner m. GitLens
    n. Git History
    o. Ruby
    p. SQLTools
    q. SQLTools PostgresSQL/Redis Driver
    r. Oracle Developer Tools for VS Code (SQL and PLSQL)

22. For Postgres DB: Add New Connection:
    a. Connection name*: DB-Appeals
    b. Connect using*: Server and Port
    c. Server Address*: localhost
    d. Port*: 5432
    e. Database*: caseflow_certification_development
    f. Username*: postgres
    g. Use password: Save password
    h. Password*: postgres

23. Save Connections & Test

24. Close and restart VS Code

25. branch should be up to date with master (```git checkout master```, ```git pull```)

26. ```cd ~/appeals/caseflow in terminal```

27. ```bin/rails db:migrate RAILS_ENV=development```

28. Run ```bundle install``` to install missing gems and then ```bin/rails db:migrate``` ```RAILS_ENV=development``` command if you have too again.

29. ```make reset``` (should have split_correlation_tables)

30. ```make c``` (then type ```quit``` and enter terminal if builds correct)

31. In new terminal open and run ```bundle install```

32. Open New terminal: ```make run-backend```
    a. Sometimes Port:3500 is in use and the port must be killed by it's PID value in order to run correct container. Use Commands below to help assist.
        i. ```docker ps```
        ii. ```lsof -t -i:3500```
        iii. ```ps -fu USERNAME```
    b. Commands to kill the port
        i. ```kill $(lsof –t -I:3500)```
        ii. ```kill -9 PID```

33. Open New Terminal: ```cd client```, ```yarn install```, ```cd ..```, and ```make run-frontend```

34. You should now be able to navigate to localhost:3000

35. Again, use crtl + c to stop backend & frontend

36. Created a system restore point here.

37. New branch can be created from here. I.e. ```git checkout –b feature/APPEALS-XXXX```
    a. Or just checkout if already exist and perform a git pull

38. ```git push --set-upstream origin feature/APPEALS-XXXX```

39. Develop & make some code changes and save based off of your tech lead's recommended branch setup and save changes. Push those new branches to create a draft PR.

40. Set user.email for git & set user.name for git
    a. ```git config --global user.email "you@va.gov"```
    b. ```git config –global user.name "Your Name"```

---

## Mac M1 and M2  #######################################################

***Ensure command line tools are installed via Self Service Portal prior to starting***

**Clone these Repos**

1. Create a `~/dev/appeals/` directory

2. Clone the following repos using git clone into this directory
    a. https://github.com/department-of-veterans-affairs/caseflow.git
    b. https://github.com/department-of-veterans-affairs/caseflow-commons.git
    c. https://github.com/department-of-veterans-affairs/caseflow-frontend-toolkit.git

3. Optional for setting up a machine, clone if can
    a. https://github.com/department-of-veterans-affairs/caseflow-efolder.git
    b. https://github.com/department-of-veterans-affairs/caseflow-facols.git
    c. https://github.com/department-of-veterans-affairs/appeals-notebook.git

4. If cannot clone the above might need to do https://docs.github.com/en/enterprise- server@3.4/authentication keeping-your-account-and-data-secure/creating-a-personal-access-token

**Homebrew Installation**

1. Install homebrew from self-service portal

**Docker Installation**

1. Navigate to docker website

2. Install “Docker Desktop for Mac Apple silicon”

3. Pop up of app will come up to transfer to application folder

4. Right click on the Docker app and select “install with privilege management”

5. Open terminal and run
    a. arch –arm64 brew install docker docker-compose colima
    b. mkdir -p ~/.docker/cli-plugins
    c. ln -sfn /opt/homebrew/opt/docker-compose/bin/docker-compose~/.docker/cli-plugins/docker-compose
    d. sudo mv homebrew /usr/local/homebrew
        i. (moves homebrew from /opt to /usr/local)
    e. eval $(/usr/local/homebrew/bin/brew shellenv)

**UTM and Vacols VM**

1. Download UTM from this link

2. Right click UTM.app and select “install with privilege management” then open the UTM.app

3. Download the Vacols VM from this link

4. After the file downloads, right click on it in “Finder” and select “Show Package Contents” and delete the view.plist file if it exists

5. Right click on the application and select “Open With > UTM.app (default)”

6. Select the “Play” button when it pops up in UTM

7. The virtual machine will open. To login, the password is “password”
Booz Allen Hamilton Internal

 8. Leave this running in the background. If you close the window, you can open it back up by repeating steps 5-7

**Chromedriver Installation**

1. Open terminal and run
    a. brew install --cask chromedriver

2. Once it successfully installs, run command
    a. chromedriver –version

3. There will be a pop up. Before clicking “OK,” navigate to System Settings > Privacy & Security

4. Scroll down and it will say “chromedriver was blocked form use because it is not from an identified
developer”

5. Select “Allow Anyway”

6. Select “Yes” from pop up

7. Open terminal and once again run
    a. chromedriver –version 8. Select “Open”

**PDFtk Server**

1. Download from this curl -L http:link

**Configure x86_64 Homebrew**

1. Create a homebrew directory under your home directory
    a. ```mkdir homebrew```

2. Open terminal and run
    a. ```curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew```

3. If chdir error run
    a. ``mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew``

4. Using sudo, move the homebrew directory to /usr/local/
    a. ```sudo mv homebrew /usr/local/homebrew```

**Rosetta**

1. Open standard terminal and run:
    a. ```softwareupdate –install-rosetta –agree-to-license```
2. Once Rosetta is installed, find the default terminal in “Finder” > Applications

3. Right click and select “Get Info”

4. Select “Open using Rosetta”
    Note: you can copy the standard terminal executable to your desktop and enable Rosetta on that, so that you don’t need to disable rosetta on the default terminal once Caseflow setup is complete

*Booz Allen Hamilton Internal*

**Oracle “instantclient” Files**

1. Download these DMG files
    a. instantclient-basic-macos.x64-19.8.0.0.0dbru.dmg
    b. instantclient-sqlplus-macos.x64-19.8.0.0.0dbru.dmg
    c. Instantclient-sdk-macos.x64-19.8.0.0.0dbru.dmg

2. After downloading, click on one of the folders and follow the instructions in INSTALL_IC_README.txt

**Postgres Download**

1. Download from this link

**OpenSSL**

1. Download openssl@1.1 and openssl@3 from this link

2. Open “Finder” and find the two folders under “Downloads”

3. Open openssl@1.1 and find the child folder 1.1.1s

4. Click 1.1.1s, duplicate it, and rename the duplicate folder 1.1.1t

5. Open openssl@3 and find the child folder 3.0.7

6. Click 3.0.7, duplicate it, and rename the duplicate folder 3.1.0

7. Open a second “Finder” window and navigate to /usr/local/homebrew/Cellar

8. Move openssl@1.1 and openssl@3 to the Cellar folder

9. Run command (from a rosetta terminal)
    a. brew link --force openssl@1.1
    b. If the one above doesn’t work run: brew link openssl@1.1 --force

**.zshrc File**

1. Run command
    a. ```open ~/.zshrc```

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

*Booz Allen Hamilton Internal*

**Configure shell env for Rosetta and x86_64 homebrew**

1. Open the terminal that was set up for “Open using Rosetta” above

2. Run the following command:
    a. ```eval $(/usr/local/homebrew/bin/brew shellenv)```

**Run dev setup scripts in Caseflow repo**

*Script 1*

1. Enter a rosetta terminal and ensure you are in the directory you cloned Caseflow repo into
(~/dev/appeals/caseflow), run commands
    a. ```git checkout grant/setup-m1```
    b. ```./scripts/dev_env_setup_step1.sh```
    **If this fails, double check the “OpenSSL” section as well as your .zshrc file

*Script 2*

1. Open a rosetta terminal and navigate to /usr/local, run commands
    a. ```sudo ln -s /usr/local/homebrew/opt optsource```
    b. ```sudo ln -s /usr/local/homebrew/Cellar Cellar```
    c. ```sudo spctl --global-disable```

2. Navigate to caseflow/scripts/dev_env_setup_step2.sh and open in VSCode

3. Make sure you are on the branch grant/setup-m1

4. Comment out line 12 (should be like the line in #5a)

5. In terminal navigate to caseflow folder, run
    a. ```RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr/local/opt/openssl@1.1" rbenv install 2.7.3```
    b. ```gem install pg –v '1.1.4' -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config```
    c. ```gem install therubyracer -- --with-v8-dir=/usr/local/homebrew/opt/v8@3.15```
    d. ```./scripts/dev_env_setup_step2.sh```
    **If you get a permission error while running gem install or bundle install, do not run using sudo. Set the permissions back to you for every directory under /.rbenv

Enter command:
    a. ```sudo chown -R <your name under /Users> /Users/<your name>/.rbenv```
        • For example, if my name is Eli Brown, the command will be:
        ```sudo chown –R elibrown /Users/elibrown/.rbenv```

6. If there are no obvious errors messages, run bundle install to ensure all gems are, in fact, installed

**Running Caseflow**

1. Open caseflow in VSCode (optional)

2. Ensure you are on master branch and up to date by running
    a. ```git checkout master```
    b. ```git fetch```
    c. ```git pull origin master```

*Booz Allen Hamilton Internal*
3. Start Vacols UTM VM and log into it. Open the Docker and Postgres applications. Leave all running in background

4. In caseflow, run
    a. make down
        i. Removes appeals-db, appeals-redis, and localstack docker containers
    b. docker-compose down –v
        i. Removes caseflow_postgresdata docker volume
    c. make up-m1
        i. Starts docker containers, volume, and network
    d. make reset
        i. Resets caseflow and ETL database schemas, seeds databases, and enables feature flags
    **If “make reset” returns database not found error:
        a. Run command “bundle exec rake db:drop”
        b. Download caseflow-db-backup.gz (not able to share this download via policy, message me)
        c. Enter terminal, navigate to ~/Downloads
        e. Run command
            i. “gzip -dck caseflow-db-backup.gz | docker exec -i appeals-db psql -U postgres”
            ii. (this command will link the caseflow_certification_database to docker)
        f. Download this file and move through the prompts (wkhtmltopdf => unrelated?)
        g. Enter terminal, navigate to caseflow, and run
            *Booz Allen Hamilton Internal*
           i. make up-m1
            ii. make reset (this will take a while)
    **Alternative fix for db not found error?
        1. bundle exec rake db:drop db:create db:schema:load
        2. bundle exec rake db:seed
        3. make install
        4. Complete the Vacols VM Trigger Fix below
        5. make test
            a. This will time out before the command is finished executing. Have been told this is normal behavior if you have completed the VM Trigger Fix
        6. make run-m1
            a. Click http://127.0.0.1:3000 to open caseflow in browser

5. Download VACOLS VM Trigger fix from this link
    a. Follow the instructions file, you will need to download SQLDeveloper on your local

6. After you are finished, go back to caseflow in VSCode, enter terminal, and run
    a. make install
    b. make test
        i. This will time out before the command is finished executing. Have been told this is normal behavior if you have finished step 5
    c. make run-m1
        i. Click http://127.0.0.1:3000 to open caseflow in browser
**If make run returns a message that the port is already running. Do the following:
    1. Find the port the error message is referring to. It should say close to the top of the error message
    2. Run command lsof -i TCP:<port number here>
    3. Run command kill -9 <PID number here>
    4. Run command make run-m1 again

After this, anytime I want to run Caseflow follow these steps:
    1. Open the Docker app, Postgres app, and Vacols UTM, log in and leave running in background
    2. Go to ~/Downloads and run gzip -dck caseflow-db-backup.gz | docker exec -i appeals-db psql -U postgres
    3. make up-m1
    4. make run-m1 (if bootsnap errors, run this again and you should see a port is already running)
    5. Run lsof -i TCP:<port>, then kill –9 <pid>
    6. Run make run-m1 again

---

## Mac Intel  ##################################################

**Pre-requisites for setup:**

1. Create GitHub user account [VA github access process](https://department-of-veterans-affairs.github.io/github-handbook/guides/onboarding/getting-access)

2. Create [DockerHub](https://hub.docker.com/signup) user account or [install colima](https://github.com/abiosoft/colima#installation)

3. Create [oracle.com](http://oracle.com/) user account to download instant client [Create Account](https://profile.oracle.com/myprofile/account/create-account.jspx) (Step can be skipped if you have the zip files from file transfer)

4. Install github on the Mac (here)

5. Install git-lfs for pulling large files down from github [Install instructions](https://git-lfs.github.com/)

**Setup steps:**

1. Open the terminal - The terminal will open to your user folder (I.E youruser@host ~ %)
2. Install Homebrew
    a. Using BAH Self Service if BAH employee Run ```brew install git-lfs .``` This is required to clone caseflow-facols repo

3. Create a caseflow-setup folder by typing: `mkdir caseflow-setup` (step can be skipped if you have the file transfer files)

4. Change directory to caseflow-setup by typing: `cd caseflow-setup`

5. Navigate to [instant client](https://www.oracle.com/database/tecdchnologies/instant-client/linux-x86-64-downloads.html)

6. Download the following zip files to caseflow-setup directory (Copy from downloads to the caseflow-setup directory if they download to downloads) (Step can be skipped if you received the file transfer files)
    * instantclient-basic-linux.x64-12.2.0.1.0.zip
    * instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
    * instantclient-sdk-linux.x64-12.2.0.1.0.zip

7. Clone caseflow repositories required for setup into caseflow-setup directory (caseflow-facols requires github account and the account has to be in the VA org in github and can be found in the file transfer files) pwd
    * HTTP protocol
        * `git clone https://github.com/department-of-veterans-affairs/caseflow.git`
        * `git clone https://github.com/department-of-veterans-affairs/caseflow-facols.git`
            * Upon completion, navigate to caseflow-facols (`cd ~/caseflow-setup/caseflow-facols`)
            * Run: `git lfs install` (needed to initialize large file storage in repo)
            * Run: `git lfs pull` (this will pull the large zipfile)
        * If you do not have VA access yet to clone caseflow-vacols can contact (Your Tech lead or the bid_appeals_mac_support channel) to receive a zip of the repository

**SSH protocol**

1. `git clone git@github.com:department-of-veterans-affairs/caseflow.git`

2. `git clone git@github.com:department-of-veterans-affairs/caseflow-facols.git`
    * Upon completion, navigate to caseflow-facols (`cd ~/caseflow-setup/caseflow-facols`)
    * Run: `git lfs install` (needed to initialize large file storage in repo)
    * Run: `git lfs pull` (this will pull the large zipfile)

3. Navigate to the caseflow directory in your terminal (type: `cd ~/caseflow-setup/caseflow`) and checkout the grant/setup-no-aws branch `git checkout grant/setup-no-aws`

4. Navigate to caseflow/docker-bin directory (type: `cd docker-bin`)

5. Create oracle_libs subdirectory (type: `mkdir oracle_libs`)

6. Copy the 3 instant-client zip files from the caseflow-setup directory into the oracle_libs directory

7. Navigate to the caseflow root directory (type: `cd ..`)

8. Run scripts/dev_env_setup_step1.sh script from bash terminal (How to run script in Mac Terminal) (Will be prompted for a password will be the SUDO password which is the password used to log into mac after restart)
    * If/When mac says Chromedriver cannot be opened do this:
        * Click cancel on the warning modal
        * Push Command + Space
        * Type System Preferences
        * Click Security and Privacy
        * Click General tab
        * Click the lock icon and put in your BAH pin Click allow anyway on chromedriver warning Click the lock icon to re lock

9. Setup Docker to use 4 CPUs and 8G memory and sign-in to your personal DockerHub account
    * To get to these settings:
        * Command + Space
        * Type docker
        * Click docker desktop
        * Click the gear icon
        * Click Resources

10. The script updated your bash profile and you need to resource it into the terminal by typing: `source ~/.bash_profile`
    * If using zsh, will need to update and `source ~/.zshrc` instead

11. `brew install shared-mime-info`

12. `brew install v8@3.15`

13. Run scripts/dev_env_setup_step2.sh script (may take a while to run)

14. Run `gem install bundler`
    * Copy the caseflow-facols/build_facols directory to the caseflow/local/vacols subdirectory. (Ensure you have a caseflow/local/vacols/build_facols directory with all the files before continuing to the next step)

15. Navigate to caseflow/local/vacols in terminal `cd ~/caseflow- setup/caseflow/local/vacols`

16. Run `./build_push.sh local`
    * Requires the oracle database image to have been pulled after running scripts/dev_env_setup_step1.sh script

17. Navigate to caseflow root directory `cd ~/caseflow-setup/caseflow`

18. Run `docker-compose up –d`

19. Run bundle exec rake db:create
    * If you get connection issues stating no file to be found, run the following:
        * `rm /opt/homebrew/var/postgres/postmaster.pid` or possibly `rm /usr/local/var/postgres/postmaster.pid`
        * `brew services restart postgresql`

20. Run `bundle exec rake local:vacols:seed`

21. Run `bundle exec rake db:schema:load db:seed`

22. Open a new tab in terminal

23. In new tab run make: ```run-backend```

24. In the old tab run: ```make run-frontend```

25. Navigate to localhost:3000 in browser to see the application

---

## Test Coverage  #######################################################

We use the [simplecov](https://github.com/colszowka/simplecov) gem to evaluate test coverage as part of the CircleCI process.

If you see a test coverage failure at CircleCI, you can evaluate test coverage locally for the affected files using
the [single_cov](https://github.com/grosser/single_cov) gem.

Locally, add the below statement to the first line of any rspec file:

```
SingleCov.covered!
```

and run that file under rspec.

```
SINGLE_COV=true bundle exec rspec spec/path/to/file_spec.rb
```

Missing test coverage will be reported automatically at the end of the test run.

---

## Debugging FACOLS setup  #######################################################
See debugging steps as well as more information about FACOLS in our [wiki](https://github.com/department-of-veterans-affairs/caseflow/wiki/FACOLS#debugging-facols) or join the DSVA slack channel #appeals-facols-issues.

Review the [FACOLS documentation](docs/FACOLS.md) for details.

## Monitoring  #######################################################
We use NewRelic to monitor the app. By default, it's disabled locally. To enable it, do:

```
NEW_RELIC_LICENSE_KEY='<key as displayed on NewRelic.com>' NEW_RELIC_AGENT_ENABLED=true bundle exec foreman start
```

You may wish to do this if you are debugging our NewRelic integration, for instance.

---

## Roles  #######################################################

When a VA employee logs in through the VA's unified login system (CSS) a session begins with the user.
Within this session the user gets a set of roles. These roles determine what pages a user has access to.
In dev mode, we don't log in with CSS and instead take on the [identity of a user in the database](#changing-between-test-users).

## Running Caseflow connected to external depedencies
To test the app connected to external dependencies, you'll need to set up Oracle, decrypt the environment variables, install staging gems, and run the app.

## Environment variables  #######################################################

First you'll need to install ansible-vault and credstash.
```sh
pip install ansible-vault
pip install credstash
```
For more credstash setup, follow [the doc](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/credstash.md#using-credstash)

We'll need to obtain the Ansible vault password using credstash:

```sh
export VAULT_PASSWORD=$(credstash -t appeals-credstash get devops.vault_pass)
```

Clone the [appeals-deployment](https://github.com/department-of-veterans-affairs/appeals-deployment/) repo, and run:

```sh
./decrypt.sh $VAULT_PASSWORD
```

In order to load these environment variables, run:

```sh
source /path/to/appeals-deployment/decrypted/uat/env.sh
```

### Install staging gems
Install the gems required to run the app connected to VBMS and VACOLS:

```sh
bundle install --with staging
```

### Run the app

```sh
bundle exec rails s -e staging
```

---

## Dev Caseflow Usage Tweaks  #######################################################
### Changing between test users
Select 'Switch User' from the dropdown or navigate to
[http://localhost:3000/dev/users](http://localhost:3000/test/users). You can use
this page to switch to any user that is currently in the database. The users' names specify
what roles they have and therefore what pages they can access. To add new users with new
roles, you should seed them in the database via the seeds.rb file. The css_id of the user
should be a comma separated list of roles you want that user to have.

In order to impersonate other user, the user will need to have Global Admin role.
(To grant a role refer to https://github.com/department-of-veterans-affairs/caseflow-commons#functions)
On test/users page, switch to a user that has Global Admin role. `Log in as user` interface
will show up where you will have to specify User ID and Station ID.


This page also contains links to different parts of the site to make dev-ing faster. Please
add more links and users as needed.


### Feature Toggle and Functions

See [Caseflow Commons](https://github.com/department-of-veterans-affairs/caseflow-commons)

### Out of Service

To enable and disable 'Out of Service' feature using `rails c`. Example usage:

```
# enable globally
Rails.cache.write("out_of_service", true)

# enable for certification only
Rails.cache.write("certification_out_of_service", true)

# enable for dispatch only
Rails.cache.write("dispatch_out_of_service", true)

# enable for hearings only
Rails.cache.write("hearings_out_of_service", true)

# enable for reader only
Rails.cache.write("reader_out_of_service", true)

# to disable, e.g.
Rails.cache.write("certification_out_of_service", false)
```

### Degraded Service
We show a "Degraded Service" banner across all Caseflow applications automatically when [Caseflow Monitor](https://github.com/department-of-veterans-affairs/caseflow-monitor) detects that our dependencies may be down. To enable this banner manually, overriding our automatic checks, run the following code from the Rails console:
```
Rails.cache.write(:degraded_service_banner, :always_show)
```

When the dependencies have recovered, switch the banner back to automatic mode:
```
Rails.cache.write(:degraded_service_banner, :auto)
```

*DANGER*: If Caseflow Monitor is incorrectly reporting a dependency issue, you can disable the "Degraded Service" banner with the following code:
```
Rails.cache.write(:degraded_service_banner, :never_show)
```

When Caseflow Monitor starts working again, switch the banner back to automatic mode:
```
Rails.cache.write(:degraded_service_banner, :auto)
```

---

## Documentation  #######################################################

We have a lot of technical documentation spread over a lot of different repositories. Here is a non-exhaustive mapping of where to find documentation:

- [Local Caseflow Setup](https://github.com/department-of-veterans-affairs/caseflow/tree/master/docs)
- [Test data setup in lower environments](https://github.com/department-of-veterans-affairs/appeals-qa/tree/master/docs)
- [Caseflow specific devops documentation](https://github.com/department-of-veterans-affairs/appeals-deployment/tree/master/docs) This folder also contains our [first responder manual](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/first-responder-manual.md), which is super in understanding our production systems.
- [Non-Caseflow specific devops documentation](https://github.com/department-of-veterans-affairs/devops/tree/master/docs). This documentation is shared with the vets.gov team, so not all of it is relevant.
- [Project documentation](https://github.com/department-of-veterans-affairs/appeals-design-research/tree/master/Project%20Folders)
