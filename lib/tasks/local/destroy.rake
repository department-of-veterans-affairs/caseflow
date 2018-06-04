namespace :local do
  desc "destroy local development environment to have a clean slate when rebuilding"
  task :destroy do
    puts "Tearing down docker volumes"
    `docker-compose down --rmi all -v --remove-orphans`
  end
end
