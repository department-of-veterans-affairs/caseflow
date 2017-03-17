# Simple middleware that collects gauge metrics whenever
# a GET /metrics request is made. This ensures we regularly
# get a snapshot of instance information
class MetricsCollector
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    perform if request.path == '/metrics'

    @app.call(env)
  end

  private

  def perform
    collect_postgres_metrics
    collect_vacols_metrics
  end

  def collect_postgres_metrics
    conns = ActiveRecord::Base.connection_pool.connections

    active = conns.count { |c| c.in_use?  && c.owner.alive? }
    dead = conns.count { |c| c.in_use?  && !c.owner.alive? }
    idle = conns.count { |c| !c.in_use? }

    PrometheusService.postgres_db_connections.set({ type: 'active' }, active)
    PrometheusService.postgres_db_connections.set({ type: 'dead' }, dead)
    PrometheusService.postgres_db_connections.set({ type: 'idle' }, idle)
  end

  def collect_vacols_metrics
    conns = VACOLS::Record.connection_pool.connections
    active = conns.count { |c| c.in_use?  && c.owner.alive? }
    dead = conns.count { |c| c.in_use?  && !c.owner.alive? }
    idle = conns.count { |c| !c.in_use? }

    PrometheusService.vacols_db_connections.set({ type: 'active' }, active)
    PrometheusService.vacols_db_connections.set({ type: 'dead' }, dead)
    PrometheusService.vacols_db_connections.set({ type: 'idle' }, idle)
  end
end

