#! /bin/sh

if [ ! -d instantclient_12_1 ]; then
  aws s3 cp s3://shared-s3/dsva-appeals/instant-client-12-1.tar.gz instant-client-12-1.tar.gz
  tar xvzf instant-client-12-1.tar.gz
fi

rm instant-client-12-1.tar.gz

aws ecr get-login-password --region us-gov-west-1 | docker login --username AWS --password-stdin 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com

docker build -t circleci .
# In case we modify this image and keep the same ruby version, we should use a different tag (i.e. image digest)
docker tag circleci:latest 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/circleci:2.5.3-node-browsers
if docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/circleci:2.5.3-node-browsers ; then
  echo 'Success the latest docker image has been pushed.'
else
  echo 'Failed. You likely need to sign in with MFA https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/'
fi
