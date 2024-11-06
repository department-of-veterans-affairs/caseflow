# frozen_string_literal: true

module ParallelTests
  module Tasks
    class << self
      # Prevents attempting to establish and consult a schema_migrations table in our VACOLS database
      #  upon initializing the test suite.
      def abort_if_pending_migrations
        pending_migrations = ActiveRecord::Base.configurations.configs_for(
          env_name: ActiveRecord::Tasks::DatabaseTasks.env
        ).flat_map do |db_config|
          next if db_config.configuration_hash[:username].match?(/VACOLS/)

          ActiveRecord::Base.establish_connection(db_config)

          ActiveRecord::Base.connection.migration_context.open.pending_migrations
        end

        if pending_migrations.any?
          Rails.logger.info(
            "You have #{pending_migrations.size} pending #{pending_migrations.size > 1 ? 'migrations:' : 'migration:'}"
          )
          pending_migrations.each do |pending_migration|
            Rails.logger.info("   #{pending_migration.version} #{pending_migration.name}")
          end
          abort %{Run `bin/rails db:migrate` to update your database then try again.}
        end
      ensure
        ActiveRecord::Base.establish_connection(ActiveRecord::Tasks::DatabaseTasks.env.to_sym)
      end

      def check_for_pending_migrations
        ["db:abort_if_pending_migrations", "app:db:abort_if_pending_migrations"].each do |abort_migrations|
          if Rake::Task.task_defined?(abort_migrations)
            abort_if_pending_migrations
            break
          end
        end
      end
    end
  end
end
