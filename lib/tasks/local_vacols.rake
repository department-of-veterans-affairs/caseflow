namespace :local_vacols do
  desc "Starts and sets up a dockerized local VACOLS"
  task setup: :environment do
    Dir.chdir(Rails.root.join("vacols")) do
      puts "Removing existing volumes"
      `docker-compose down -v`
      puts "Starting database, and logging to #{Rails.root.join('tmp', 'vacols.log')}"
      `docker-compose up &> '../tmp/vacols.log' &`

      # Loop until setup is complete. At most 10 minutes
      puts "Waiting for the database to be ready"
      setup_complete = false
      600.times do
        if `grep -q 'Done ! The database is ready for use' ../tmp/vacols.log; echo $?` == "0\n"
          setup_complete = true
          break
        end
        sleep 1
      end

      if setup_complete
        puts "Updating schema"
        schema_complete = false
        120.times do
          output = `docker exec --tty -i VACOLS_DB bash -c \
          "source /home/oracle/.bashrc; sqlplus /nolog @/ORCL/setup_vacols.sql"`
          if !output.include?("SP2-0640: Not connected")
            schema_complete = true
            break
          end
          sleep 1
        end

        if schema_complete
          puts "Schema loaded"
        else
          puts "Schema load failed"
        end
      else
        puts "Failed to setup database"
      end
    end
  end

  desc "Starts up existing database"
  task start: :environment do
    Dir.chdir(Rails.root.join("vacols")) do
      `docker-compose up &> '../tmp/vacols.log' &`
    end
  end

  desc "Stops a running database"
  task stop: :environment do
    Dir.chdir(Rails.root.join("vacols")) do
      `docker-compose down`
    end
  end

  desc "Outputs logs from database"
  task logs: :environment do
    Dir.chdir(Rails.root.join("vacols")) do
      puts `cat '../tmp/vacols.log'`
    end
  end
end
