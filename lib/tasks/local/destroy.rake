# frozen_string_literal: true

namespace :local do
  desc "destroy local development environment to have a clean slate when rebuilding"
  task :destroy do
    puts ">>> BEGIN local:destroy"

    puts ">>> 01/02 Dropping development and test caseflow databases"
    system("RAILS_ENV=development bundle exec rake db:drop") || abort

    puts ">>> 02/02 Tearing down docker volumes"
    # Note: In some cases, there may be dangling images or volumes that
    #       can interfere with setup. One may want to try `docker volume prune`
    #       and `docker image prune`, but be aware that it may remove
    #       non-Caseflow Docker volumes/images.
    system("docker-compose down -v --remove-orphans --rmi all") || abort

    puts ">>> END local:destroy"
  end
end
