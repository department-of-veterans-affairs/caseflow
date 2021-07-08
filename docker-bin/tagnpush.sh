#!/bin/bash
echo "Logging in to ECR"
aws ecr get-login-password --region us-gov-west-1 | docker login --username AWS --password-stdin 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com

tag_name="latest"

if [[ -n $1 ]]; then
  tag_name=$1
fi
echo "Tagging with date"
docker tag caseflow:latest 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/caseflow:$(date +%F)

echo "Tagging with $tag_name"
docker tag caseflow:latest 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/caseflow:$tag_name

echo "Pushing to ECR"
if docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/caseflow:$(date +%F); then
    echo "Success the latest docker image has been pushed."
else
    echo "Failed. You likely need to sign in with MFA"
    exit 1
fi
docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/caseflow:$tag_name

echo "Completed!"
