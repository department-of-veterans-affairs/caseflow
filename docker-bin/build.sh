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
  aws s3 cp --region us-gov-west-1 s3://vaec-nonprod-shared-s3/vaec-appeals/instantclient-basic-linux.x64-12.2.0.1.0.zip instantclient-basic-linux.x64-12.2.0.1.0.zip
  aws s3 cp --region us-gov-west-1 s3://vaec-nonprod-shared-s3/vaec-appeals/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
  aws s3 cp --region us-gov-west-1 s3://vaec-nonprod-shared-s3/vaec-appeals/instantclient-sdk-linux.x64-12.2.0.1.0.zip instantclient-sdk-linux.x64-12.2.0.1.0.zip

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

cp /etc/ssl/certs/ca-certificates.crt docker-bin/ca-certs/cacert.pem

# Build Docker
echo -e "\tCreating Caseflow App Docker Image"
echo "Using token1: ${GIT_CREDENTIAL}"
echo "Using token2: ${env.GIT_CREDENTIAL}"
docker build --build-arg PRIVATE_ACCESS_TOKEN="${GIT_CREDENTIAL}" -t caseflow .
result=$?
echo -e "\tCleaning Up..."
rm -rf docker-bin/oracle_libs
if [ $result == 0 ]; then
  echo -e "\tBuilding Caseflow Docker App: Completed"
else
  echo -e "\tBuilding Caseflow failed"
fi
exit $result
