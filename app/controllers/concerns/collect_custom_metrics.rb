# frozen_string_literal: true

module CollectCustomMetrics
  extend ActiveSupport::Concern

  included do
    before_action :collect_custom_metrics
  end

  def collect_custom_metrics
    collect_postgres_metrics
    collect_vacols_metrics
  end

  # :reek:FeatureEnvy
  def collect_postgres_metrics
    conns = ActiveRecord::Base.connection_pool.connections

    active = conns.count { |conn| conn.in_use? && conn.owner.alive? }
    dead = conns.count { |conn| conn.in_use? && !conn.owner.alive? }
    idle = conns.count { |conn| !conn.in_use? }

    emit_metrics_point("postgres", "active", active)
    emit_metrics_point("postgres", "dead", dead)
    emit_metrics_point("postgres", "idle", idle)
  end

  # :reek:FeatureEnvy
  def collect_vacols_metrics
    conns = VACOLS::Record.connection_pool.connections

    active = conns.count { |conn| conn.in_use? && conn.owner.alive? }
    dead = conns.count { |conn| conn.in_use? && !conn.owner.alive? }
    idle = conns.count { |conn| !conn.in_use? }

    emit_metrics_point("vacols", "active", active)
    emit_metrics_point("vacols", "dead", dead)
    emit_metrics_point("vacols", "idle", idle)
  end

  # :reek:UtilityFunction
  def emit_metrics_point(db_name, type, count)
    MetricsService.emit_gauge(
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
