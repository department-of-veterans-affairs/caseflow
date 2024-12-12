# frozen_string_literal: true

# The original definition of the `db:seed` task calls `db:abort_if_pending_migrations`, which would attempt to create a
# `schema_migrations` table on ALL configured databases, even if a database is not set up for the current environment.
#
# This re-definiton of `db:seed` will instead call the DB-specific `db:abort_if_pending_migrations` task as a workaround
# and skip it for databases that are not set up for the given environment.

db_namespace = namespace :db do
  Rake::Task["db:seed"].clear if Rake::Task.task_defined?("db:seed")
  desc "Loads the seed data from db/seeds.rb"
  task seed: :load_config do
    db_namespace["abort_if_pending_migrations:primary"].invoke

    # skip for environments where ETL DB does not exist
    db_namespace["abort_if_pending_migrations:etl"].invoke unless %w(demo prodtest).include?(ENV["DEPLOY_ENV"])

    ActiveRecord::Base.establish_connection(ActiveRecord::Tasks::DatabaseTasks.env.to_sym)

    ActiveRecord::Tasks::DatabaseTasks.load_seed
  end
end

#-----------------------------------------------------------------------------------------------------------------------

# After transitioning to Rails-native multi-DB support, the behavior of some DB tasks changed such that they will now
# act on ALL configured databases for a given environment.
#
# To avoid accidents, we re-define these tasks here to no-op and output a helpful message to redirect developers toward
# using their new database-specific counterparts instead.

# rubocop:disable Rails/RakeEnvironment, Layout/HeredocIndentation, Style/SignalException, Rails/Blank
namespace :db do
  Rake::Task["db:create"].clear if Rake::Task.task_defined?("db:create")
  desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
  task :create do
    puts <<~HEREDOC

      db:create is prohibited.

      Prefer using the appropriate database-specific task below:

        db:create:primary  # Create primary database for current environment
        db:create:etl      # Create etl database for current environment
    HEREDOC
  end

  Rake::Task["db:drop"].clear if Rake::Task.task_defined?("db:drop")
  desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
  task :drop do
    puts <<~HEREDOC

      db:drop is prohibited.

      Prefer using the appropriate database-specific task below:

        db:drop:primary  # Drop primary database for current environment
        db:drop:etl      # Drop etl database for current environment
    HEREDOC
  end

  Rake::Task["db:migrate"].clear if Rake::Task.task_defined?("db:migrate")
  desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
  task :migrate do
    puts <<~HEREDOC

      db:migrate is prohibited.

      Prefer using the appropriate database-specific task below:

        db:migrate:primary  # Migrate primary database for current environment
        db:migrate:etl      # Migrate etl database for current environment
    HEREDOC
  end

  namespace :migrate do
    Rake::Task["db:migrate:down"].clear if Rake::Task.task_defined?("db:migrate:down")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :down do
      puts <<~HEREDOC

        db:migrate:down is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:migrate:down:primary  # Runs the "down" for a given migration VERSION on the primary database
          db:migrate:down:etl      # Runs the "down" for a given migration VERSION on the etl database
      HEREDOC
    end

    Rake::Task["db:migrate:redo"].clear if Rake::Task.task_defined?("db:migrate:redo")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :redo do
      puts <<~HEREDOC

        db:migrate:redo is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:migrate:redo:primary  # Rolls back primary database one migration and re-migrates up (options: STEP=x, VERSION=x)
          db:migrate:redo:etl      # Rolls back etl database one migration and re-migrates up (options: STEP=x, VERSION=x)
      HEREDOC
    end

    Rake::Task["db:migrate:status"].clear if Rake::Task.task_defined?("db:migrate:status")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :status do
      puts <<~HEREDOC

        db:migrate:status is prohibited.

        Prefer using the appropriate database-specific task below:

          db:migrate:status:primary  # Display status of migrations for primary database
          db:migrate:status:etl      # Display status of migrations for etl database
      HEREDOC
    end

    Rake::Task["db:migrate:up"].clear if Rake::Task.task_defined?("db:migrate:up")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :up do
      puts <<~HEREDOC

        db:migrate:up is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:migrate:up:primary  # Runs the "up" for a given migration VERSION on the primary database
          db:migrate:up:etl      # Runs the "up" for a given migration VERSION on the etl database
      HEREDOC
    end
  end

  Rake::Task["db:reset"].clear if Rake::Task.task_defined?("db:reset")
  desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
  task :reset do
    puts <<~HEREDOC

      db:reset is prohibited.

      Prefer using the appropriate database-specific task below:

        db:reset:primary  # Reset the primary database
        db:reset:etl      # Reset the etl database
    HEREDOC
  end

  Rake::Task["db:rollback"].clear if Rake::Task.task_defined?("db:rollback")
  desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
  task :rollback do
    puts <<~HEREDOC

      db:rollback is prohibited.

      Prefer using the appropriate database-specific task below:

        db:rollback:primary  # Rollback primary database for current environment (specify steps w/ STEP=n)
        db:rollback:etl      # Rollback etl database for current environment (specify steps w/ STEP=n)
    HEREDOC
  end

  Rake::Task["db:setup"].clear if Rake::Task.task_defined?("db:setup")
  desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
  task :setup do
    puts <<~HEREDOC

      db:setup is prohibited.

      Prefer using the appropriate database-specific task below:

        db:setup:primary  # Setup the primary database
        db:setup:etl      # Setup the etl database
    HEREDOC
  end
end
# rubocop:enable Rails/RakeEnvironment, Layout/HeredocIndentation, Style/SignalException, Rails/Blank
