#!/bin/bash
echo "Building Caseflow Docker App.."

# Create temp folders
if [ ! -d oracle_libs ]; then
  echo "\t Creating Oracle Libs folder"
  mkdir ./oracle_libs 
fi

echo "\t Going into the Oracle Libs folder"
cd ./oracle_libs

echo "\t Checking if Oracle Instant client files exist"
# if file doesnt exist download it (oracle libs)
if [ ! -f instantclient-basic-linux.x64-12.2.0.1.0.zip ]; then

  echo "\t\t Downloading Oracle Instant Client and SQLPlus"
  aws s3 cp --region us-gov-west-1  s3://shared-s3/dsva-appeals/instantclient-basic-linux.x64-12.2.0.1.0.zip instantclient-basic-linux.x64-12.2.0.1.0.zip

  aws s3 cp --region us-gov-west-1 s3://shared-s3/dsva-appeals/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip

  aws s3 cp --region us-gov-west-1
  s3://shared-s3/dsva-appeals/instantclient-sdk-linux.x64-12.2.0.1.0.zip instantclient-sdk-linux.x64-12.2.0.1.0.zip

fi

echo "\t Checking if Instant Client Folder has been unarchived"
if [ ! -d instantclient_12_2 ]; then
  echo "\t\t Unzipping Instant Client and SQLPlus"
  unzip instantclient-basic-linux.x64-12.2.0.1.0.zip
  unzip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
  unzip instantclient-sdk-linux.x64-12.2.0.1.0.zip
fi

echo "\t Creating Caseflow App Docker Image"
# Build Docker
cd ../../
docker build -t caseflow .

echo "\t Cleaning Up..."
rm -rf docker-bin/oracle_libs/

echo "\t Building Caseflow Docker App: Completed"
