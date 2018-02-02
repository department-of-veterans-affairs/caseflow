#! /bin/bash

for f in /Users/teja/git/caseflow/tmp/capybara/*.html; do 
  echo "uploading $f to s3";
  aws s3 mv /home/travis/build/department-of-veterans-affairs/caseflow/tmp/capybara/$f s3://dsva-appeals-travis-builds/build-$TRAVIS_BUILD_NUMBER/$TEST_CATEGORY.$f
done