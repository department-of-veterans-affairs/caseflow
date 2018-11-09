#!/bin/bash
echo "Building Caseflow Docker App.."

# Create temp folders
if [ ! -d oracle_libs ]; then
  echo "  Creating Oracle Libs folder"
  mkdir ./oracle_libs 
fi

echo "  Going into the Oracle Libs folder"
cd ./oracle_libs

echo "  Checking if Oracle Instant client files exist"
# if file doesnt exist download it (oracle libs)
if [ ! -f instantclient-basic-linux.x64-12.2.0.1.0.zip ]; then

  echo "    Downloading Oracle Instant Client and SQLPlus"
  aws s3 cp --region us-gov-west-1  s3://shared-s3/dsva-appeals/instantclient-basic-linux.x64-12.2.0.1.0.zip instantclient-basic-linux.x64-12.2.0.1.0.zip

  aws s3 cp --region us-gov-west-1 s3://shared-s3/dsva-appeals/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip

  aws s3 cp --region us-gov-west-1 s3://shared-s3/dsva-appeals/instantclient-sdk-linux.x64-12.2.0.1.0.zip instantclient-sdk-linux.x64-12.2.0.1.0.zip

fi

echo "  Checking if Instant Client has been downloaded"
if [ ! -f instantclient-basic-linux.x64-12.2.0.1.0.zip ] || [ ! -f instantclient-sqlplus-linux.x64-12.2.0.1.0.zip ] || [ ! -f instantclient-sdk-linux.x64-12.2.0.1.0.zip ]; then

  echo "    Error: Couldn't download the files. Exiting"
  exit 1

fi

echo "  Checking if Instant Client Folder has been unarchived"
if [ ! -d instantclient_12_2 ]; then
  echo "    Unzipping Instant Client and SQLPlus"
  unzip instantclient-basic-linux.x64-12.2.0.1.0.zip
  unzip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
  unzip instantclient-sdk-linux.x64-12.2.0.1.0.zip
fi

# Get Git Version to Health Check
cd ../../
printf "commit: `git rev-parse HEAD`\ndate: `git log -1 --format=%cd`" > config/build_version.yml

# Build Docker
echo "  Creating Caseflow App Docker Image"
docker build -t caseflow .

echo "  Cleaning Up..."
rm -rf docker-bin/oracle_libs/
echo "  Building Caseflow Docker App: Completed"