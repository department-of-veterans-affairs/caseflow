## Mac Intel  ##################################################

[<< Back](README.md)

**Pre-requisites for setup:**
**Some steps require completing VA On-boarding**

1. Create GitHub user account [VA github access process](https://department-of-veterans-affairs.github.io/github-handbook/guides/onboarding/getting-access)

2. Create [DockerHub](https://hub.docker.com/signup) user account or [install colima](https://github.com/abiosoft/colima#installation)

3. Create [oracle.com](http://oracle.com/) user account to download instant client [Create Account](https://profile.oracle.com/myprofile/account/create-account.jspx) (Step can be skipped if you have the zip files from file transfer)

4. Install github on the Mac [here](https://desktop.github.com/)

5. Install git-lfs for pulling large files down from github [Install instructions](https://git-lfs.github.com/)

**Setup steps:**

1. Open the terminal - The terminal will open to your user folder (I.E youruser@host ~ %)
2. Install Homebrew
    * a. Using BAH Self Service if BAH employee Run ```brew install git-lfs .``` This is required to clone caseflow-facols repo

3. Create an appeals folder by typing: `mkdir ~/appeals` 

4. Change directory to appeals by typing: `cd appeals`

5. Navigate to [instant client](https://www.oracle.com/database/tecdchnologies/instant-client/linux-x86-64-downloads.html)

6. Download the following zip files (Step can be skipped if you received the file transfer files)
    * instantclient-basic-linux.x64-12.2.0.1.0.zip
    * instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
    * instantclient-sdk-linux.x64-12.2.0.1.0.zip

7. Clone the following caseflow repositories required into appeals directory
    * https://github.com/department-of-veterans-affairs/caseflow
    * https://github.com/department-of-veterans-affairs/caseflow-facols

8. Upon completion, navigate to caseflow-facols (`cd ~/appeals/caseflow-facols`)
    1. Run: `git lfs install` (needed to initialize large file storage in repo)
    2. Run: `git lfs pull` (this will pull the large zipfile)
    3. Copy the `~/appeals/caseflow-facols/build_facols` directory into `~/appeals/caseflow/local/vacols/` directory.

9. Navigate to the caseflow directory in your terminal (type: `cd ~/appeals/caseflow`) and checkout the grant/setup-no-aws branch `git checkout grant/setup-no-aws`

10. Navigate to caseflow/docker-bin directory (type: `cd docker-bin`)

11. Create oracle_libs subdirectory (type: `mkdir oracle_libs`)

12. Copy the 3 instant-client zip files from step 6 into the oracle_libs directory

13. Navigate to the caseflow root directory (type: `cd ~/appeals/caseflow`)

14. Run `scripts/dev_env_setup_step1.sh` script from bash terminal (How to run script in Mac Terminal) (Will be prompted for a password will be the SUDO password which is the password used to log into mac after restart)
    * If/When mac says Chromedriver cannot be opened do this:
        * Click cancel on the warning modal
        * Push Command + Space
        * Type System Preferences
        * Click Security and Privacy
        * Click General tab
        * Click the lock icon and put in your BAH pin Click allow anyway on chromedriver warning Click the lock icon to re lock

15. Setup Docker to use 4 CPUs and 8G memory and sign-in to your personal DockerHub account
    * To get to these settings:
        * Command + Space
        * Type docker
        * Click docker desktop
        * Click the gear icon
        * Click Resources

16. The script updated your bash profile and you need to resource it into the terminal by typing: `source ~/.bash_profile`
    * If using zsh, will need to update and `source ~/.zshrc` instead

17. `brew install shared-mime-info`

18. `brew install v8@3.15`

19. Run `scripts/dev_env_setup_step2.sh` script (may take a while to run)

20. Run `gem install bundler`

21. Navigate to `~/appeals/caseflow/local/vacols` in terminal (type: `cd ~/appeals/caseflow/local/vacols`)

22. To install the latest and enterprise Oracle Database version follow (https://seanstacey.org/deploying-an-oracle-database-19c-as-a-docker-container/2020/09/) guide.
    1. Go to http://container-registry.oracle.com/ (Here log in and opt for Database)
    2. On command line `docker login container-registry.oracle.com`
    3. On command line `docker pull container-registry.oracle.com/database/enterprise:latest`
       
23. Run `./build_push.sh local`

24. Navigate to caseflow root directory `cd ~/appeals/caseflow`

25. Run `ln -s Makefile.example Makefile`

26. Run `make up`

27. Run `make reset`
   * If issues occur:
      1.  Run `bundle exec rake db:create`
         * If you get connection issues stating no file to be found, run the following:
            * `rm /opt/homebrew/var/postgres/postmaster.pid` or possibly `rm /usr/local/var/postgres/postmaster.pid`
            * `brew services restart postgresql`
      2. Run `bundle exec rake local:vacols:seed`
      3. Run `bundle exec rake db:schema:load db:seed`

27. Open a new tab in terminal

28. In new tab run make: ```run-backend```

29. In the old tab run: ```make run-frontend```

30. Navigate to localhost:3000 in browser to see the application

[<< Back](README.md)
