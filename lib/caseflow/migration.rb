# frozen_string_literal: true

# @deprecated Use {Caseflow::Migrations::AddIndexConcurrently} instead, because descendants of this class are forever
#   coupled to Active Record 5.1.
#   This class should be preserved until all descendant migrations <= 20240227154315 are pruned.
#
# @note Migration with built-in timeout extensions for adding indexes
class Caseflow::Migration < ActiveRecord::Migration[5.1]
  def initialize(*)
    super
    # Trigger deprecation warning to prevent re-introduction in migrations after version 20240227154315
    if version > 20_240_227_154_315
      ActiveSupport::Deprecation.warn(
        "Caseflow::Migration is deprecated and should no longer be used.\n" \
        "If adding an index, see Caseflow::Migrations::AddIndexConcurrently."
      )
    end
  end

  # hardcode this because setting via class method does not work in subclass
  def disable_ddl_transaction
    say "disable_ddl_transaction is true"
    true
  end

  def add_safe_index(*args)
    say "Extending statement_timeout to 30 minutes"
    ActiveRecord::Base.connection.execute "SET statement_timeout = 1800000" # 30 minutes

    table, columns, options = *args
    options ||= {}
    options[:algorithm] ||= :concurrently

    add_index(table, columns, options)
  rescue StandardError => error
    say "Caught #{error}, rolling back index"
    options[:column] = columns unless options[:name]
    remove_index(table, options)
    raise error # re-raise to abort migration
  ensure
    say "Restoring statement_timeout to 30 seconds"
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
