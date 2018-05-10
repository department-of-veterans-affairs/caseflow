#! /bin/sh

eval $(aws ecr get-login --no-include-email --region us-gov-west-1)

docker build -t facols .
docker tag facols:latest 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols:latest
if docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/facols:latest ; then
  echo 'Success the latest docker image has been pushed.'
else
  echo 'Failed. You likely need to sign in with MFA https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/'
fi
