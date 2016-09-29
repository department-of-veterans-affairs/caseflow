# Caseflow Certification

[![Build Status](https://travis-ci.org/department-of-veterans-affairs/caseflow-certification.svg?branch=master)](https://travis-ci.org/department-of-veterans-affairs/caseflow-certification)

## About

Clerical errors have the potential to delay the resolution of a veteran's appeal by **months**. Caseflow Certification uses automated error checking, and user-centered design to greatly reduce the number of clerical errors made when certifying appeals from offices around the nation to the Board of Veteran's Appeals in Washington DC.

[You can read more about the project here](https://medium.com/the-u-s-digital-service/new-tool-launches-to-improve-the-benefits-claim-appeals-process-at-the-va-59c2557a4a1c#.t1qhhz7h8).

![Screenshot of Caseflow Certification (Fake data, No PII here)](certification-screenshot.png "Caseflow Certification")

## Running Caseflow in isolation
To try Caseflow without going through the hastle of connecting to VBMS and VACOLS, just tell bundler
to skip production gems when installing.

`$ bundle install --without production staging`

And by default, Rails will run in the development environment, which will mock out data.

`$ rails s`

## Running Caseflow connected to external depedencies
To test the app connected to external dependencies follow

### Set up Oracle
First you'll need to install the libraries required to connect to the VACOLS Oracle database:

#### OSX
1) Download the ["Instant Client Package - Basic" and "Instant Client Package - SDK"](http://www.oracle.com/technetwork/database/features/instant-client/index.html) for Mac 32 or 64bit.

2) Unzip both packages into `/opt/oracle/instantclient_11_2`

3) Setup both packages according to the Oracle documentation:
```
export DYLD_LIBRARY_PATH=/opt/oracle/instantclient_11_2`
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
export LD_LIBRARY_PATH=/opt/oracle/instantclient_11_2`
cd /opt/oracle/instantclient_11_2
sudo ln -s libclntsh.so.12.1 libclntsh.so
```

### Run the app
Now you'll be able to install the gems required to run the app connected to VBMS and VACOLS:
`$ bundle install --with staging`

Set the development VACOLS credentials as environment variables.  
(ask a team member for them)
```
export VACOLS_USERNAME=username
export VACOLS_PASSWORD=secret_password
```

Finally, just run Rails in the staging environment!
`$ rails s -e staging`
