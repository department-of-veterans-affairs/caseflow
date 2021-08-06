# frozen_string_literal: true

class QuerySubscriber
  attr_reader :queries

  def initialize
    @queries = []
  end

  def track(&block)
    ActiveSupport::Notifications.subscribed(method(:call), "sql.active_record") do
      block.call
    end
    @queries
  end

  def call(name, started, finished, unique_id, payload)
    @queries << payload[:sql]
  end

  def select_queries
    @queries.select{|query| query =~ /SELECT/ }
  end
end
