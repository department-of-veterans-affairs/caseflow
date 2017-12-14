# This class calls MetricsService to record API metrics while also releasing DB connections.
# Our external dependencies are slow and unreliable. If an external dependency takes a long
# time to respond we end up holding on to DB connections for an unreasonable amount of time.
# By default we'll release all DB connections before making the API call.
class ExternalApi::ApiService
  def self.request(description, service: nil, name: "unknown")
    if FeatureToggle.enabled?(:release_db_connections)
      if VACOLS::Record.connection_pool.active_connection?
        VACOLS::Record.connection_pool.release_connection if VACOLS::Record.connection.open_transactions == 0
      end
      if ActiveRecord::Base.connection_pool.active_connection?
        ActiveRecord::Base.connection_pool.release_connection if ActiveRecord::Base.connection.open_transactions == 0
      end
    end

    MetricsService.record(description, service: service, name: name) do
      yield
    end
  end
end
