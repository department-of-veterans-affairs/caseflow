# Caseflow
[![CircleCI](https://circleci.com/gh/department-of-veterans-affairs/caseflow.svg?style=svg)](https://circleci.com/gh/department-of-veterans-affairs/caseflow)

Caseflow is a suite of web-based tools to manage VA appeals. It's currently in development by the Appeals Modernization team (est. 2016). It will replace the current system of record for appeals, the Veterans Appeals Control and Location System (VACOLS), which was created in 1979 on now-outdated infrastructure. Additionally, Caseflow will allow the Board of Veterans' Appeals to process appeals under the new guidelines created by the Veterans Appeals Improvement and Modernization Act of 2017, which goes into effect February 14th, 2019.

The Appeals Modernization team's mission is to empower employees with technology to increase timely, accurate appeals decisions and improve the Veteran experience. Most of the team's products live here, in the main Caseflow repository.

## Caseflow products in heavy development

### Intake

Tracking Appeals Modernization Act reviews in a single system.

### Queue

Workflow management at the Board of Veterans' Appeals.

### Reader

Increases the speed with which attorneys and Veterans Law Judges (VLJs)
review and annotate electronic case files.

### Hearing Schedule

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
| Product | GitHub Repository | CI |
| --- | --- | ---|
| Caseflow | [caseflow](https://github.com/department-of-veterans-affairs/caseflow) | [CircleCI - Caseflow](https://circleci.com/gh/department-of-veterans-affairs/caseflow) |
| eFolder Express | [caseflow-efolder](https://github.com/department-of-veterans-affairs/caseflow-efolder) | [Travis CI - eFolder](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder) |
| Caseflow Feedback | [caseflow-feedback](https://github.com/department-of-veterans-affairs/caseflow-feedback) | [Travis CI - Caseflow Feedback](https://travis-ci.org/department-of-veterans-affairs/caseflow-feedback) |
| Commons | [caseflow-commons](https://github.com/department-of-veterans-affairs/caseflow-commons) | [Travis CI - Commons](https://travis-ci.org/department-of-veterans-affairs/caseflow-commons) |

## Developer Setup

### Install the Xcode commandline tools

    xcode-select --install

### Install base dependencies

Install the base dependencies via Homebrew:

    brew install rbenv nodenv yarn
    brew tap ouchxp/nodenv
    brew install nodenv-nvmrc
    brew tap caskroom/cask
    brew cask install chromedriver

### Setup [rbenv](https://github.com/rbenv/rbenv).

Run `rbenv init` and do what it tells you.

### Setup [nodenv](https://github.com/nodenv/nodenv).

Run `nodenv init` and do what it tells you.

Once you've done that, close your terminal window and open a new one. Verify that both environment managers are running:

    $ env | grep ENV_SHELL
    NODENV_SHELL=bash
    RBENV_SHELL=bash

If you don't see both, stop and debug.

### Git 2-factor authentication

We are using 2-factor authentication with Github so, for example, when you access a repository using Git on the command line using commands like `git clone`, `git fetch`, `git pull` or `git push` with HTTPS URLs, you must provide your GitHub username and your personal access token when prompted for a username and password. Follow directions [here](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) on how to do that.

### Install [PDFtk Server](https://www.pdflabs.com/tools/pdftk-server/)

Unfortunately, the link on the website points to a version for older macOS that doesn't work on current versions. Use this link found on a Stack Overflow post instead:

[PDFtk Server for modern macOS](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-2.02-mac_osx-10.11-setup.pkg)

### Install Docker

Install Docker on your machine via Homebrew:

```
    brew cask install docker
```

Once Docker's installed, run the application and go into advanced preferences to limit Docker's resources in order to keep FACOLS from consuming your Macbook.  Recommended settings are 4 CPUs, 8 GiB of internal memory, and 512 MiB of swap.

Back in the terminal, run:
```
docker login -u dsvaappeals
```

The password is in the DSVA 1Password account. Note you can use your personal account as well, you'll just have to accept the license agreement for the [Oracle Database docker image](https://store.docker.com/images/oracle-database-enterprise-edition). To accept the agreement, checkout with the Oracle image on the docker store.

### Install the Oracle client libraries

You'll need to install the libraries required to connect to the VACOLS Oracle database.

#### macOS

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

#### Windows
1) Download the ["Instant Client Package - Basic" and "Instant Client Package - SDK"](https://www.oracle.com/technetwork/database/database-technologies/instant-client/downloads/index.html) for Windows 32 or 64bit.

2) Unzip both packages into `[DIR]`

3) Add `[DIR]` to your `PATH`

#### Linux
Note: This has only been tested on Debian based OS. However, it should also work
for Fedora based OS.

 1. Download the ["Instant Client Package - Basic" and "Instant Client Package - SDK"](https://www.oracle.com/technetwork/database/database-technologies/instant-client/downloads/index.html) for Linux 32 or 64bit (depending on your Ruby architecture)

 1. Unzip both packages into `/opt/oracle/instantclient_11_2`

 1. Setup both packages according to the Oracle documentation:

```sh
export LD_LIBRARY_PATH=/opt/oracle/instantclient_11_2 <-- Not sure if this is still valid. It has recently changed for MAC. See above.
cd /opt/oracle/instantclient_11_2
sudo ln -s libclntsh.so.12.1 libclntsh.so
```

### Clone this repo
Navigate to the directory you'd like to clone this repo into and run:

    git clone https://github.com/department-of-veterans-affairs/caseflow.git

### Install Ruby dependencies

    cd caseflow
    rbenv install $(cat .ruby-version)
    rbenv rehash
    gem install bundler

*NOTE* If when running `gem install bundler` above you get a permissions error, this means you have not propertly configured your rbenv. Debug. Do not proceed by running `sudo gem install bundler`.

    bundle install

This should install clean. If you have errors, you probably missed a dependency (like the Oracle libraries).

### Install JavaScript dependencies

    cd caseflow
    nodenv install $(cat .nvmrc)
    nodenv rehash
    cd client
    yarn install

This should install clean. If you have errors, try ... FIXME.

### Setup the development Postgres user

Add these to your `.bash_profile`:

```
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export NLS_LANG=AMERICAN_AMERICA.US7ASCII
```

The last env var silences one of the Oracle warnings on startup.

(Reload the file `source ~/.bash_profile`)

### Cleanup the old dev environment (not needed for new Macbooks)

If you were doing Caseflow development before Docker, you need to turn off the brew managed Postgres and Redis services before starting to use the Docker services:
```
brew services stop postgresql
brew services stop redis
```

## Start your dev environment

We use [docker](https://docs.docker.com/) and [docker-compose](https://docs.docker.com/compose/) to mock a production environment locally.  Prior knowledge of docker is not required and slowly learning how docker works is encouraged. Please ask a team member for an overview, and/or slowly review the docs linked.

Your development setup of caseflow runs Redis, Postgres and OracleDB (VACOLS) in Docker.

### Database environment setup

To rapidly set up your local development (and testing) environment, you can run:
```
bundle exec rake local:build
```

The above shortcut runs a set of commands in sequence that should build your local environment. If you need to troubleshoot the process, you can copy each individual step out of the task and run them independently.

### Connecting to databases locally

There are two databases you'll use: the postgres db aka Caseflow's db, and the Oracle db representing VACOLS (FACOLS).

Rails provides a useful way to connect to the default database called `dbconsole`:

```sh
bundle exec rails dbconsole # password is `postgres`
```

To connect to FACOLS, we recommend using [SQL Developer](https://www.oracle.com/database/technologies/appdev/sql-developer.html). Connection details can be found in the docker-compose.yml file.

### Debugging FACOLS setup
FACOLS (short for fake-VACOLS) is our name for the Oracle DB with mock VACOLS data that we run locally. Sometimes the above setup fails at FACOLS steps, or the app cannot connect to the FACOLS DB. Here are some frequently encountered scenarios.

1) Running `rake local:vacols:setup` logs out:
```
[36mVACOLS_DB-development     |[0m tail: cannot open '/u01/app/oracle/diag/rdbms/bvap/BVAP/trace/alert_BVAP.log' for reading: No such file or directory
[36mVACOLS_DB-development     |[0m tail: no files remaining
[36mVACOLS_DB-development exited with code 1
```
Try running `docker-compose down --rmi all -v --remove-orphans` and then running the setup again.

2) The app is failing to connect to the DB and you get timeout errors. Try restarting your docker containers. `docker-compose restart`.

If all else fails you can rebuild your local development environment by running the two rake tasks in sequence:
```
bundle exec rake local:destroy
bundle exec rake local:build
```

More detailed errors and resolutions are located in the [Oracle Debugging readme](docs/oracle-debugging.md).

### Manually seeding your local VACOLS container
To seed the VACOLS container with data you'll need to generate the data for the CSVs first.

1) `bundle install --with staging` to get the necessary gems to connect to an Oracle DB
2) `rake local:vacols:seed` to load the data from the CSV files into your local VACOLS
3) `rails s` to start the server connected to local VACOLS or `rails c` to start the rails console connected to local VACOLS.

### Certification Test Scenarios

| BFKEY/VACOLS_ID | Case |
| ----- | ---------------- |
| 2367429 | Ready to certify with all dates matching |
| 2774535 | Ready to certify with fuzzy-matched dates |
| 2771149 | Mismatched documents |
| 3242524 | Already certified |

Review the [FACOLS documentation](docs/FACOLS.md) for information on adding new data.

## Monitoring
We use NewRelic to monitor the app. By default, it's disabled locally. To enable it, do:

```
NEW_RELIC_LICENSE_KEY='<key as displayed on NewRelic.com>' NEW_RELIC_AGENT_ENABLED=true bundle exec foreman start
```

You may wish to do this if you are debugging our NewRelic integration, for instance.

## Running Caseflow in isolation

To try Caseflow without going through the hastle of connecting to VBMS and VACOLS, just tell bundler
to skip production gems when installing.

    bundle install --without production staging
    rbenv rehash

Set up and seed the DB

    bundle exec rake db:setup

And by default, Rails will run in the development environment, which will mock out data. For an improved development experience with faster iteration, the application by default runs in "hot mode". This will cause Javascript changes to immediately show up on the page on save, without having to reload the page. You can start the application via:

    foreman start

If you want to run the Rails server and frontend webpack server separately, look at the `Procfile` to figure out what commands to run.

You can access the site at [http://localhost:3000/test/users](http://localhost:3000/test/users).

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

## Changing between test users
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

To use intake features as the users, you'll need to toggle two features in a
rails console `rails c`:

```
[1] FeatureToggle.enable!(:intakeAma)
=> true
[2] FeatureToggle.enable!(:intake)
=> true
```

This page also contains links to different parts of the site to make dev-ing faster. Please
add more links and users as needed.

## Running tests

To run the test suite:

    bundle exec rake

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

## Feature Toggle and Functions

See [Caseflow Commons](https://github.com/department-of-veterans-affairs/caseflow-commons)

## Out of Service

To enable and disable 'Out of Service' feature using `rails c`. Example usage:

```
# enable globally
Rails.cache.write("out_of_service", true)

# enable for certification only
Rails.cache.write("certification_out_of_service", true)

# enable for dispatch only
Rails.cache.write("dispatch_out_of_service", true)

# enable for hearing prep only
Rails.cache.write("hearing_prep_out_of_service", true)

# enable for hearing schedule only
Rails.cache.write("hearing_schedule_out_of_service", true)

# enable for reader only
Rails.cache.write("reader_out_of_service", true)

# to disable, e.g.
Rails.cache.write("certification_out_of_service", false)
```

## Degraded Service
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
- [Project documentation](https://github.com/department-of-veterans-affairs/appeals-design-research/tree/master/Projects)
