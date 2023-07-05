## Mac Intel  ##################################################

[<< Back](README.md)

**Pre-requisites for setup:**

1. Create GitHub user account [VA github access process](https://department-of-veterans-affairs.github.io/github-handbook/guides/onboarding/getting-access)

2. Create [DockerHub](https://hub.docker.com/signup) user account or [install colima](https://github.com/abiosoft/colima#installation)

3. Create [oracle.com](http://oracle.com/) user account to download instant client [Create Account](https://profile.oracle.com/myprofile/account/create-account.jspx) (Step can be skipped if you have the zip files from file transfer)

4. Install github on the Mac [here](https://desktop.github.com/)

5. Install git-lfs for pulling large files down from github [Install instructions](https://git-lfs.github.com/)

**Setup steps:**

1. Open the terminal - The terminal will open to your user folder (I.E youruser@host ~ %)
2. Install Homebrew
    * a. Using BAH Self Service if BAH employee Run ```brew install git-lfs .``` This is required to clone caseflow-facols repo

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

19. Run `bundle exec rake db:create`
    * If you get connection issues stating no file to be found, run the following:
        * `rm /opt/homebrew/var/postgres/postmaster.pid` or possibly `rm /usr/local/var/postgres/postmaster.pid`
        * `brew services restart postgresql`

20. Run `bundle exec rake local:vacols:seed`

21. Run `bundle exec rake db:schema:load db:seed`

22. Open a new tab in terminal

23. In new tab run make: ```run-backend```

24. In the old tab run: ```make run-frontend```

25. Navigate to localhost:3000 in browser to see the application

[<< Back](README.md)
