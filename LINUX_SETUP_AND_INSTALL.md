# Developer Setup - Debian Systems

## Github

### Organization

Request an invite to the [department-of-veterans-affairs](https://github.com/department-of-veterans-affairs) organization  

### 2Factor

We are using 2-factor authentication with Github so, for example, when you access a repository using Git on the command line using commands like git clone, git fetch, git pull or git push with HTTPS URLs, you must provide your GitHub username and your personal access token when prompted for a username and password. Follow directions [here](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) on how to do that.


## Machine setup
### Install Language Managers

[Install rbenv](https://github.com/rbenv/rbenv-installer#rbenv-installer`)  
[Install nodenv](https://github.com/nodenv/nodenv-installer#nodenv-installer)  
[Install yarn](https://yarnpkg.com/lang/en/docs/install)  


Setup rbenv & nodenv

`rbenv init` #follow directions  
`nodenv init` #follow directions


### Install Databases

Install redis. (Maybe not required? Give it a shot without.)  
Configure to run on another port to avoid blocking the docker container.    

Install postgres client and developer libraries.  
The postgres server is not needed. If you install it, configure it to run on a different port or you will block the docker container.    
Add these postgres variables to your env:  
```
export POSTGRES_HOST=localhost
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
```

Install sqlite3 client and dev libs. This may be deprecated shortly.

[Install oracle](https://github.com/kubo/ruby-oci8/blob/master/docs/install-instant-client.md#install-oracle-instant-client-packages) (last known working at v12; follow _all the steps_ for the zip install. Requires instant-client, sdk, and sql\*plus packages. Don't skip the lib softlink)  
You probably have to create an Oracle account.  
Add this to your env to squash oracle errors on startup:  
`export NLS_LANG=AMERICAN_AMERICA.US7ASCII`  

May need to have your user own the oracle directory?

### Install Third Party Software

Install PDFtk Server. Available for Ubuntu in the software manager.  

Install docker-ce  
Login docker, password in 1Password:  
`docker login -u dsvaappeals`

Set docker to run without sudo.  


## Repo Setup

### Clone the repo

Navigate to the directory you'd like to clone this repo into and run:

`git clone https://github.com/department-of-veterans-affairs/caseflow.git`


### Ruby Dependencies

```
cd caseflow
rbenv install $(cat .ruby-version)
rbenv rehash
# NB: install the version of bundler used to bundled the Gemfile.lock
BUNDLED_WITH= #[Gemfile.lock bundled-with]
gem install bundler -v $BUNDLED_WITH
# If when running gem install bundler above you get a permissions error, this means you have not propertly configured your rbenv.
# Debug. 
# !! Do *not* proceed by running sudo gem install bundler. !!
bundle install
```

This should install clean. If you have errors, you probably missed a dependency (like the Oracle libraries).

### Javascript Dependencies

```
cd caseflow
nodenv install $(cat .nvmrc)
nodenv rehash
cd client
yarn install
```

### Repo Build

Rake task for rapidly setting up dev & test environment

_Not working on ubuntu as of this writing. See Alternative_

```
bundle exec rake local:build
```

_Alternative work around_
```
# "Building docker services from configuration"
docker-compose build --no-cache
# "Starting docker containers in the background"
docker-compose up -d vacols-db-development
docker ps # wait until health: starting becomes healthy
docker-compose up -d appeals-localstack-aws
docker-compose up -d appeals-postgres
docker-compose up -d appeals-redis
docker-compose up -d vacols-db-test
# "Creating local caseflow dbs"
bundle exec rake db:create db:schema:load
# "Setting up development FACOLS"
docker exec --tty -i VACOLS_DB-development bash -c \
  "source /home/oracle/.bashrc; sqlplus /nolog @/ORCL/setup_vacols.sql" 
# "Seeding FACOLS"
RAILS_ENV=development bundle exec rake local:vacols:seed
# "Setting up test FACOLS"
docker exec --tty -i VACOLS_DB-test bash -c \
  "source /home/oracle/.bashrc; sqlplus /nolog @/ORCL/setup_vacols.sql" 
# "Enabling feature flags"
bundle exec rails runner scripts/enable_features_dev.rb
# "Setting up local caseflow database"
RAILS_ENV=development bundle exec rake db:setup
```

# Running caseflow & Accessing DBs

## Running caseflow
To run both back and front end:

```
foreman start
```

Front end has a longer spin up time (~90s).  
To run them seperately for dev purposes:

**Backend**:  
`REACT_ON_RAILS_ENV=HOT bundle exec rails s -p 3000`

**Frontend**:  
`cd client && yarn run dev:hot`

## DB access

Caseflow database:  
`bundle exec rails dbconsole` # password is 'postgres'

FACOLs:  
Suggested access software is [SQL Developer](https://www.oracle.com/database/technologies/appdev/sql-developer.html)

## Docker image management

[DockStation](https://dockstation.io/) is useful for visibility into the docker containers.
