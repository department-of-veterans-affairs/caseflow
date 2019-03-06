# frozen_string_literal: true

namespace :local do
  desc "destroy local development environment to have a clean slate when rebuilding"
  task :destroy do
    puts "Tearing down docker volumes"
    system("docker-compose down -v --remove-orphans --rmi all") || abort
    # In some cases, there may be dangling images or volumes that
    # can interfere with setup. One may want to try `docker volume prune`
    # and `docker image prune`, but be aware that it may remove
    # non-Caseflow Docker volumes/images.
  end
end
