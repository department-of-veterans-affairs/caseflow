# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
class HealthChecksController < ActionController::Base
  include CollectCustomMetrics

  protect_from_forgery with: :exception

  def show
    body = {
      healthy: true
    }.merge(Rails.application.config.build_version || {}).merge(migration_status)
    render(json: body, status: :ok)
  end

  private

  def migration_status
    migrations = ActiveRecord::Base.connection.migration_context.migrations_status.map do |status, version, name|
      { status: status, version: version, name: name } unless status == "up"
    end.compact
    { pending_migrations: migrations.any?, migrations: migrations }
  end
end
# rubocop:enable Rails/ApplicationController
