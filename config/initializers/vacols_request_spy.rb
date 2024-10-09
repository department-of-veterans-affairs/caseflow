# frozen_string_literal: true

if DatabaseRequestCounter.valid_env?

  EXCLUDED_PATTERNS = [
    # Ignore the following request to describe the database since they will only happen once in the lifetime of the
    # Rails app and may happen at different times based on the order the tests run.
    #
    # Table columns:
    # https://github.com/rsim/oracle-enhanced/blob/1272b3c58d082930514e625182a14a729e1e693e/lib/active_record/...
    # connection_adapters/oracle_enhanced_adapter.rb#L559
    "FROM all_tab_cols cols",
    # Table sequences:
    # https://github.com/rsim/oracle-enhanced/blob/1272b3c58d082930514e625182a14a729e1e693e/lib/active_record/...
    # connection_adapters/oracle_enhanced_adapter.rb#L591
    "from all_sequences",
    # Table primary keys:
    # https://github.com/rsim/oracle-enhanced/blob/1272b3c58d082930514e625182a14a729e1e693e/lib/active_record/...
    # connection_adapters/oracle_enhanced_adapter.rb#L591
    "FROM all_constraints"
  ].freeze

  def vacols_request_spy(statement)
    unless statement.match?(Regexp.union(EXCLUDED_PATTERNS))
      simulate_vacols_latency
      DatabaseRequestCounter.increment_counter(:vacols)
    end
  end

  def simulate_vacols_latency
    # Simulate VACOLS latency by running something the Rails server by using something like the following:
    # $> REACT_ON_RAILS_ENV=HOT SIMULATE_VACOLS_LATENCY=true bundle exec rails s -p 3000
    return unless ENV["SIMULATE_VACOLS_LATENCY"]

    latency = ENV["VACOLS_DELAY_MS"] || 80
    sleep(latency / 1000.0)
  end

  class ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter
    def execute(*args)
      vacols_request_spy(args.first)
      super
    end

    def exec_query(*args)
      vacols_request_spy(args.first)
      super
    end
  end
end
