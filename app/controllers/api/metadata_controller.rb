# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
class Api::MetadataController < ActionController::Base
  protect_from_forgery with: :null_session

  VERSION_STATUS = {
    draft: "Draft Version",
    current: "Current Version",
    previous: "Previous Version",
    deprecated: "Deprecated Version"
  }.freeze

  def index
    render json: {
      meta: {
        versions: [
          {
            version: "3",
            internal_only: true,
            status: VERSION_STATUS[:draft],
            path: "/api/docs/v3/decision_reviews",
            healthcheck: "/health-check"
          }
        ]
      }
    }
  end
end
# rubocop:enable Rails/ApplicationController
