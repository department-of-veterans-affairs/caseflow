# Caseflow

Following are links to view the results for each product in Travis CI as well as a link to the product's repository:

| Product | GitHub Repository | Travis CI |
| --- | --- | ---|
| Caseflow | [caseflow](https://github.com/department-of-veterans-affairs/caseflow) | [Travis CI - Caseflow](https://travis-ci.org/department-of-veterans-affairs/caseflow) |
| eFolder Express | [caseflow-efolder](https://github.com/department-of-veterans-affairs/caseflow-efolder) | [Travis CI - eFolder](https://travis-ci.org/department-of-veterans-affairs/caseflow-efolder) |
| Caseflow Feedback | [caseflow-feedback](https://github.com/department-of-veterans-affairs/caseflow-feedback) | [Travis CI - Caseflow Feedback](https://travis-ci.org/department-of-veterans-affairs/caseflow-feedback) |
| Commons | [caseflow-commons](https://github.com/department-of-veterans-affairs/caseflow-commons) | [Travis CI - Commons](https://travis-ci.org/department-of-veterans-affairs/caseflow-commons) |


# Caseflow Certification

[![Build Status](https://travis-ci.org/department-of-veterans-affairs/caseflow.svg?branch=master)](https://travis-ci.org/department-of-veterans-affairs/caseflow)

## About

Clerical errors have the potential to delay the resolution of a veteran's appeal by **months**. Caseflow Certification uses automated error checking, and user-centered design to greatly reduce the number of clerical errors made when certifying appeals from offices around the nation to the Board of Veteran's Appeals in Washington DC.

[You can read more about the project here](https://medium.com/the-u-s-digital-service/new-tool-launches-to-improve-the-benefits-claim-appeals-process-at-the-va-59c2557a4a1c#.t1qhhz7h8).

![Screenshot of Caseflow Certification (Fake data, No PII here)](certification-screenshot.png "Caseflow Certification")

[View information on Caseflow Certification](https://github.com/department-of-veterans-affairs/caseflow/blob/master/docs/certification.md).

## Setup
Make sure you have [rbenv](https://github.com/rbenv/rbenv) and [nvm](https://github.com/creationix/nvm) installed.

Then run the following:

    rbenv install 2.2.4

    gem install bundler

You'll need ChromeDriver, Postgres, and Redis if you don't have them.

    brew install postgresql

    brew install redis

    brew install chromedriver

You need to have Redis, Postgres, and Chromedriver running to run Caseflow. (Chromedriver is for the Capybara tests.) Let brew tell you how to do that:

    brew info redis

    brew info postgresql

    brew info chromedriver

Install [pdftk](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-2.02-mac_osx-10.11-setup.pkg)

Note this link was found on Stack Overflow and is not the same link that is on the pdftk website.
The version on the website does not work on recent versions of OSX (Sierra and El Capitan).

For the frontend, you'll need to install Node and the relevant npm modules

    nvm install v6.10.2

    cd client && nvm use && npm install

## Running Caseflow in isolation
To try Caseflow without going through the hastle of connecting to VBMS and VACOLS, just tell bundler
to skip production gems when installing.

    bundle install --without production staging

Setup and seed the DB

    rake db:setup

And by default, Rails will run in the development environment, which will mock out data. For an improved development experience with faster iteration, the application by default runs in "hot mode". This will cause Javascript changes to immediately show up on the page on save, without having to reload the page. You can start the application via:

    foreman start

Or to run the rails server and frontend webpack server separately:

    REACT_ON_RAILS_ENV=hot bundle exec rails s

    cd client && nvm use && npm run dev

You can access the site at [http://localhost:3000](http://localhost:3000), which takes you to the help page.

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
To test the app connected to external dependencies follow

### Set up Oracle
First you'll need to install the libraries required to connect to the VACOLS Oracle database:

#### OSX
1) Download the ["Instant Client Package - Basic" and "Instant Client Package - SDK"](http://www.oracle.com/technetwork/database/features/instant-client/index.html) for Mac 32 or 64bit.

2) Unzip both packages into `/opt/oracle/instantclient_11_2`

3) Setup both packages according to the Oracle documentation:
```
export OCI_DIR=/opt/oracle/instantclient_12_1
cd /opt/oracle/instantclient_11_2
sudo ln -s libclntsh.dylib.11.1 libclntsh.dylib
```

#### Windows
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

### Run the app
Now you'll be able to install the gems required to run the app connected to VBMS and VACOLS:
    bundle install --with staging

Set the development VACOLS credentials as environment variables.
(ask a team member for them)
```
export VACOLS_USERNAME=username
export VACOLS_PASSWORD=secret_password
```

Finally, just run Rails in the staging environment!
    rails s -e staging

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

# Support
![BrowserStack logo](./browserstack-logo.png)

Thanks to [BrowserStack](https://www.browserstack.com/) for providing free support to this open-source project.
