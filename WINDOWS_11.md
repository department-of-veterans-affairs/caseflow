## Windows 11 with WSL #######################################################

[<< Back](README.md)

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

[<< Back](README.md)
