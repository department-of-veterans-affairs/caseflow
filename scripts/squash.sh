#!/usr/bin/env bash

git ls-files db/migrate/*.rb | sort | tail -1 | \
  ruby -e "schema_version=STDIN.read[/[\d_]+/]; init_schema=%(db/migrate/#{schema_version}_init_schema.rb);
  %x(git rm -f db/migrate/*.rb;
  mkdir db/migrate;
  git mv db/schema.rb #{init_schema};
  bundle exec rake db:migrate:primary;
  git add db/schema.rb; git commit -m 'Squashed migrations')"
