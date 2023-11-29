## Windows 10 with WSL ######################################################

[<< Back](README.md)

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

[<< Back](README.md)
