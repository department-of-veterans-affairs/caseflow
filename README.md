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
            * [Basic Dependencies](#basic-dependencies)
            * [Setup <a href="https://github.com/rbenv/rbenv">rbenv</a> &amp; <a href="https://github.com/nodenv/nodenv">nodenv</a>.](#setup-rbenv--nodenv)
            * [Install <a href="https://www.pdflabs.com/tools/pdftk-server/" rel="nofollow">PDFtk Server</a>](#install-pdftk-server)
            * [Install Database Clients](#install-database-clients)
            * [Install Docker](#install-docker)
            * [Install chromedriver](#install-chromedriver)
            * [Clone this repo](#clone-this-repo)
            * [Install Ruby dependencies](#install-ruby-dependencies)
            * [Install JavaScript dependencies](#install-javascript-dependencies)
            * [Setup the development Postgres user](#setup-the-development-postgres-user)
            * [Database environment setup](#database-environment-setup)
      * [Running dev Caseflow &amp; Accessing dev DBs](#running-dev-caseflow--accessing-dev-dbs)
         * [Running Caseflow](#running-caseflow)
         * [Seeding Data](#seeding-data)
         * [Connecting to databases locally](#connecting-to-databases-locally)
      * [Running tests](#running-tests)
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


### Machine setup #######################################################

You can manually go through the following steps.
Alternatively, if you have a Mac, you can clone this repo and run the following scripts:

  - `git clone https://github.com/department-of-veterans-affairs/caseflow`
  - [dev_env_setup_step1.sh](scripts/dev_env_setup_step1.sh)
  - [dev_env_setup_step2.sh](scripts/dev_env_setup_step2.sh)

Remember to follow the instructions printed at the end of the scripts.
If an error occurs, it is okay to run the scripts multiple times after the error is corrected.

#### Basic Dependencies #######################################################

**Mac**

Install the Xcode commandline tools

`xcode-select --install`

Install the base dependencies via Homebrew:

```
brew install rbenv nodenv yarn
brew tap ouchxp/nodenv
brew install nodenv-nvmrc
brew tap caskroom/cask
brew install --cask chromedriver
```
**Linux**

* [Install rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer)
* [Install nodenv](https://github.com/nodenv/nodenv-installer#nodenv-installer)
* [Install yarn](https://yarnpkg.com/lang/en/docs/install)

Ubuntu specific
```
sudo apt-get install git curl
```
Fedora specific
```
sudo dnf install git-core zlib zlib-devel gcc-c++ patch readline \
  readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 \
  autoconf automake libtool bison curl
```


#### Setup [rbenv](https://github.com/rbenv/rbenv) & [nodenv](https://github.com/nodenv/nodenv). ####

Run `rbenv init` and do what it tells you.

Run `nodenv init` and do what it tells you.

Once you've done that, close your terminal window and open a new one. Verify that both environment managers are running:

    $ env | grep ENV_SHELL
    NODENV_SHELL=bash
    RBENV_SHELL=bash

If you don't see both, stop and debug.

#### Install [PDFtk Server](https://www.pdflabs.com/tools/pdftk-server/) ########################

**Mac**
Unfortunately, the link on the website points to a version for older macOS that doesn't work on current versions. Use this link found on a Stack Overflow post instead:

[PDFtk Server for modern macOS](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-2.02-mac_osx-10.11-setup.pkg)

**Ubuntu**
Available for Ubuntu in the software manager.

**Fedora**
[Fedora Instructions](https://www.linuxglobal.com/pdftk-works-on-centos-7/)

#### Install Database Clients #######################################################

_Postgres_
**Mac & Linux**
Install postgres client and developer libraries.
The postgres server is not needed. If you install it, configure it to run on a different port or you will block the docker container.
Add these postgres variables to your env:

```
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
```

_Oracle_
You'll need to install the libraries required to connect to the VACOLS Oracle database.

**Mac**

1) Run the Homebrew install command for the "Instant Client Package - Basic" library:

```
    brew tap InstantClientTap/instantclient
    brew install instantclient-basic
```

2) Homebrew will error and give you instructions to complete a successful installation:

    - Follow the link to the download page
    - Log in or create an Oracle account
    - Accept the license agreement
    - Download the linked zip file
    - Move and rename the file
    - rerun the `brew install instantclient-basic` command

3) Do the same thing for the "Instant Client Package - SDK" library; run the install command:

    `brew install instantclient-sdk`

    ...and follow the corresponding steps in Homebrew's error message.

**Linux**
[Install oracle](https://github.com/kubo/ruby-oci8/blob/master/docs/install-instant-client.md#install-oracle-instant-client-packages)
 - Last known working at Oracle Instant Client v12;
 - Follow _all the steps_ for the zip install.
 - Requires instant-client, sdk, and sql\*plus packages.
 - Don't skip the lib softlink

You probably have to create an Oracle account to download these.

(May need to have your user own the oracle /opt directory?)

**Windows**
1) Download the ["Instant Client Package - Basic" and "Instant Client Package - SDK"](https://www.oracle.com/technetwork/database/database-technologies/instant-client/downloads/index.html) for Windows 32 or 64bit.

2) Unzip both packages into `[DIR]`

3) Add `[DIR]` to your `PATH`

#### Install Docker ####################################################################

**Mac**
Install Docker on your machine via Homebrew:

```
    brew install --cask docker
```

Once Docker's installed, run the application and go into advanced preferences to limit Docker's resources in order to keep FACOLS from consuming your Macbook.  Recommended settings are 4 CPUs, 8 GiB of internal memory, and 512 MiB of swap.

Back in the terminal, run:
```
docker login -u dsvaappeals
```

The password is in the DSVA 1Password account.
Note you can use your personal account as well, you'll just have to accept the license agreement for the [Oracle Database docker image](https://store.docker.com/images/oracle-database-enterprise-edition). To accept the agreement, checkout with the Oracle image on the docker store.

**Linux**

[Install docker-ce](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

Follow the directions to set docker to run without sudo.

Back in the terminal, run:
```
docker login -u dsvaappeals
```

The password is in the DSVA 1Password account.
Note you can use your personal account as well, you'll just have to accept the license agreement for the [Oracle Database docker image](https://store.docker.com/images/oracle-database-enterprise-edition). To accept the agreement, checkout with the Oracle image on the docker store.

You may need to adjust your base disk image size to accomodate FACOLS and restart docker. Example:

```
$ cat /etc/docker/daemon.json
{
  "debug": true,
  "storage-opts" : [ "dm.basesize=256G" ]
}
$ systemctl restart docker
```

#### Install chromedriver

Allows the feature tests to run locally.

**Mac**
```
brew install --cask chromedriver
chromedriver --version
```

**ubuntu**
```
sudo apt-get update
sudo apt-get install -y unzip xvfb libxi6 libgconf-2-4
sudo curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add
sudo echo "deb [arch=amd64]  http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
sudo apt-get -y update
sudo apt-get -y install google-chrome-stable
wget https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
sudo mv chromedriver /usr/bin/chromedriver
sudo chown root:root /usr/bin/chromedriver
sudo chmod +x /usr/bin/chromedriver
rm chromedriver_linux64.zip
chromedriver --version
```


#### Clone this repo #######################################################
Navigate to the directory you'd like to clone this repo into and run:

    git clone https://github.com/department-of-veterans-affairs/caseflow.git

#### Install Ruby dependencies ##############################################

```
cd caseflow
rbenv install $(cat .ruby-version)
rbenv rehash
# BUNDLED_WITH<VERSION> is at the bottom Gemfile.lock
gem install bundler -v BUNDLED_WITH
# If when running gem install bundler above you get a permissions error,
# this means you have not propertly configured your rbenv.
# Debug.
# !! Do *not* proceed by running sudo gem install bundler. !!
bundle install
```

This should install clean. If you have errors, you probably missed a dependency (like the Oracle libraries).

#### Install JavaScript dependencies #########################################

    cd caseflow
    nodenv install $(cat .nvmrc)
    nodenv rehash
    cd client
    yarn install

This should install clean. If you have errors, ask for help in the slack.

#### Setup the development Postgres user #####################################

Add these to your `.bash_profile`:

```
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export NLS_LANG=AMERICAN_AMERICA.UTF8
```

The last env var silences one of the Oracle warnings on startup.

(Reload the file `source ~/.bash_profile`)

#### Makefile

An example Makefile is included in the repo, that can ease some of the setup and common development tasks. To use it,
try:

```
% ln -s Makefile.example Makefile
```

Many of the examples that follow have alternate `make` targets for convenience. They are spelled out here
for clarity as to what is happening "behind the scenes."

#### Database environment setup

**Note:** You must have [AWS access granted & setup](https://github.com/department-of-veterans-affairs/appeals-deployment/wiki/New-Hires) prior to setting up your local environment as the database is not publicly accessible due to Oracle licensing.

To rapidly set up your local development (and testing) environment, run:
```
bundle exec rake local:build
```
The above shortcut runs a set of commands in sequence that should build your local environment. If you need to troubleshoot the process, you can copy each individual step out of the task and run them independently.


## Running dev Caseflow & Accessing dev DBs ##################

We use [docker](https://docs.docker.com/) and [docker-compose](https://docs.docker.com/compose/) to mock a production environment locally.  Prior knowledge of docker is not required and slowly learning how docker works is encouraged. Please ask a team member for an overview, and/or slowly review the docs linked.

Your development setup of caseflow runs Redis, Postgres and OracleDB (VACOLS) in Docker.

### Running Caseflow ###################################################

To run caseflow:
```
make run
```

**Note:** The Docker containers must always be running in order for the Rails application to start successfully. Some rake tasks will start them automatically, but if you restart your computer or otherwise stop Docker, you'll want to run `docker-compose up -d` to start the containers initially.

```
docker-compose up -d
foreman start
```

Spinning up the docker containers is fast, but not instantaneous Occasionally, running `foreman start` *immediately* after `docker-compose up -d`, can cause the rails server to fail to start because not all of the containers are ready. For example, the following _may_ not work:

```
docker-compose up -d && foreman start
```

`Makefile.example` provides a bunch of useful shortcuts, one of which is the `run` directive. `run` will ensure that all of the dockers containers are ready before running `foreman start`.

Example:

```
make -f Makefile.example run
```

#### Separate Front & Backend Servers ####################################################

`foreman start` starts both the back-end server and the front-end server.

They can, alternatively, be started separately:

_Backend_
`REACT_ON_RAILS_ENV=HOT bundle exec rails s -p 3000`

_Frontend_
`cd client && yarn run dev:hot`

### Seeding Data

Seeding VACOLS:

`bundle exec rake local:vacols:seed`

Seeding Caseflow:

`bundle exec rake db:seed`

Resetting Caseflow:

`bundle exec rake db:reset`

### Connecting to databases locally

There are two databases you'll use: the postgres db aka Caseflow's db, and the Oracle db representing VACOLS (FACOLS).

#### Postgres Caseflow DB
Rails provides a useful way to connect to the default database called `dbconsole`:

```sh
bundle exec rails dbconsole # password is `postgres`
```

You can also use Psequel (instead of SQL Developer) with the following setup (user and password is postgres):

<img width="1659" alt="Screenshot 2019-02-11 12 19 42" src="https://user-images.githubusercontent.com/46791771/57386802-1fd1ac00-7183-11e9-8333-63249df033d2.png">

#### FACOLS

To connect to FACOLS, we recommend using SQL Plus Instant Client or [SQL Developer](https://www.oracle.com/database/technologies/appdev/sql-developer.html). Connection details can be found in the docker-compose.yml file.

To install SQL Plus Instant Client on a Mac, run the following Homebrew install commands:

```sh
brew tap InstantClientTap/instantclient
brew install instantclient-sqlplus
```

Homebrew will error and give you instructions to complete a successful installation.

Once SQL Plus is installed, you can connect to FACOLS with this command:

```sh
sqlplus "VACOLS_DEV/VACOLS_DEV@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SID=BVAP)))"
```

Alternately, you can run SQL commands on FACOLS via the rails console using this syntax:

```ruby
VACOLS::Case.connection.exec_query("SELECT hearing_pkseq from HEARSCHED").to_hash
```

### Debugging Tools
[RailsPanel](https://github.com/dejan/rails_panel) is a great Chrome extension
that makes debugging easier. It depends on the `meta_request` gem, which is
already included in this repo.


## Running tests

To run the test suite:

```
% make test
```

### Testing frontend changes in feature specs

Making frontend changes requires Webpack to compile the assets in order for the
spec to pick up the changes. To automatically compile assets after every change,
you can turn on Webpack's [Hot Module Replacement](https://webpack.js.org/concepts/hot-module-replacement/)
by setting the env var `REACT_ON_RAILS_ENV` to `HOT` in your Terminal session.

For example:
```console
export REACT_ON_RAILS_ENV=HOT
bundle exec rspec spec/feature/queue/case_details_spec.rb:350
```
or
```console
REACT_ON_RAILS_ENV=HOT bundle exec rspec spec/feature/queue/case_details_spec.rb:350
```

For less typing, create an alias in your shell profile (such as `.bash_profile`):
```
alias ber='REACT_ON_RAILS_ENV=HOT bundle exec rspec'
```
To run a specific test with this alias:
```console
ber spec/feature/queue/case_details_spec.rb:350
```

The webpack server also needs to be running while you are testing. Run this
command in a separate Terminal pane:
```
cd client && yarn run dev:hot
```

### Debugging tests in the browser

By default, tests will run by launching an instance of Chrome for easier
debugging. If you prefer to run the tests using a headless driver, set the `CI`
env var to `true`. For example:
```console
CI=true bundle exec rspec spec/feature/queue/case_details_spec.rb:350
```

### focus

During development, it can be helpful to narrow the scope of tests being run. You can do this by
adding [`focus: true`](https://relishapp.com/rspec/rspec-core/v/2-6/docs/filtering/inclusion-filters) to a `context` or `it` like so:

```diff
-context "test my new feature" do
+context "test my new feature", focus: true do
```

### Guard

In addition, if you are iterating on a subset of tests, [`guard`](https://github.com/guard/guard-rspec) is a useful tool that will
automatically rerun some command when a watched set of files change - you can do this by
running `bundle exec guard`, then editing a file (see Guardfile for details). In conjunction with
the `focus` flag, you can get a short development loop.

### Test coverage

We use the [simplecov](https://github.com/colszowka/simplecov) gem to evaluate test coverage as part of the CircleCI process.

If you see a test coverage failure at CircleCI, you can evaluate test coverage locally for the affected files using
the [single_cov](https://github.com/grosser/single_cov) gem.

Add the line to any rspec file locally:

```
SingleCov.covered!
```

and run that file under rspec.

```
SINGLE_COV=true bundle exec rspec spec/path/to/file_spec.rb
```

Missing test coverage will be reported automatically at the end of the test run.

## Debugging FACOLS setup
See debugging steps as well as more information about FACOLS in our [wiki](https://github.com/department-of-veterans-affairs/caseflow/wiki/FACOLS#debugging-facols) or join the DSVA slack channel #appeals-facols-issues.

Review the [FACOLS documentation](docs/FACOLS.md) for details.

## Monitoring
We use NewRelic to monitor the app. By default, it's disabled locally. To enable it, do:

```
NEW_RELIC_LICENSE_KEY='<key as displayed on NewRelic.com>' NEW_RELIC_AGENT_ENABLED=true bundle exec foreman start
```

You may wish to do this if you are debugging our NewRelic integration, for instance.

## Roles

When a VA employee logs in through the VA's unified login system (CSS) a session begins with the user.
Within this session the user gets a set of roles. These roles determine what pages a user has access to.
In dev mode, we don't log in with CSS and instead take on the [identity of a user in the database](#changing-between-test-users).

## Running Caseflow connected to external depedencies
To test the app connected to external dependencies, you'll need to set up Oracle, decrypt the environment variables, install staging gems, and run the app.

### Environment variables

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

## Dev Caseflow Usage Tweaks
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

## Documentation
We have a lot of technical documentation spread over a lot of different repositories. Here is a non-exhaustive mapping of where to find documentation:

- [Local Caseflow Setup](https://github.com/department-of-veterans-affairs/caseflow/tree/master/docs)
- [Test data setup in lower environments](https://github.com/department-of-veterans-affairs/appeals-qa/tree/master/docs)
- [Caseflow specific devops documentation](https://github.com/department-of-veterans-affairs/appeals-deployment/tree/master/docs) This folder also contains our [first responder manual](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/first-responder-manual.md), which is super in understanding our production systems.
- [Non-Caseflow specific devops documentation](https://github.com/department-of-veterans-affairs/devops/tree/master/docs). This documentation is shared with the vets.gov team, so not all of it is relevant.
- [Project documentation](https://github.com/department-of-veterans-affairs/appeals-design-research/tree/master/Project%20Folders)
