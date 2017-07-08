#!/bin/bash

bundle install --deployment --without development staging production
cd ./client && npm install --no-optional

bundle exec rake db:create
bundle exec rake db:schema:load

Xvfb :99 -screen 0 1024x768x16 &> xvfb.log &
export DISPLAY=:99
bundle exec rspec ./spec/feature/help_spec.rb
