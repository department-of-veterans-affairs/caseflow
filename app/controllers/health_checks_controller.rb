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
    pending_migrations = false
    ActiveRecord::Base.connection.migration_context.migrations_status.each do |status, version, name|
      if status != "up"
        migrations << { status: status, version: version, name: name }
        pending_migrations = true
      end
    end
    { pending_migrations: pending_migrations, migrations: migrations }
  end
end
