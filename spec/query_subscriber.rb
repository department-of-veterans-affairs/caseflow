# frozen_string_literal: true

class QuerySubscriber
  attr_reader :queries

  def initialize
    @queries = []
  end

  def track
    ActiveSupport::Notifications.subscribed(method(:call), "sql.active_record") do
      yield
    end
    @queries
  end

  def call(_name, _started, _finished, _unique_id, payload)
    @queries << payload[:sql]
  end

  def select_queries(sql_pattern = /SELECT/)
    @queries.select { |query| query =~ sql_pattern }
  end
end
