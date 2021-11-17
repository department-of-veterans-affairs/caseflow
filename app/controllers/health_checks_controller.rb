# frozen_string_literal: true

class HealthChecksController < ActionController::Base
  include TrackRequestId
  include CollectDataDogMetrics

  protect_from_forgery with: :exception
  newrelic_ignore_apdex

  def show
    migrations = check_migrations
    body = {
      healthy: true
    }.merge(Rails.application.config.build_version || {}).merge(migrations)
    render(json: body, status: :ok)
  end

  private
  def check_migrations
    migrations = []
    pending_migrations = false
    ActiveRecord::Base.connection.migration_context.migrations_status.each do |status, version, name|
        migrations << { status: status, version: version, name: name }
        pending_migrations = true if status != "up"
    end
    { migrations: migrations, pending_migrations: pending_migrations }
  end
end
