#! /bin/sh

eval $(aws ecr get-login --no-include-email --region us-gov-west-1)

docker build -t facols2 .
docker tag facols2:latest 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols2:version1
if docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols2:version1 ; then
  echo 'Success the latest docker image has been pushed.'
else
  echo 'Failed. You likely need to sign in with MFA https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/'
fi
