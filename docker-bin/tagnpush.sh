#!/bin/bash
echo "Tagging with Date"
docker tag caseflow:latest 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/caseflow:$(date +%F)

echo "Tagging with Latest"
docker tag caseflow:latest 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/caseflow:latest

echo "Logging in to ECR"
eval $(aws ecr get-login --no-include-email --region us-gov-west-1)

echo "Pushing to ECR"
if docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/caseflow:$(date +%F); then
    echo "Success the latest docker image has been pushed."
else    
    echo "Failed. You likely need to sign in with MFA"
    exit 1
fi

# If all went right, also push the tag
docker push 008577686731.dkr.ecr.us-gov-west-1.amazonaws.com/caseflow:latest

echo "Completed!"