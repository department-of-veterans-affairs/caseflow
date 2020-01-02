# frozen_string_literal: true

# Migration with built-in timeout extensions for adding indexes

class Caseflow::Migration < ActiveRecord::Migration[5.1]
  # hardcode this because setting via class method does not work in subclass
  def disable_ddl_transaction
    say "disable_ddl_transaction is true"
    true
  end

  def add_index_with_timeout(*args)
    say "Extending statement_timeout to 30 minutes"
    ActiveRecord::Base.connection.execute "SET statement_timeout = 1800000" # 30 minutes

    table, columns, options = *args
    options ||= {}
    options[:algorithm] ||= :concurrently

    add_index(table, columns, options)

  rescue => error
    say "Caught #{error}, rolling back index"
    options[:column] = columns unless options[:name]
    remove_index(table, options)
  ensure
    say "Restoring statement_timeout to 30 seconds"
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
