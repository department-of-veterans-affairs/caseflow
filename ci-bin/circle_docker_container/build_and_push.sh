#! /bin/sh

if [ ! -d instantclient_12_1 ]; then
  aws s3 cp s3://shared-s3/dsva-appeals/instant-client-12-1.tar.gz instant-client-12-1.tar.gz
  tar xvzf instant-client-12-1.tar.gz
fi

rm instant-client-12-1.tar.gz

eval $(aws ecr get-login --no-include-email --region us-gov-west-1)

docker build -t circleci .
docker tag circleci:latest 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/circleci:latest
if docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/circleci:latest ; then
  echo 'Success the latest docker image has been pushed.'
else
  echo 'Failed. You likely need to sign in with MFA https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/'
fi
