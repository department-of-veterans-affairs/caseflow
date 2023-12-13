# frozen_string_literal: true

module CollectMetricsServiceMetrics
  extend ActiveSupport::Concern

  included do
    before_action :collect_data_dog_metrics
  end

  def collect_data_dog_metrics
    collect_postgres_metrics
    collect_vacols_metrics
  end

  def collect_postgres_metrics
    conns = ActiveRecord::Base.connection_pool.connections

    active = conns.count { |c| c.in_use? && c.owner.alive? }
    dead = conns.count { |c| c.in_use? && !c.owner.alive? }
    idle = conns.count { |c| !c.in_use? }

    emit_metrics_service_point("postgres", "active", active)
    emit_metrics_service_point("postgres", "dead", dead)
    emit_metrics_service_point("postgres", "idle", idle)
  end

  def collect_vacols_metrics
    conns = VACOLS::Record.connection_pool.connections

    active = conns.count { |c| c.in_use? && c.owner.alive? }
    dead = conns.count { |c| c.in_use? && !c.owner.alive? }
    idle = conns.count { |c| !c.in_use? }

    emit_metrics_service_point("vacols", "active", active)
    emit_metrics_service_point("vacols", "dead", dead)
    emit_metrics_service_point("vacols", "idle", idle)
  end

  def emit_metrics_service_point(db_name, type, count)
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
