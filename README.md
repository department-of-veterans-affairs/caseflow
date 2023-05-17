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
            * [Windows 10 + WSL](WINDOWS_10)
            * [Windows 11 + WSL](WINDOWS_11)
            * [Mac M1/M2](MAC_M1)
            * [Mac Intel](MAC_INTEL)
      * [Test Coverage](#test-coverage)
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


## Machine setup #######################################################

You can manually go through the following steps.
Alternatively, if you have a Mac, you can clone this repo and run the following scripts:

  - `git clone https://github.com/department-of-veterans-affairs/caseflow`
  - `git checkout grant/setup-m1`
  - [dev_env_setup_step1.sh](scripts/dev_env_setup_step1.sh)
  - [dev_env_setup_step2.sh](scripts/dev_env_setup_step2.sh)

If an error occurs, it is okay to run the scripts multiple times after the error is corrected.

---

## Test Coverage  #######################################################

We use the [simplecov](https://github.com/colszowka/simplecov) gem to evaluate test coverage as part of the CircleCI process.

If you see a test coverage failure at CircleCI, you can evaluate test coverage locally for the affected files using
the [single_cov](https://github.com/grosser/single_cov) gem.

Locally, add the below statement to the first line of any rspec file:

```
SingleCov.covered!
```

and run that file under rspec.

```
SINGLE_COV=true bundle exec rspec spec/path/to/file_spec.rb
```

Missing test coverage will be reported automatically at the end of the test run.

---

## Debugging FACOLS setup  #######################################################
See debugging steps as well as more information about FACOLS in our [wiki](https://github.com/department-of-veterans-affairs/caseflow/wiki/FACOLS#debugging-facols) or join the DSVA slack channel #appeals-facols-issues.

Review the [FACOLS documentation](docs/FACOLS.md) for details.

## Monitoring  #######################################################
We use NewRelic to monitor the app. By default, it's disabled locally. To enable it, do:

```
NEW_RELIC_LICENSE_KEY='<key as displayed on NewRelic.com>' NEW_RELIC_AGENT_ENABLED=true bundle exec foreman start
```

You may wish to do this if you are debugging our NewRelic integration, for instance.

---

## Roles  #######################################################

When a VA employee logs in through the VA's unified login system (CSS) a session begins with the user.
Within this session the user gets a set of roles. These roles determine what pages a user has access to.
In dev mode, we don't log in with CSS and instead take on the [identity of a user in the database](#changing-between-test-users).

## Running Caseflow connected to external depedencies
To test the app connected to external dependencies, you'll need to set up Oracle, decrypt the environment variables, install staging gems, and run the app.

## Environment variables  #######################################################

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

---

## Dev Caseflow Usage Tweaks  #######################################################
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

---

## Documentation  #######################################################

We have a lot of technical documentation spread over a lot of different repositories. Here is a non-exhaustive mapping of where to find documentation:

- [Local Caseflow Setup](https://github.com/department-of-veterans-affairs/caseflow/tree/master/docs)
- [Test data setup in lower environments](https://github.com/department-of-veterans-affairs/appeals-qa/tree/master/docs)
- [Caseflow specific devops documentation](https://github.com/department-of-veterans-affairs/appeals-deployment/tree/master/docs) This folder also contains our [first responder manual](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/first-responder-manual.md), which is super in understanding our production systems.
- [Non-Caseflow specific devops documentation](https://github.com/department-of-veterans-affairs/devops/tree/master/docs). This documentation is shared with the vets.gov team, so not all of it is relevant.
- [Project documentation](https://github.com/department-of-veterans-affairs/appeals-design-research/tree/master/Project%20Folders)
