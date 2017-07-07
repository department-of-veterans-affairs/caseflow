#!/bin/bash
bundle exec rake db:create
bundle exec rake db:schema:load

Xvfb :99 -screen 0 1024x768x16 &> xvfb.log &
export DISPLAY=:99
bundle exec rspec ./spec/feature/help_spec.rb
