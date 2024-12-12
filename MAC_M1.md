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

2. I am running into errors! Where can I go for help?

See the Installation Workarounds section for common or previously relevant workarounds that may help. Additionally, join the #bid_appeals_mac_support channel in Slack (or ask your scrum master to add you). You can search that channel to see if your issue has been previously discussed or post what step you are having a problem on and what you've done so far.

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

UTM Option: Install UTM and VACOLS VM
---
1. Download UTM from this [link](https://github.com/utmapp/UTM/releases/latest/download/UTM.dmg)
2. Right click UTM.app and select “install with privilege management” then open the UTM.app
3. Download the Vacols VM from this [link](https://boozallen-my.sharepoint.com/:u:/r/personal/622659_bah_com/Documents/Appeals%20Vacols%20VM%20May%202023.utm.zip?csf=1&web=1&e=TnDe7c)
4. After the file downloads, right click on it in “Finder” and select “Show Package Contents” and delete the view.plist file if it exists
5. Right click on the application and select “Open With > UTM.app (default)”
6. Select the “Play” button when it pops up in UTM
7. Leave this running in the background. If you close the window, you can open it back up by repeating steps 5-7

Colima/Docker Option with Oracle 19
---

1. In the Caseflow repo: Checkout the jshields/facols-arm-docker-build branch
2. Run: git lfs install (needed to initialize large file storage in repo)
3. Run: git lfs pull (this will pull the large zipfile)
4. Navigate to the caseflow local vacols folder caseflow/docker-bin/oracle_libs
5. Run: ./build_push.sh local
6. After the image builds a vacols image will now be in your docker images. When running [make up] vacols will spin up with the other containers
7. Running the first time: Right now when the container first starts the oracle database has to intialize. You can ssh into the contoner to see the logs and status. Once intialized should be good to go.


Chromedriver, PDFtk Server, and wkhtmltox Installation
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
9. Download and install from this [link](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-2.02-mac_osx-10.11-setup.pkg). When you receive a security warning, follow steps 3-6 for PDFtk server
10. Download this [file](https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-2/wkhtmltox-0.12.6-2.macos-cocoa.pkg) and move through the prompts. When you receive a security warning, follow steps 3-6 for wkhtmltox

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

Configure x86_64 Homebrew
---
Run the below commands **from your home directory**

1. In a terminal, create a homebrew directory under your home directory
    * ```mkdir homebrew```
2. In a terminal, run
    * ```curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew```
3. If you get a chdir error, run
    * ``mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew``

Rosetta
---
1. Open standard terminal and run:
    * ```softwareupdate -–install-rosetta –-agree-to-license```
2. Once Rosetta is installed, find the default terminal in “Finder” > Applications
3. Right click and select “Get Info”
4. Select “Open using Rosetta”
    * Note: you can copy the standard terminal executable to your desktop and enable Rosetta on that, so that you don’t need to disable rosetta on the default terminal once Caseflow setup is complete

Modify your .zshrc File
---
1. Run command `open ~/.zshrc`
2. Add the following lines, if any of these are already set make sure to comment previous settings:

```
export PATH=~/homebrew/bin:${PATH}
eval "$(~/homebrew/bin/rbenv init -)"
eval "$(~/homebrew/bin/nodenv init -)"
eval "$(~/homebrew/bin/pyenv init --path)"

# Add Postgres environment variables for CaseFlow
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export NLS_LANG=AMERICAN_AMERICA.UTF8
export FREEDESKTOP_MIME_TYPES_PATH=~/homebrew/share/mime/packages/freedesktop.org.xml export OCI_DIR=~/Downloads/instantclient_19_8
```

3. Save file
4. Go to your active terminal and enter source ~/.zshrc or create a new terminal
Note: until rbenv, nodenv, and pyenv are installed, the `eval` commands will display a 'command not found' error when launching a terminal

Run dev setup scripts in Caseflow repo
---
**VERY IMPORTANT NOTE: The below commands must be run *in a Rosetta terminal* until you reach the 'Running Caseflow' section**

***Script 1***

1. Open a **new Rosetta** terminal and ensure you are in the directory you cloned the Caseflow repo into (~/dev/appeals/caseflow) and run commands:
    1. ```git checkout grant/setup-m1```
    2. ```./scripts/dev_env_setup_step1.sh```
    * If this fails, double check your .zshrc file to ensure your PATH has only the x86_64 brew

Note: If you run into errors installing any versions of openssl, see the "Installation Workarounds" section at the bottom of this document

***Script 2***

2. In the **Rosetta** terminal, install pyenv and the required python2 version:
    1. `brew install pyenv`
    2. `pyenv rehash`
    3. `pyenv install 2.7.18`
    4. In the caseflow directory, run `pyenv local 2.7.18` to set the version
3. In the **Rosetta** terminal navigate to caseflow folder:
    1. run `rbenv install $(cat .ruby-version)`
    2. run `rbenv rehash`
    3. run `gem install bundler -v $(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)`
    4. run `gem install pg:1.1.4 -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config`
    5. Install v8@3.15 by doing the following (these steps assume that vi/vim is the default editor):
        1. run `HOMEBREW_NO_INSTALL_FROM_API=1 brew edit v8@3.15`
        2. go to line 21 in the editor by typing `:21`
      Note: the line being removed is `disable! date: "2023-06-19", because: "depends on Python 2 to build"`
        3. delete the line by pressing `d` twice
        4. save and quit by typing `:x`
        5. run `HOMEBREW_NO_INSTALL_FROM_API=1 brew install v8@3.15`
    6. Configure build opts for gem `therubyracer`:
        1. `bundle config build.libv8 --with-system-v8`
        2. `bundle config build.therubyracer --with-v8-dir=$(brew --prefix v8@3.15)`
    7. run ```./scripts/dev_env_setup_step2.sh```
  If you get a permission error while running gem install or bundle install, something went wrong with your rbenv install which needs to be fixed.
4. If there are no errors messages, run `bundle install` to ensure all gems are installed

Running Caseflow
---
**VERY IMPORTANT NOTE TWO: This is where you switch back to a *standard* (non-Rosetta) terminal**

1. Once your installation of all gems is complete, switch back to a standard MacOS terminal:
    1. open your ~/.zshrc file
    2. comment the line `export PATH=~/homebrew/bin:$PATH`
    3. uncomment the line `export PATH=/opt/homebrew/bin:$PATH`
    4. add the line `export PATH=$HOME/.nodenv/shims:$HOME/.rbenv/shims:$HOME/.pyenv/shims:$PATH`
    5. comment the lines `eval "$({binary} init -)"` for rbenv, pyenv, and nodenv if applicable
    6. if you added the line `eval $(~/homebrew/bin/brew shellenv)` after installing x86_64 homebrew, comment it out
2. Open a new terminal and verify:
	  1. that you are on arm64 by doing `arch` and checking the output
	  2. that you are using arm64 brew by doing `which brew` and ensuring the output is `/opt/homebrew/bin/brew`
3. Open caseflow in VSCode (optional), or navigate to the caseflow directory in your terminal and:
	  1. `brew install yarn`
4. Ensure you are on main branch and up to date by running
    1. ```git checkout main```
    2. ```git fetch```
    3. ```git pull origin main```
5. Start Vacols UTM VM (if not already running)
6. run `make up-m1` to create the docker containers and volumes
7. run `make reset` to (re)create and seed the database; this takes a while (~45 minutes)
	  1. if you get a database not found error, run `bundle exec rake db:drop:primary db:create:primary db:schema:load:primary`, and then run `make reset` again
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
# Installation Workarounds

M3 Mac Gem Installation
---
**Follow these steps if you are getting errors when running `bundle install`**

1. Create a new file `script.py` with the following contents:
   ```
	import subprocess
	import re

	#string = subprocess.check_output("gem query --local", shell=True)
	#string = re.findall("(?![^\\(]*\\))[A-Za-z-_]+", string.decode("utf-8"))

	with open("./gems.txt") as file:
	    lines = [line.rstrip() for line in file]

	for i in lines:
		print("bundle config build." + i + " --with-cflags=\"-Wno-error=incompatible-function-pointer-types\" --with-cppflags=\"-Wno-compound-token-split-by-macro\"")
		output = subprocess.check_output("bundle config build." + i + " --with-cflags=\"-Wno-error=incompatible-function-pointer-types\" --with-cppflags=\"-Wno-compound-token-split-by-macro\"", shell=True)

   ```
2. Create a new file `gems.txt` with the following contents:
   ```
	aasm
	actioncable
	actionmailbox
	actionmailer
	actionpack
	actiontext
	actionview
	activejob
	activemodel
	activerecord
	activerecord-import
	activerecord-oracle_enhanced-adapter
	activestorage
	activesupport
	acts_as_tree
	addressable
	akami
	amoeba
	anbt-sql-formatter
	ast
	aws-sdk
	aws-sdk-core
	aws-sdk-resources
	aws-sigv4
	backport
	benchmark-ips
	bgs
	bootsnap
	bourbon
	brakeman
	browser
	builder
	bullet
	bummr
	bundler-audit
	business_time
	byebug
	capybara
	capybara-screenshot
	caseflow
	choice
	claide
	claide-plugins
	cliver
	coderay
	colored2
	colorize
	concurrent-ruby
	connect_mpi
	connect_vbms
	connection_pool
	console_tree_renderer
	cork
	countries
	crack
	crass
	d3-rails
	danger
	database_cleaner
	date
	ddtrace
	debase
	debase-ruby_core_source
	derailed_benchmarks
	diff-lcs
	docile
	dogstatsd-ruby
	dotenv
	dotenv-rails
	dry-configurable
	dry-container
	dry-core
	dry-equalizer
	dry-inflector
	dry-initializer
	dry-logic
	dry-schema
	dry-types
	ecma-re-validator
	erubi
	execjs
	factory_bot
	factory_bot_rails
	faker
	faraday
	faraday-http-cache
	faraday_middleware
	fast_jsonapi
	fasterer
	ffi
	foreman
	formatador
	fuzzy_match
	get_process_mem
	git
	globalid
	govdelivery-tms
	guard
	guard-compat
	guard-rspec
	gyoku
	hana
	hashdiff
	heapy
	holidays
	httpclient
	httpi
	i18n
	i18n_data
	icalendar
	ice_cube
	immigrant
	jaro_winkler
	jmespath
	jquery-rails
	jshint
	json
	json_schemer
	kaminari
	kaminari-actionview
	kaminari-activerecord
	kaminari-core
	knapsack_pro
	kramdown
	kramdown-parser-gfm
	launchy
	libv8
	listen
	logstasher
	loofah
	lumberjack
	mail
	marcel
	maruku
	memory_profiler
	meta_request
	method_source
	mime-types
	mime-types-data
	mini_mime
	minitest
	moment_timezone-rails
	momentjs-rails
	msgpack
	multi_json
	multipart-post
	multiverse
	nap
	neat
	nenv
	net-imap
	net-pop
	net-protocol
	net-smtp
	newrelic_rpm
	nio4r
	no_proxy_fix
	nokogiri
	nori
	notiffany
	octokit
	open4
	paper_trail
	parallel
	paranoia
	parser
	pdf-forms
	pdfjs_viewer-rails
	pdfkit
	pg
	pluck_to_hash
	pry
	pry-byebug
	public_suffix
	puma
	racc
	rack
	rack-contrib
	rack-test
	rails
	rails-dom-testing
	rails-erd
	rails-html-sanitizer
	railties
	rainbow
	rake
	rb-fsevent
	rb-inotify
	rb-readline
	rchardet
	react_on_rails
	redis
	redis-actionpack
	redis-activesupport
	redis-classy
	redis-mutex
	redis-namespace
	redis-rack
	redis-rails
	redis-store
	ref
	regexp_parser
	request_store
	reverse_markdown
	rexml
	roo
	rspec
	rspec-core
	rspec-expectations
	rspec-github
	rspec-mocks
	rspec-rails
	rspec-retry
	rspec-support
	rspec_junit_formatter
	rubocop
	rubocop-performance
	rubocop-rails
	ruby-debug-ide
	ruby-graphviz
	ruby-oci8
	ruby-plsql
	ruby-prof
	ruby-progressbar
	ruby_dep
	ruby_parser
	rubyzip
	safe_shell
	safe_yaml
	sass
	sass-listen
	sass-rails
	savon
	sawyer
	scss_lint
	selenium-webdriver
	sentry-raven
	sexp_processor
	shellany
	shoryuken
	shoulda-matchers
	simplecov
	simplecov-html
	single_cov
	sixarm_ruby_unaccent
	sniffybara
	socksify
	solargraph
	sprockets
	sprockets-rails
	sql_tracker
	statsd-instrument
	stringex
	strong_migrations
	terminal-table
	test-prof
	therubyracer
	thor
	thread_safe
	tilt
	timecop
	timeout
	tty-tree
	tzinfo
	uglifier
	unicode-display_width
	unicode_utils
	uniform_notifier
	uri_template
	validates_email_format_of
	wasabi
	webdrivers
	webmock
	webrick
	websocket
	websocket-driver
	websocket-extensions
	xmldsig
	xmlenc
	xmlmapper
	xpath
	yard
	zeitwerk
	ziptz
   ```
3. Move both files into the `caseflow` root folder
4. In your Terminal, run `python3 script.py`
5. Run `bundle install` again
6. If any gems fail to install, manually install it by running `gem install` (e.g. `gem install pg:1.1.4`) and then run `bundle install` again to check for additional failures
7. Once `bundle install` stops throwing errors, return to the last step for Script 2 (run ```./scripts/dev_env_setup_step2.sh```)


OpenSSL
---
**When installing rbenv, nodenv, or pyenv, both openssl libraries should install as dependencies. _Only follow the below instructions if you have problems with openssl@3 or openssl@1.1 not compiling_.**

1. Download openssl@1.1 and openssl@3 from this [link](https://boozallen.sharepoint.com/teams/VABID/appeals/Documents/Forms/AllItems.aspx?id=%2Fteams%2FVABID%2Fappeals%2FDocuments%2FDevelopment%2FDeveloper%20Setup%20Resources%2FM1%20Mac%20Developer%20Setup&viewid=8a8eaf3e%2D2c12%2D4c87%2Db95f%2D4eab3428febd)
2. Open “Finder” and find the two folders under “Downloads”
3. Extract the `.tar.gz` or `.zip` archives
4. In each of the extracted folders:
    1. Navigate to the `~/homebrew/Cellar` subfolder
    2. Copy the openssl folder to your local machine's `~/homebrew/Cellar` folder
    3. If the folder `Cellar` in `~/homebrew` does not exist, create it with `mkdir ~/homebrew/Cellar`
    * Note: moving these folders can be done using finder or a terminal
5. Run command (from a rosetta terminal)
    1. `brew link --force openssl@1.1`
    2. If the one above doesn’t work run: `brew link openssl@1.1 --force`
    * Note: don't link openssl@3 unless you run into issues farther in the setup

Installing Ruby via Rbenv
---
If you are getting errors for rbenv being unable to find a usable version of openssl, run these commands prior to running the second dev setup script:
1. `brew install openssl@1.1`
2. `export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr/local/homebrew/Cellar/openssl@1.1"`

Running Caseflow
---
The following steps are an alternative to step 7 of the Running Caseflow section in the event that you absolutely cannot get those commands to work:
1. In caseflow, run
    * a. `make down`
        * i.  Removes appeals-pg, appeals-redis, and localstack docker containers
    * b. `docker-compose down –v`
        * i. Removes caseflow_postgresdata docker volume
    * c. `make up-m1`
        * i. Starts docker containers, volume, and network
    * d. `make reset`
        * i. Resets caseflow and ETL database schemas, seeds databases, and enables feature flags
        * **If `make reset` returns database not found error:
            * a. Run command `bundle exec rake db:drop:primary`
            * b. Download caseflow-db-backup.gz (not able to share this download via policy, ask in the slack channel)
            * c. Enter terminal, navigate to ~/Downloads
            * e. Run command
                * i. `gzip -dck caseflow-db-backup.gz | docker exec -i appeals-pg psql -U postgres`
                * ii. (this command will link the caseflow_certification_database to docker)
            * f. Enter terminal, navigate to caseflow, and run
                * i. `make up-m1`
                * ii. `make reset` (this will take a while)

[<< Back](README.md)
