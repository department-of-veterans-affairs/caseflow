# frozen_string_literal: true

# Once on Rails 7+, we can add the `database_tasks: false` option to the `database.yml` to permit connection to the
# vacols database without generating database tasks for it:
# https://github.com/rails/rails/blob/984c3ef2775781d47efa9f541ce570daa2434a80/guides/source/active_record_multiple_databases.md?plain=1#L203-L219
#
# After adopting and sufficiently testing the above setting setting, we can dispense with the workarounds in this file.
if Rails::VERSION::MAJOR >= 7
  ActiveSupport::Deprecation.warn(
    "Use the new `database_tasks` DB config option to skip generation of database tasks for the VACOLS DB.\n" \
    "For further details, see https://github.com/rails/rails/blob/984c3ef2775781d47efa9f541ce570daa2434a80/guides/source/active_record_multiple_databases.md?plain=1#L203-L219"
  )
end

# Explicitly clear any generated database tasks for the vacols DB.
%w[
  db:create:vacols
  db:drop:vacols
  db:migrate:vacols
  db:migrate:status:vacols
  db:migrate:up:vacols
  db:migrate:down:vacols
  db:migrate:redo:vacols
  db:rollback:vacols
  db:schema:dump:vacols
  db:schema:load:vacols
  db:structure:dump:vacols
  db:structure:load:vacols
].each do |task_name|
  Rake::Task[task_name].clear if Rake::Task.task_defined?(task_name)
end

#-----------------------------------------------------------------------------------------------------------------------

# The original definition of the `db:seed` task calls `db:abort_if_pending_migrations`, which would attempt to create a
# `schema_migrations` table on ALL configured databases, including the vacols DB:
# https://github.com/rails/rails/blob/ac87f58207cff18880593263be9d83456aa3a2ef/activerecord/lib/active_record/railties/databases.rake#L389-L393
#
# This would result in the following error, since the Caseflow app does not have permissions to alter the VACOLS schema:
#
#   ActiveRecord::StatementInvalid: OCIError: ORA-01031: insufficient privileges
#
# This re-definiton of `db:seed` will instead call the DB-specific `db:abort_if_pending_migrations` as a workaround.

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
# act on ALL databases, including the vacols DB, and not just the primary database.
#
# To avoid accidents, we re-define these tasks here to no-op and output a helpful message to redirect developers toward
# using their new database-specific counterparts instead.

# rubocop:disable Rails/RakeEnvironment, Layout/HeredocIndentation
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

      Prefer using the appropriate sequence of database-specific tasks below:

        db:drop:primary db:create:primary db:schema:load:primary db:seed  # Reset the primary database
        db:drop:etl db:create:etl db:schema:load:etl db:seed              # Reset the etl database
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

  namespace :schema do
    Rake::Task["db:schema:dump"].clear if Rake::Task.task_defined?("db:schema:dump")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :dump do
      puts <<~HEREDOC

        db:schema:dump is prohibited.
  
        Prefer using the appropriate database-specific task below:
  
          db:schema:dump:primary  # Creates a database schema file (either db/schema.rb or db/structure.sql, depending on `config.active_record.schema_format`) for primary database
          db:schema:dump:etl      # Creates a database schema file (either db/schema.rb or db/structure.sql, depending on `config.active_record.schema_format`) for etl database
      HEREDOC
    end

    Rake::Task["db:schema:load"].clear if Rake::Task.task_defined?("db:schema:load")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :load do
      puts <<~HEREDOC

        db:schema:load is prohibited.
  
        Prefer using the appropriate database-specific task below:
  
          db:schema:load:primary  # Loads a database schema file (either db/schema.rb or db/structure.sql, depending on `config.active_record.schema_format`) into the primary database
          db:schema:load:etl      # Loads a database schema file (either db/schema.rb or db/structure.sql, depending on `config.active_record.schema_format`) into the etl database
      HEREDOC
    end
  end

  Rake::Task["db:setup"].clear if Rake::Task.task_defined?("db:setup")
  desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
  task :setup do
    puts <<~HEREDOC

      db:setup is prohibited.

      Prefer using the appropriate sequence of database-specific tasks below:

        db:create:primary db:schema:load:primary db:seed  # Setup the primary database
        db:create:etl db:schema:load:etl db:seed          # Setup the etl database
    HEREDOC
  end

  namespace :test do
    Rake::Task["db:test:load"].clear if Rake::Task.task_defined?("db:test:load")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :load do
      puts <<~HEREDOC

        db:test:load is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:test:load:primary  # Recreate the primary test database from the current schema
          db:test:load:etl      # Recreate the etl test database from the current schema
      HEREDOC
    end

    Rake::Task["db:test:load_schema"].clear if Rake::Task.task_defined?("db:test:load_schema")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :load_schema do
      puts <<~HEREDOC

        db:test:load_schema is prohibited.
  
        Prefer using the appropriate database-specific task below:

          db:test:load_schema:primary  # Recreate the primary test database from an existent schema file (schema.rb or structure.sql, depending on `config.active_record.schema_format`)
          db:test:load_schema:etl      # Recreate the etl test database from an existent schema file (schema.rb or structure.sql, depending on `config.active_record.schema_format`)
      HEREDOC
    end

    Rake::Task["db:test:prepare"].clear if Rake::Task.task_defined?("db:test:prepare")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :prepare do
      puts <<~HEREDOC

        db:test:prepare is prohibited.
  
        Prefer using the appropriate database-specific task below:
        
          db:test:prepare:primary  # Load the schema for the primary test database
          db:test:prepare:etl      # Load the schema for the etl test database
      HEREDOC
    end

    Rake::Task["db:test:purge"].clear if Rake::Task.task_defined?("db:test:purge")
    desc "[PROHIBITED] Use the appropriate database-specific tasks instead"
    task :purge do
      puts <<~HEREDOC

        db:test:purge is prohibited.
  
        Prefer using the appropriate database-specific task below:
        
          db:test:purge:primary  # Empty the primary test database
          db:test:purge:etl      # Empty the etl test database
      HEREDOC
    end
  end
end
# rubocop:enable Rails/RakeEnvironment, Layout/HeredocIndentation
