# frozen_string_literal: true

# @note Usage: Include this module only in migrations where you need to add an index concurrently.
#   Invoke `#add_safe_index` in place of `#add index`.
#
# @note Since this module necessarily disables transactions, you should avoid mixing in other DB changes when
#   adding indexes concurrently. Prefer isolating index additions in their own migration.
#
# @see [PostgreSQL: Building Indexes Concurrently](https://www.postgresql.org/docs/14/sql-createindex.html#SQL-CREATEINDEX-CONCURRENTLY)
# @see [thoughtbot: How to Create Postgres Indexes Concurrently in ActiveRecord Migrations](https://thoughtbot.com/blog/how-to-create-postgres-indexes-concurrently-in)
#
# @example
#   class YourMigrationName < ActiveRecord::Migration[6.0]
#     include Caseflow::Migrations::AddIndexConcurrently
#
#     change
#       add_safe_index :some_table, :some_column
#     end
#   end
#
# @example
#   # Alternatively, you can add in the requisite incantations yourself, without this module
#
#   class YourMigrationName < ActiveRecord::Migration[6.0]
#     disable_ddl_transaction!
#
#     change
#       add_index :some_table, :some_column, algorithm: :concurrently
#     rescue StandardError => error
#       remove_index :some_table, :some_column
#     end
#   end
module Caseflow
  module Migrations
    module AddIndexConcurrently
      extend ActiveSupport::Concern

      EXTENDED_STATEMENT_TIMEOUT_DURATION = 30.minutes

      included do
        # Disables the automatic transaction wrapping this migration.
        # https://github.com/rails/rails/blob/28bb76d3efc39b2ef663dfe2346f7c2621343cd6/activerecord/lib/active_record/migration.rb#L508-L524
        disable_ddl_transaction!

        # @note Use this method in place of `#add_index` to add an index concurrently (i.e. without blocking DB writes).
        # - Accommodates long-running index builds by extending the statement_timeout duration
        # - Performs a rollback should an error occur during the migration, since transactions are disabled
        #
        # @note Inspired by {Caseflow::Migration} https://github.com/department-of-veterans-affairs/caseflow/blob/6fc9d26a5ae9417b69d7d1f30cc70bea57a0700d/lib/caseflow/migration.rb#L12-L29
        def add_safe_index(*args)
          original_statement_timeout_duration = current_statement_timeout_duration
          extend_statement_timeout
          add_index_concurrently(args)
        rescue StandardError => error
          rollback_index(error, args)
          raise error # re-raise to abort migration
        ensure
          restore_original_statement_timeout(original_statement_timeout_duration)
        end

        private

        def current_statement_timeout_duration
          ActiveSupport::Duration.build(
            ActiveRecord::Base.connection.execute("SHOW statement_timeout").first["statement_timeout"].to_i
          )
        end

        def extend_statement_timeout
          say "Extending statement_timeout to #{EXTENDED_STATEMENT_TIMEOUT_DURATION.inspect}"
          ActiveRecord::Base.connection.execute(
            ActiveRecord::Base.sanitize_sql(["SET statement_timeout = ?",
                                             EXTENDED_STATEMENT_TIMEOUT_DURATION.in_milliseconds])
          )
        end

        def add_index_concurrently(args)
          table, columns, options = *args
          options ||= {}
          options[:algorithm] ||= :concurrently
          add_index(table, columns, options)
        end

        def rollback_index(error, args)
          say "Caught #{error}, rolling back index"
          table, columns, options = *args
          options[:column] = columns unless options[:name]
          remove_index(table, options)
        end

        # :reek:FeatureEnvy
        def restore_original_statement_timeout(duration)
          say "Restoring statement_timeout to #{duration.inspect}"
          ActiveRecord::Base.connection.execute(
            ActiveRecord::Base.sanitize_sql(["SET statement_timeout = ?", duration.in_milliseconds])
          )
        end
      end
    end
  end
end
