# frozen_string_literal: true

namespace :local do
  desc "destroy local development environment to have a clean slate when rebuilding"
  task :destroy do # rubocop:disable Rails/RakeEnvironment
    puts ">>> BEGIN local:destroy"

    puts ">>> 01/02 Dropping development and test caseflow databases"
    system("RAILS_ENV=development bundle exec rake db:drop:primary") || abort

    puts ">>> 02/02 Tearing down docker volumes"
    # Note: In some cases, there may be dangling images or volumes that
    #       can interfere with setup. One may want to try `docker volume prune`
    #       and `docker image prune`, but be aware that it may remove
    #       non-Caseflow Docker volumes/images.
    system("docker-compose down -v --remove-orphans --rmi all") || abort

    puts ">>> END local:destroy"
  end

  desc "Nuke docker environment (removes all process, containers, images and volumes)"
  task :nuke do # rubocop:disable Rails/RakeEnvironment
    puts ">>> BEGIN local:nuke"

    puts ">>> 01/05 Stopping all docker processes"
    processes = system("docker ps -aq")
    if processes != true
      system("docker stop #{processes}") || abort
    end

    puts ">>> 02/05 Removing all docker containers"
    containers = system("docker ps -aq")
    if containers != true
      system("docker rm -f #{containers}") || abort
    end

    puts ">>> 03/05 Removing all docker images"
    images = system("docker images -aq")
    if images != true
      system("docker rmi -f #{images}") || abort
    end

    puts ">>> 04/05 Removing all docker volumes"
    volumes = system("docker volume ls -q")
    if volumes != true
      system("docker volume rm -f #{volumes}") || abort
    end

    puts ">>> 05/05 Destroying environment"
    system("make destroy") || abort

    puts ">>> END local:nuke"
  end
end
