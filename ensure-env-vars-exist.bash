#! /bin/bash

VARS=(AWS_ACCESS_KEY_ID AWS_DEFAULT_REGION AWS_SECRET_ACCESS_KEY)

for i in "${VARS[@]}"
do
  if [ -z ${!i} ]; then
    echo "The following required env var is not defined: '$i'."
    echo "This can happen if you are sending a pull request from a branch on a fork, rather than the origin."
    echo "All pull requests must be sent from the origin."
    exit 1
  fi
done

