# frozen_string_literal: true

if DatabaseRequestCounter.valid_env?
  def vacols_request_spy
    simulate_vacols_latency
    DatabaseRequestCounter.increment_counter(:vacols)
  end

  def simulate_vacols_latency
    # Simulate VACOLS latency by running something the Rails server by using something like the following:
    # $> REACT_ON_RAILS_ENV=HOT SIMULATE_VACOLS_LATENCY=true bundle exec rails s -p 3000
    return unless ENV["SIMULATE_VACOLS_LATENCY"]

    # Default determined from metrics sent to Datadog:
    # https://app.datadoghq.com/dashboard/54w-efy-r5d/va-systems?fullscreen_widget=399796003
    latency = ENV["VACOLS_DELAY_MS"] || 80
    sleep(latency / 1000.0)
  end

  class ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter
    def execute(*args)
      vacols_request_spy
      super
    end

    def exec_query(*args)
      vacols_request_spy
      super
    end
  end
end
