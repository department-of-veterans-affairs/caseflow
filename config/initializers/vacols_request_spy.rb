if DatabaseRequestCounter.valid_env?
  def vacols_request_spy
    DatabaseRequestCounter.increment_counter(:vacols)
  end

  class ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter
    # TODO: Add sleep(1000) if ENV["SOME_VAR"] to imitate production slowness
    # What is a good delay to simulate the latency here?
    def execute(*args)
      byebug
      vacols_request_spy
      super
    end

    def exec_query(*args)
      byebug
      vacols_request_spy
      super
    end
  end
end