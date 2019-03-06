# frozen_string_literal: true

# Simple middleware that collects gauge metrics whenever
# a GET /metrics request is made. This ensures we regularly
# get a snapshot of instance information
class MetricsCollector
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    perform if request.path == "/metrics"

    @app.call(env)
  end

  private

  def perform
    collect_postgres_metrics
    collect_vacols_metrics
  end

  def collect_postgres_metrics
    conns = ActiveRecord::Base.connection_pool.connections

    active = conns.count { |c| c.in_use? && c.owner.alive? }
    dead = conns.count { |c| c.in_use? && !c.owner.alive? }
    idle = conns.count { |c| !c.in_use? }

    PrometheusService.postgres_db_connections.set({ type: "active" }, active)
    PrometheusService.postgres_db_connections.set({ type: "dead" }, dead)
    PrometheusService.postgres_db_connections.set({ type: "idle" }, idle)

    emit_datadog_point("postgres", "active", active)
    emit_datadog_point("postgres", "dead", dead)
    emit_datadog_point("postgres", "idle", idle)
  end

  def collect_vacols_metrics
    conns = VACOLS::Record.connection_pool.connections
    active = conns.count { |c| c.in_use? && c.owner.alive? }
    dead = conns.count { |c| c.in_use? && !c.owner.alive? }
    idle = conns.count { |c| !c.in_use? }

    PrometheusService.vacols_db_connections.set({ type: "active" }, active)
    PrometheusService.vacols_db_connections.set({ type: "dead" }, dead)
    PrometheusService.vacols_db_connections.set({ type: "idle" }, idle)

    emit_datadog_point("vacols", "active", active)
    emit_datadog_point("vacols", "dead", dead)
    emit_datadog_point("vacols", "idle", idle)
  end

  def emit_datadog_point(db_name, type, count)
    DataDogService.emit_gauge(
      metric_group: "database",
      metric_name: "#{type}_connections",
      metric_value: count,
      app_name: "caseflow",
      attrs: {
        database: db_name
      }
    )
  end
end
