# Caseflow
[![Build Status](https://travis-ci.org/department-of-veterans-affairs/caseflow.svg?branch=master)](https://travis-ci.org/department-of-veterans-affairs/caseflow)

Clerical errors have the potential to delay the resolution of a veteran's appeal by **months**. Caseflow Certification uses automated error checking, and user-centered design to greatly reduce the number of clerical errors made when certifying appeals from offices around the nation to the Board of Veteran's Appeals in Washington DC.

[You can read more about the project here](https://medium.com/the-u-s-digital-service/new-tool-launches-to-improve-the-benefits-claim-appeals-process-at-the-va-59c2557a4a1c#.t1qhhz7h8).

![Screenshot of Caseflow Certification (Fake data, No PII here)](certification-screenshot.png "Caseflow Certification")

## Setup
Install dependencies via Homebrew:

    brew install chromedriver rbenv nvm yarn

Make sure you have installed and setup both [rbenv](https://github.com/rbenv/rbenv) and [nvm](https://github.com/creationix/nvm). For rbenv this means running `rbenv init`. For nvm this means doing the following:
- Run `mkdir ~/.nvm`
- Add the following to your shell login script:

        export NVM_DIR="$HOME/.nvm"
        . "/usr/local/opt/nvm/nvm.sh"

Before continuing, source your shell login script, e.g., `source ~/.profile` or `source ~/.bashrc`.

Then run the following:

    cd caseflow
    rbenv install $(cat .ruby-version)
    rbenv rehash
    gem install bundler

*NOTE* If when running `gem install bundler` above you get a permissions error, this means you have not propertly configured your rbenv. Do not proceed by running `sudo gem install bundler`.

You need to have Chromedriver running to run the Capybara tests. Let `brew` tell you how to do that:

    brew info chromedriver

Install [pdftk](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-2.02-mac_osx-10.11-setup.pkg)

Note this link was found on Stack Overflow and is not the same link that is on the pdftk website.
The version on the website does not work on recent versions of OSX (Sierra and El Capitan).

For the frontend, you'll need to install Node and the relevant npm modules. [Install yarn](https://yarnpkg.com/en/docs/install). Use the version of Yarn defined in our `.travis.yml` file.

    # Use the version of Node defined in .nvmrc.
    nvm use

    cd client && yarn


## Set up Docker
Install [Docker](https://docs.docker.com/docker-for-mac/install/) on your machine. After installation is complete, run:
```
docker login -u dsvaappeals
```

The password is in the DSVA 1Password account. Note you can use your personal account as well, you'll just have to
accept the license agreement for [this docker image](https://store.docker.com/images/oracle-database-enterprise-edition).

## Set up Oracle
You'll need to install the libraries required to connect to the VACOLS Oracle database:

### OSX
1) Download the ["Instant Client Package - Basic" and "Instant Client Package - SDK"](http://www.oracle.com/technetwork/database/features/instant-client/index.html) for Mac 32 or 64bit.

2) Unzip both packages into `/opt/oracle/instantclient_<version_number>` where `<version_number>` is consistent with step 3. Most of us are using `<version_number>=12_2`.

3) Setup both packages according to the Oracle documentation:
```
export OCI_DIR=/opt/oracle/instantclient_<version_number>
cd /opt/oracle/instantclient_<version_number>
sudo ln -s libclntsh.dylib.<version_number> libclntsh.dylib
```

If you prefer to use Homebrew, see the documentation on the [appeals-data](https://github.com/department-of-veterans-affairs/appeals-data#installing-roracle) repo.

### Windows
1) Download the ["Instant Client Package - Basic" and "Instant Client Package - SDK"](http://www.oracle.com/technetwork/database/features/instant-client/index.html) for Mac 32 or 64bit.

2) Unzip both packages into `[DIR]`

3) Add `[DIR]` to your `PATH`

### Linux
Note: This has only been tested on Debian based OS. However, it should also work
for Fedora based OS.

 1. Download the ["Instant Client Package - Basic" and "Instant Client Package - SDK"](http://www.oracle.com/technetwork/database/features/instant-client/index.html) for Linux 32 or 64bit (depending on your Ruby architecture)

 1. Unzip both packages into `/opt/oracle/instantclient_11_2`

 1. Setup both packages according to the Oracle documentation:

```sh
export LD_LIBRARY_PATH=/opt/oracle/instantclient_11_2 <-- Not sure if this is still valid. It has recently changed for MAC. See above.
cd /opt/oracle/instantclient_11_2
sudo ln -s libclntsh.so.12.1 libclntsh.so
```

## Start up your docker based environment

We use [docker](https://docs.docker.com/) and [docker-compose](https://docs.docker.com/compose/) to mock a production environment locally.  Prior knowledge of docker is not required, but slowly learning how docker works is encouraged.
Please ask a team member for an overview, and/or slowly review the docs linked.

Your development setup of caseflow currently runs Redis, postgres and OracleDB (VACOLS) in Docker.

Setup your postgres user.  Run this in your CLI, or better yet, add this to your shell configuration `~/.bashrc`

```
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
```

**Note: If you previously have had redis and postgres installed via brew and would like to switch to docker, do the following:**
```
brew services stop postgresql
brew services stop redis
```

Start all containers
```
docker-compose up -d
# run without -d to start your environment and view container logging in the foreground

docker-compose ps
# this shows you the status of all of your dependencies
```

Turning off dependencies
```
# this stops all containers
docker-compose down

# this will reset your setup back to scratch. You will need to setup your database schema again if you do this (see below)
docker-compose down -v
```

## Setup your Database Schema
```
rake [RAILS_ENV=<test|development|stubbed>] db:setup
rake [RAILS_ENV=<test|development|stubbed>] db:seed

# setup local VACOLS (FAKOLS)
rake [RAILS_ENV=<test|development|stubbed>] local:vacols:setup
rake [RAILS_ENV=<test|development|stubbed>] local:vacols:seed
```

## Manually seeding your local VACOLS container
To seed the VACOLS container with data you'll need to generate the data for the CSVs first.

1) `bundle install --with staging` to get the necessary gems to connect to an Oracle DB
2) `rake local:vacols:seed` to load the data from the CSV files into your local VACOLS
3) `rails s` to start the server connected to local VACOLS or `rails c` to start the rails console connected to local VACOLS.

## Certification Test Scenarios

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

    rake db:setup

And by default, Rails will run in the development environment, which will mock out data. For an improved development experience with faster iteration, the application by default runs in "hot mode". This will cause Javascript changes to immediately show up on the page on save, without having to reload the page. You can start the application via:

    foreman start

If you want to run the Rails server and frontend webpack server separately, look at the `Procfile` to figure out what commands to run.

You can access the site at [http://localhost:3000/test/users](http://localhost:3000/test/users).

## Roles

When a VA employee logs in through the VA's unified login system (CSS) a session begins with the user.
Within this session the user gets a set of roles. These roles determine what pages a user has access to.
In dev mode, we don't log in with CSS and instead take on the [identity of a user in the database](#changing-between-test-users).

## Dispatch (Dev Mode)
To view the dispatch pages head to [http://localhost:3000/dispatch](http://localhost:3000/dispatch).

To see the manager view, you need the following roles: [Establish Claim, Manage Claim Establishment].
The database is seeded with a number of tasks, users, and appeals.

To see the worker view, you need the following role: [Establish Claim].
From this view you can start a new task and go through the flow of establishing a claim.

## Running Caseflow connected to external depedencies
To test the app connected to external dependencies, you'll need to set up Oracle, decrypt the environment variables, install staging gems, and run the app.

### Environment variables

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
rails s -e staging
```

## Changing between test users
Select 'Switch User' from the dropdown or navigate to
[http://localhost:3000/dev/users](http://localhost:3000/test/users). You can use
this page to switch to any user that is currently in the database. The users' names specify
what roles they have and therefore what pages they can access. To add new users with new
roles, you should seed them in the database via the seeds.rb file. The css_id of the user
should be a comma separated list of roles you want that user to have.

This page also contains links to different parts of the site to make dev-ing faster. Please
add more links and users as needed.

## Running tests

To run the test suite:

    rake

### Parallelized tests
You'll be able to get through the tests a lot faster if you put all your CPUs to work.
Parallel test categories are split up by category:
- `unit`: Any test that isn't a feature test, since these are :lightning: fast
- `other`: Any feature test that is not in a subfolder
- CATEGORY: The other feature tests are split by subfolders in `spec/feature/`. Examples are `certification` and `reader`

To set your environment up for parallel testing run:

    rake spec:parallel:setup

To run the test suite in parallel:

    rake spec:parallel

You can run any one of the parallel categories on its own via (where `CATEGORY` is `unit`, `certification`, etc):

    rake spec:parallel:CATEGORY

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

# enable for hearings only
Rails.cache.write("hearing_prep_out_of_service", true)

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

# Other Caseflow Products
| Product | GitHub Repository | Travis CI |
| --- | --- | ---|
| Caseflow | [caseflow](https://github.com/department-of-veterans-affairs/caseflow) | [Travis CI - Caseflow](https://travis-ci.org/department-of-veterans-affairs/caseflow) |
| eFolder Express | [caseflow-efolder](https://github.com/department-of-veterans-affairs/caseflow-efolder) | [Travis CI - eFolder](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder) |
| Caseflow Feedback | [caseflow-feedback](https://github.com/department-of-veterans-affairs/caseflow-feedback) | [Travis CI - Caseflow Feedback](https://travis-ci.org/department-of-veterans-affairs/caseflow-feedback) |
| Commons | [caseflow-commons](https://github.com/department-of-veterans-affairs/caseflow-commons) | [Travis CI - Commons](https://travis-ci.org/department-of-veterans-affairs/caseflow-commons) |

# Support
![BrowserStack logo](./browserstack-logo.png)

Thanks to [BrowserStack](https://www.browserstack.com/) for providing free support to this open-source project.
