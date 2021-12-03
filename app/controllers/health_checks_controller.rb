# frozen_string_literal: true

class HealthChecksController < ActionController::Base
  include TrackRequestId
  include CollectDataDogMetrics

  protect_from_forgery with: :exception
  newrelic_ignore_apdex

  def show
    migrations = migration_status
    body = {
      healthy: true
    }.merge(Rails.application.config.build_version || {}).merge(migrations)
    render(json: body, status: :ok)
  end

  private

  def migration_status
    migrations = []
    ActiveRecord::Base.connection.migration_context.migrations_status.map do |status, version, name|
      migrations << { status: status, version: version, name: name } unless status == "up"
    end
    { pending_migrations: migrations.any?, migrations: migrations }
  end
end
