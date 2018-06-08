namespace :local do
  desc "destroy local development environment to have a clean slate when rebuilding"
  task :destroy do
    puts "Tearing down docker volumes"
    system("docker-compose down -v --remove-orphans --rmi all") or abort
  end
end
