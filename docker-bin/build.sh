#!/bin/bash
echo "Building Caseflow Docker App.."

# Create temp folders
if [ ! -d oracle_libs ]; then
  echo -e "\tCreating Oracle Libs folder"
  mkdir ./oracle_libs
fi

echo "  Going into the Oracle Libs folder"
cd ./oracle_libs

echo -e "\tChecking if Oracle Instant client files exist"
# if file doesnt exist download it (oracle libs)
if [ ! -f instantclient-basic-linux.x64-12.2.0.1.0.zip ]; then

  echo -e "\t\tDownloading Oracle Instant Client and SQLPlus"
  aws s3 cp --region us-gov-west-1  s3://shared-s3/dsva-appeals/instantclient-basic-linux.x64-12.2.0.1.0.zip instantclient-basic-linux.x64-12.2.0.1.0.zip
  aws s3 cp --region us-gov-west-1 s3://shared-s3/dsva-appeals/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
  aws s3 cp --region us-gov-west-1 s3://shared-s3/dsva-appeals/instantclient-sdk-linux.x64-12.2.0.1.0.zip instantclient-sdk-linux.x64-12.2.0.1.0.zip

fi

echo -e "\tChecking if Instant Client has been downloaded"
if [ ! -f instantclient-basic-linux.x64-12.2.0.1.0.zip ] || [ ! -f instantclient-sqlplus-linux.x64-12.2.0.1.0.zip ] || [ ! -f instantclient-sdk-linux.x64-12.2.0.1.0.zip ]; then

  echo -e "\t\tError: Couldn't download the files. Exiting"
  return 1

fi

echo -e "\tChecking if Instant Client Folder has been unarchived"
if [ ! -d instantclient_12_2 ]; then
  echo "    Unzipping Instant Client and SQLPlus"
  unzip instantclient-basic-linux.x64-12.2.0.1.0.zip
  unzip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
  unzip instantclient-sdk-linux.x64-12.2.0.1.0.zip
fi

# Get Git Version to Health Check
cd ../../
printf "commit: `git rev-parse HEAD`\ndate: `git log -1 --format=%cd`" > config/build_version.yml

credstash -t appeals-credstash get datadog.api.key > config/datadog.key

# Build Docker
echo -e "\tCreating Caseflow App Docker Image"
docker build -t caseflow . --no-cache

echo -e "\tCleaning Up..."
rm -rf config/datadog.key
rm -rf docker-bin/oracle_libs/
echo -e "\tBuilding Caseflow Docker App: Completed"
